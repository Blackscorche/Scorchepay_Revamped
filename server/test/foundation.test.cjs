const {test,after,before}=require('node:test');
const assert=require('node:assert/strict');
const {randomUUID}=require('node:crypto');
const {parseNgn}=require('../dist/domain/money');

test('money preserves exact smallest units and rejects unsafe inputs',()=>{
  assert.deepEqual(parseNgn('999999999999.99'),{minor:99999999999999n,decimal:'999999999999.99'});
  assert.equal(parseNgn('0.01').minor,1n);
  for(const input of [0.01,'1e3','0','-1','0.001','NaN','Infinity','01.00',{},'1000000000000']) assert.throws(()=>parseNgn(input));
});

// Integration tests never use .env or an existing application database.
const dbUrl=process.env.TEST_DATABASE_URL;
if(dbUrl) {
  const uri=new URL(dbUrl);
  if(!['127.0.0.1','localhost'].includes(uri.hostname)||!uri.pathname.endsWith('/scorchepay_foundation_test')) throw new Error('Use a disposable local scorchepay_foundation_test database');
  process.env.DATABASE_URL=dbUrl;
  const {pool}=require('../dist/db/pool');
  const {executeTransfer,OperationConflict}=require('../dist/services/operations');
  const {consumeRefreshToken,verifyOtp}=require('../dist/services/auth');
  const fs=require('node:fs'); const path=require('node:path');
  let sender,receiver;
  before(async()=>{
    await pool.query(fs.readFileSync(path.join(__dirname,'../src/db/schema.sql'),'utf8'));
    await pool.query(fs.readFileSync(path.join(__dirname,'../src/db/migrations/001_foundation.sql'),'utf8'));
    const suffix=randomUUID().slice(0,8);
    sender=(await pool.query('INSERT INTO users(username,display_name,phone_verified) VALUES($1,$2,true) RETURNING id,username',['sender_'+suffix,'Sender'])).rows[0];
    receiver=(await pool.query('INSERT INTO users(username,display_name,phone_verified) VALUES($1,$2,true) RETURNING id,username',['receiver_'+suffix,'Receiver'])).rows[0];
    await pool.query(`INSERT INTO balances(user_id,currency,amount) VALUES($1,'NGN',100),($2,'NGN',100)`,[sender.id,receiver.id]);
  });
  after(()=>pool.end());
  const request=(overrides={})=>({userId:sender.id,id:randomUUID(),toUsername:receiver.username,currency:'NGN',amount:'1.00',...overrides});
  test('concurrent duplicate requests move money once and preserve journal sum',async()=>{
    const input=request();
    const results=await Promise.all(Array.from({length:12},()=>executeTransfer(input)));
    assert.ok(results.every(r=>r.status==='completed'&&r.id===input.id));
    const {rows}=await pool.query(`SELECT sum(amount_minor)::text AS sum,count(*)::int AS count FROM journal_postings WHERE operation_user_id=$1 AND operation_id=$2`,[sender.id,input.id]);
    assert.equal(rows[0].sum,'0'); assert.equal(rows[0].count,2);
    assert.equal((await pool.query('SELECT status FROM money_holds WHERE user_id=$1 AND operation_id=$2',[sender.id,input.id])).rows[0].status,'captured');
    assert.equal((await pool.query('SELECT count(*)::int AS count FROM ledger_entries WHERE meta->>\'operationId\'=$1',[input.id])).rows[0].count,2);
    await assert.rejects(()=>executeTransfer({...input,amount:'2.00'}),OperationConflict);
  });
  test('reciprocal concurrent sends do not deadlock or create value',async()=>{
    await Promise.all(Array.from({length:10},(_,i)=>executeTransfer(i%2 ? request() : request({userId:receiver.id,toUsername:sender.username}))));
    const total=(await pool.query(`SELECT sum(amount)::text AS total FROM balances WHERE user_id=ANY($1::uuid[]) AND currency='NGN'`,[[sender.id,receiver.id]])).rows[0].total;
    assert.equal(Number(total),200);
  });
  test('concurrent overspending allows exactly one debit',async()=>{
    const available=(await pool.query(`SELECT amount::text FROM balances WHERE user_id=$1 AND currency='NGN'`,[sender.id])).rows[0].amount;
    const amount=available.split('.')[0]+'.00';
    const results=await Promise.all([executeTransfer(request({amount})),executeTransfer(request({amount}))]);
    assert.equal(results.filter(r=>r.status==='completed').length,1);
    assert.equal(results.filter(r=>r.status==='failed').length,1);
  });
  test('lost response replays the persisted outcome without changing balances',async()=>{
    const input=request({userId:receiver.id,toUsername:sender.username,amount:'0.01'});
    await executeTransfer(input); // Deliberately discard response, as on a timeout.
    const before=(await pool.query(`SELECT amount FROM balances WHERE user_id=$1 AND currency='NGN'`,[sender.id])).rows[0].amount;
    assert.equal((await executeTransfer(input)).status,'completed');
    const after=(await pool.query(`SELECT amount FROM balances WHERE user_id=$1 AND currency='NGN'`,[sender.id])).rows[0].amount;
    assert.equal(after,before);
  });
  test('database fault rolls back balances, journal, hold and operation',async()=>{
    const input=request({userId:receiver.id,toUsername:sender.username});
    await pool.query(`CREATE OR REPLACE FUNCTION reject_test_posting() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'injected failure'; END $$`);
    await pool.query(`CREATE TRIGGER reject_test_posting BEFORE INSERT ON journal_postings FOR EACH ROW EXECUTE FUNCTION reject_test_posting()`);
    const before=(await pool.query(`SELECT amount FROM balances WHERE user_id=$1 AND currency='NGN'`,[receiver.id])).rows[0].amount;
    try { await assert.rejects(()=>executeTransfer(input)); }
    finally { await pool.query('DROP TRIGGER reject_test_posting ON journal_postings'); await pool.query('DROP FUNCTION reject_test_posting()'); }
    assert.equal((await pool.query(`SELECT amount FROM balances WHERE user_id=$1 AND currency='NGN'`,[receiver.id])).rows[0].amount,before);
    assert.equal((await pool.query('SELECT 1 FROM money_operations WHERE user_id=$1 AND id=$2',[receiver.id,input.id])).rowCount,0);
    assert.equal((await pool.query('SELECT 1 FROM money_holds WHERE user_id=$1 AND operation_id=$2',[receiver.id,input.id])).rowCount,0);
  });
  test('database rejects a completed operation without a balanced journal',async()=>{
    await assert.rejects(()=>pool.query(`INSERT INTO money_operations(id,user_id,fingerprint,status,result) VALUES($1,$2,'test','completed','{}')`,[randomUUID(),sender.id]));
  });
  test('authenticated API enforces PIN, verification and operation ownership',async()=>{
    process.env.JWT_SECRET='disposable-test-secret-'+randomUUID();
    const express=require('express');
    const {authRouter}=require('../dist/routes/auth');
    const {transfersRouter}=require('../dist/routes/transfers');
    const {walletRouter}=require('../dist/routes/wallet');
    const {requireAuth}=require('../dist/middleware/requireAuth');
    const {requireVerified}=require('../dist/middleware/authSafety');
    const {errorHandler}=require('../dist/middleware/errorHandler');
    const {hashPin,signAccessToken}=require('../dist/services/auth');
    await pool.query('UPDATE users SET pin_hash=$2 WHERE id=$1',[sender.id,await hashPin('4321')]);
    const app=express();app.use(express.json());
    app.use('/auth',authRouter);app.use('/transfers',requireAuth,requireVerified,transfersRouter);app.use('/wallet',requireAuth,requireVerified,walletRouter);app.use(errorHandler);
    const server=await new Promise(resolve=>{const listening=app.listen(0,'127.0.0.1',()=>resolve(listening));});
    const base=`http://127.0.0.1:${server.address().port}`;
    const headers={'Content-Type':'application/json',Authorization:`Bearer ${signAccessToken(sender.id)}`};
    try {
      assert.equal((await fetch(base+'/wallet/snapshot')).status,401);
      const wrong=await fetch(base+'/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:sender.username,pin:'1234'})});
      assert.equal(wrong.status,401);
      const login=await fetch(base+'/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:sender.username,pin:'4321'})});
      assert.equal(login.status,200);
      const send=await fetch(base+'/transfers/send',{method:'POST',headers:{...headers,'Idempotency-Key':randomUUID()},body:JSON.stringify({toUsername:receiver.username,currency:'NGN',amount:'0.01',pin:'1234'})});
      assert.equal(send.status,403);
      const input=request({userId:receiver.id,toUsername:sender.username,amount:'0.01'});await executeTransfer(input);
      const other=await fetch(base+'/transfers/operations/'+input.id,{headers});
      assert.equal((await other.json()).status,'unknown');
      const snapshot=await (await fetch(base+'/wallet/snapshot',{headers})).json();
      assert.equal(typeof snapshot.balances.NGN,'string');
      await pool.query('UPDATE users SET phone_verified=false WHERE id=$1',[sender.id]);
      assert.equal((await fetch(base+'/wallet/snapshot',{headers})).status,403);
    } finally { await pool.query('UPDATE users SET phone_verified=true WHERE id=$1',[sender.id]); await new Promise(resolve=>server.close(resolve)); }
  });
  test('refresh tokens and OTP codes can only be consumed once under concurrency',async()=>{
    const token=randomUUID(), phone=randomUUID();
    await pool.query(`INSERT INTO refresh_tokens(token,user_id,expires_at) VALUES($1,$2,now()+interval '1 hour')`,[token,sender.id]);
    const uses=await Promise.all(Array.from({length:6},()=>consumeRefreshToken(token)));
    assert.equal(uses.filter(Boolean).length,1);
    await pool.query(`INSERT INTO otp_codes(phone,code,purpose,expires_at) VALUES($1,'123456','signup',now()+interval '1 hour')`,[phone]);
    const codes=await Promise.all(Array.from({length:6},()=>verifyOtp(phone,'123456','signup')));
    assert.equal(codes.filter(Boolean).length,1);
  });
}
