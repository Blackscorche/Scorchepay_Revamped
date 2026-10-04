import { Router } from 'express';
import { pool } from '../db/pool';
import { sendOtpSms } from '../services/termii';
import { requireAuth } from '../middleware/requireAuth';
import { allowAttempt } from '../middleware/authSafety';
import { username as normalizeUsername } from '../domain/money';
import { hashPin, verifyPin, signAccessToken, issueRefreshToken, consumeRefreshToken, revokeRefreshToken, generateOtpCode, storeOtp, verifyOtp } from '../services/auth';
export const authRouter = Router();

async function sendVerification(phone: string) {
  const code = generateOtpCode();
  // Invalidate earlier codes before issuing a replacement.
  await pool.query(`UPDATE otp_codes SET consumed_at=now() WHERE phone=$1 AND purpose='signup' AND consumed_at IS NULL`,[phone]);
  await storeOtp(phone,code,'signup');
  await sendOtpSms(phone,code);
}
authRouter.post('/signup', async(req,res,next) => {
  try {
    const {displayName,email,phone,pin} = req.body;
    let username: string;
    try {
      username = normalizeUsername(req.body.username);
      if (typeof displayName !== 'string' || !displayName.trim() || displayName.length>80) throw new Error('Enter your name');
      if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length>254) throw new Error('Enter a valid email');
      if (typeof phone !== 'string' || !/^\+[1-9]\d{7,14}$/.test(phone)) throw new Error('Use an international phone number, such as +234…');
      if (typeof pin !== 'string' || !/^\d{4}$/.test(pin)) throw new Error('Use a four-digit PIN');
    } catch(error) { return res.status(400).json({error:(error as Error).message}); }
    if (!(await allowAttempt('signup',req.ip ?? 'unknown',5))) return res.status(429).json({error:'Please wait before creating another account'});
    const existing = await pool.query(`SELECT 1 FROM users WHERE lower(regexp_replace(username,'^@',''))=$1 OR lower(email)=$2 OR phone=$3`,[username,email.trim().toLowerCase(),phone]);
    if (existing.rowCount) return res.status(409).json({error:'Account details are already registered. Log in to continue.'});
    const pinHash = await hashPin(pin);
    const {rows} = await pool.query(`INSERT INTO users(username,display_name,email,phone,pin_hash) VALUES($1,$2,$3,$4,$5) RETURNING id,username,display_name,phone,phone_verified`,[username,displayName.trim(),email.trim().toLowerCase(),phone,pinHash]);
    const user = rows[0];
    // An SMS outage does not conceal a successfully created account.
    let otpSent = true;
    try { await sendVerification(phone); } catch { otpSent = false; }
    res.status(201).json({user,otpSent,accessToken:signAccessToken(user.id),refreshToken:await issueRefreshToken(user.id)});
  } catch(error) {
    if ((error as {code?:string}).code === '23505') return res.status(409).json({error:'Account details are already registered. Log in to continue.'});
    next(error);
  }
});
authRouter.post('/login', async(req,res,next) => {
  try {
    let username: string;
    try { username = normalizeUsername(req.body.username); } catch { return res.status(401).json({error:'Invalid username or PIN'}); }
    const pin = req.body.pin;
    if (typeof pin !== 'string' || !/^\d{4}$/.test(pin)) return res.status(401).json({error:'Invalid username or PIN'});
    const ipAllowed = await allowAttempt('login-ip',req.ip ?? 'unknown',40);
    const userAllowed = await allowAttempt('login-user',username);
    if (!ipAllowed || !userAllowed) return res.status(429).json({error:'Too many attempts. Try again in 15 minutes.'});
    const {rows} = await pool.query(`SELECT id,pin_hash FROM users WHERE lower(regexp_replace(username,'^@',''))=$1`,[username]);
    if (rows.length !== 1 || !rows[0].pin_hash || !(await verifyPin(pin,rows[0].pin_hash))) return res.status(401).json({error:'Invalid username or PIN'});
    res.json({accessToken:signAccessToken(rows[0].id),refreshToken:await issueRefreshToken(rows[0].id)});
  } catch(error) { next(error); }
});
authRouter.get('/me',requireAuth,async(req,res,next) => {
  try {
    const {rows} = await pool.query('SELECT id,username,display_name,phone,phone_verified FROM users WHERE id=$1',[req.userId]);
    if (!rows.length) return res.status(401).json({error:'Session expired'});
    res.json(rows[0]);
  } catch(error) { next(error); }
});
authRouter.post('/verify-otp',requireAuth,async(req,res,next) => {
  try {
    const {rows} = await pool.query('SELECT phone FROM users WHERE id=$1',[req.userId]);
    if (!rows.length) return res.status(401).json({error:'Session expired'});
    if (!(await allowAttempt('otp-check',req.userId!,6))) return res.status(429).json({error:'Too many attempts. Try again in 15 minutes.'});
    const code = req.body.code;
    if (typeof code !== 'string' || !/^\d{6}$/.test(code) || !(await verifyOtp(rows[0].phone,code,'signup'))) return res.status(400).json({error:'Invalid or expired code'});
    await pool.query('UPDATE users SET phone_verified=true WHERE id=$1',[req.userId]);
    res.json({verified:true});
  } catch(error) { next(error); }
});
authRouter.post('/resend-otp',requireAuth,async(req,res,next) => {
  try {
    if (!(await allowAttempt('otp-send',req.userId!,1,60))) return res.status(429).json({error:'Wait a minute before requesting another code'});
    const {rows} = await pool.query('SELECT phone,phone_verified FROM users WHERE id=$1',[req.userId]);
    if (!rows.length) return res.status(401).json({error:'Session expired'});
    if (!rows[0].phone_verified) await sendVerification(rows[0].phone);
    res.json({sent:true});
  } catch(error) { next(error); }
});
authRouter.post('/refresh',async(req,res,next) => {
  try {
    if (typeof req.body.refreshToken !== 'string') return res.status(400).json({error:'Refresh token required'});
    const userId = await consumeRefreshToken(req.body.refreshToken);
    if (!userId) return res.status(401).json({error:'Session expired'});
    res.json({accessToken:signAccessToken(userId),refreshToken:await issueRefreshToken(userId)});
  } catch(error) { next(error); }
});
authRouter.post('/logout',async(req,res,next) => {
  try { if (typeof req.body.refreshToken === 'string') await revokeRefreshToken(req.body.refreshToken); res.sendStatus(204); }
  catch(error) { next(error); }
});
