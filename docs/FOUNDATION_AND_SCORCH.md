# ScorchePay foundation and Scorch

This increment starts phase 1 of the implementation plan. It does not enable provider-funded deposits, bills, crypto settlement, gift-card settlement, or the later delivery phases.

## Scorch motion system

Scorch keeps the original sculptural 3D orange ember artwork. `ScorchCharacter` animates it as a textured 2.5D puppet using Flutter vertices, rather than swapping generated frames. A continuous deformation field gives the greeting hand a shoulder-driven wave, lets the flame sway, adds breathing, lifts the wallet coin hand or protective shield, and moves the celebration arms and feet. This preserves the original shading; it is not a fully modeled 3D character and cannot turn to reveal unseen sides.

A shared 3.6-second timeline drives the puppet and scene effects. Mesh topology and texture coordinates are cached; an animation repaint listener updates vertex positions without decoding images every frame. Periodic curves match position and velocity at the loop seam. Tests check seam continuity and that triangles do not fold through a full cycle in every activity. Reduced motion and hidden tabs stop the shared timeline at the original pose.

- Onboarding: five stories matching wallets/transfers, Smart Pay/bills, crypto/P2P, savings/group goals and escrow. Each slide owns its activity and category so the copy and scene stay aligned.
- Welcome/splash/home: greeting pose and soft sparks.
- Authentication: shield pose.
- Wallet: wallet pose with circulating coins. Crypto: coin-hand puppet with distinct shaded BTC, ETH and USDT tokens in a continuous orbit; shared by onboarding and the crypto workspace.
- Shared detail headers: activity selected from the page title (payments, savings, escrow/security, wallet, exploration).
- Processing: wallet action with moving payment path; errors stop the character.
- Confirmed success: arms-raised celebration pose.
- Empty states: exploration scene.

All scenes ignore pointer input and are excluded from screen-reader semantics. They pause in hidden tabs and respect the OS reduced-motion setting. Artwork sits in the layout rather than floating over buttons or amounts. Add a `ScorchMascot(activity: ..., size: ...)` or `ScorchCompanion` to new pages.

Assets:

- `assets/scorch_mascot.png`
- `assets/scorch_wallet.png`
- `assets/scorch_protect.png`
- `assets/scorch_celebrate.png`
- `assets/scorch_wave_sheet.png`
- `assets/scorch_wallet_sheet.png`
- `assets/scorch_protect_sheet.png`
- `assets/scorch_celebrate_sheet.png`

The four original illustrations texture the live puppet. Sprite atlases and the vector rig remain unused design experiments. A debug-only `/scorch-preview` route demonstrates all four original poses with the production motion widget.

Generated with the built-in imagegen tool. Final base prompt:

> Use case: stylized-concept. Create an original ScorchePay fintech app mascot: a friendly small ember flame character, soft sculptural 3D orange/coral body, curved flame tuft, charcoal oval eyes and warm smile, tiny rounded arms and feet, sophisticated minimal premium mobile app style. Full body centered, welcoming pose with one hand raised. Genuinely transparent background, no ground plane, no words or logos, no other objects. Strong readable silhouette at 64px, generous padding. Asset will be animated with gentle floating and celebration motion throughout the app.

Each pose used the base image as an identity reference and this shared edit prompt:

> Use case: precise-object-edit. Create a matching ScorchePay mascot pose variant using this image as identity reference. Keep exactly the same orange/coral soft 3D ember character, flame tuft, dark eyes, proportions, lighting and premium sculptural style. [Pose below] Full body centered, genuinely transparent background, generous padding, no text, no background or ground plane. Standalone mobile app illustration.

Pose prompts:

- Wallet: Scorch is cradling a small elegant charcoal wallet with a glowing orange coin being placed into it, looking down at the wallet with a warm focused smile.
- Protect: Scorch is proudly holding a small smooth charcoal shield with an orange check symbol in front of its body, friendly calm confident smile. Hands visibly hold the shield.
- Celebrate: Scorch is celebrating a successful task with both arms raised and feet lifted in a small joyous jump, a happy open smile. No confetti baked into image.

## Demo and live builds

```sh
flutter run --dart-define=SCORCHEPAY_MODE=demo
flutter run --dart-define=SCORCHEPAY_MODE=live --dart-define=SCORCHEPAY_API_URL=https://your-staging-api.example
```

Demo is the default and displays a DEMO ribbon. Its login PIN is 1234; balances and providers are local simulations. Live mode has a separate server-backed workspace; it never constructs the demo state notifier. Release live builds require an HTTPS API URL; debug live builds permit HTTP for local testing. API configuration errors stop startup instead of selecting demo mode.

Live signup collects name, username, email, international phone number, and confirmed four-digit PIN. It creates the account, then verifies its phone via the server. Login checks the PIN server-side. Unverified accounts only see verification; wallet and transfer routes enforce verification independently. SMS delivery failure does not disguise a created account; users can log in and request another code. SMS codes are never logged as a fallback.

Live NGN transfers resolve the recipient's real name, accept decimal-string amounts, confirm the PIN on the server, and save an operation ID before submitting. The same ID is used to resume after a timeout. Pending details are namespaced to the authenticated user and contain no PIN. On restart/resume, the app queries the operation and reloads its wallet snapshot. An unknown result is not treated as failure or success.

## Database and transaction boundary

Run versioned migrations with `npm --prefix server run migrate` against staging before enabling this build. The runner applies the base schema and numbered migrations in one transaction under a migration lock. Nothing in this implementation automatically migrates a deployed database.

`001_foundation.sql` expands balance/ledger precision and adds operations, holds, journal postings, and persistent authentication attempt budgets. NGN uses exact integer minor units and decimal strings; settlement does not convert to JavaScript Number. Both wallets are locked in deterministic order. The operation result, captured hold, balanced journal, legacy receipt entries, and balance projection commit together. Reusing an ID with changed details is rejected. Failed business outcomes are durable and do not debit funds. Internal transfers settle within one database transaction; multi-step external provider reservations and reconciliation workers remain later work.

Expanding the schema cannot restore crypto precision already lost in historical records. Crypto and other provider rails stay disabled until custody, amounts and provider contracts are reconciled. The old provider adapters remain as scaffolding, but their public routes respond unavailable and their webhooks are not acknowledged as settled. Any previously deployed in-flight provider activity must be reconciled before rolling out these route gates.

## Verification

```sh
flutter analyze --no-pub
flutter test
npm --prefix server test
TEST_DATABASE_URL=postgresql://USER@127.0.0.1:PORT/scorchepay_foundation_test npm --prefix server test
```

The integration suite requires an explicitly named disposable local database. It never reads a production URL for tests or seeds a production wallet. It covers exact precision, duplicate and reciprocal concurrent sends, concurrent overspending, replay after a lost response, rollback on injected database failure, and single-use refresh/OTP consumption.

Production rollout still requires actual SMS delivery verification, provider contracts, operational reconciliation, staging deployment and recovery exercises. No provider purchase or live settlement was used for this increment.

## Archived animation atlas generation prompts

The built-in imagegen tool generated each atlas from its matching identity-reference still. Shared final prompt:

> Use case: stylized-concept. Asset type: production animation sprite sheet for the ScorchePay Flutter app. Use the supplied Scorch mascot as the exact character identity reference. Generate ONE square 2048x2048 transparent PNG containing EXACTLY a 4-column by 4-row grid of 16 sequential animation frames, equal 512x512 cells, row-major order. All cells have the same fixed camera, character scale, baseline and center, with safe 12% padding within every cell. GENUINE transparent alpha background across the full sheet, no checkerboard painted in, no labels, no grid lines, no text. The character in each cell must be fully separate, no overlap between cells. Consistent soft sculptural orange/coral 3D flame, charcoal eyes, tiny limbs and premium lighting from the reference. Animation: [action below] Frames show successive phases of the motion, smoothly looping from frame 16 back to frame 1. IMPORTANT every cell is a genuinely different articulated pose in the sequence, not repeated copies, not merely whole-body tilt. Preserve facial identity and proportions throughout. All 16 frames must be present.

Actions:

- Wave: Scorch performs a welcoming wave: right arm lifts, bends at elbow, hand waves left-right twice, then returns; face blinks once; flame tip flexes gently; body breathes with small squash/stretch. The feet stay planted.
- Wallet: Scorch places the glowing coin into its wallet: hand lifts the coin, moves it over the wallet opening, lowers coin into wallet, eyes follow the coin, blinks, then resets its hand/coin to the starting pose for a seamless magical loop. Clearly articulate the arms and hands, not only whole-body rotation.
- Protect: Scorch lifts its shield protectively, looks left then right, blinks, gives a confident nod, and lowers shield to initial position. Both hands actually change position, flame tip flexes, body breathes.
- Celebrate: Scorch performs a joyful celebratory hop: crouches, arms swing down, springs up, feet bend and separate, arms lift overhead, face smiles, then lands with squash and settles back to starting pose. Keep entire character within each cell.

Actual delivered atlases are 1254 × 1254 RGBA, each with 16 frames. Original alpha channels are preserved. Atlas playback was superseded by the continuous character rig because generated pose-to-pose variation was visibly choppy.
