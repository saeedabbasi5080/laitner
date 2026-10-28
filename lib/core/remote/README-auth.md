# Phone sign-in

Optional sign-in by phone number. The point is future backup: a card collection
on a lost device cannot be recovered without an account to attach it to. Nothing
is synced yet, and the app is fully usable without signing in.

The service lives in `D:\litner\AtilearnBackend` — a sibling of this project,
not inside it. The two are separate builds with separate toolchains: Maven on one
side, Flutter on the other, and neither needs to know the other exists beyond the
address below.

---

## What is where

```
lib/
  core/remote/remote_config.dart            the server address
  domain/entities/phone_numbers.dart        validation and normalisation
  domain/entities/auth_user.dart            who is signed in
  domain/entities/auth_error.dart           why a request failed
  domain/repositories/auth_token_store.dart where a session is kept
  data/datasources/auth_api_client.dart     the four endpoints
  data/datasources/secure_auth_token_store.dart  keystore, with a fallback
  presentation/blocs/auth/                  the state machine
  presentation/screens/sign_in_screen.dart  number, then code
  presentation/widgets/account_section.dart the settings row and its warning
```

Tested in `test/auth/` — 104 tests. The rules live in `PhoneNumbers`, the state
machine in `AuthCubit`, and both are tested without a network.

---

## Signing in is optional

This is the constraint everything else follows from.

- Nothing at start-up needs the server. `main` calls `restore()` without
  awaiting it, so a slow or absent server costs nothing at launch.
- No screen blocks on it. There is no gate, no splash that waits.
- A launch with no network still shows the user as signed in, from what is
  stored. The account tile says the session is unconfirmed rather than pretending
  otherwise.
- A failure never stops anything. Every one lands in `AuthState.failed` and is
  shown; none is re-thrown.
- Signing out is local. No request, so it works on a plane.

If the whole feature were deleted tomorrow, nothing else in the app would
notice.

---

## The warning

For someone not signed in, the settings screen shows:

> وارد نشده‌اید. اگر دستگاهتان را گم کنید یا اطلاعاتش پاک شود، کارت‌هایتان
> برنمی‌گردد و ما نمی‌توانیم کمکی کنیم. برنامه بدون ورود هم کامل کار می‌کند.

Two sentences: what is true, and that nothing is being taken away. It does not
promise a backup, because there is not one yet, and it is not repeated or
escalated — a warning that nags every time settings is opened is one the user
learns to swipe past.

It appears only in `AuthStatus.signedOut`, never in `AuthStatus.unknown`. During
the lookup the user may well be signed in, and warning somebody who is signed in
that they cannot recover their cards would be simply wrong.

---

## The address

```bash
flutter run --dart-define=ATILEARN_API_BASE_URL=http://10.0.2.2:5070/api/v1
```

The default is `http://10.0.2.2:5070/api/v1` — the Android emulator's route to
the host. `RemoteConfig.isConfigured` is `false` for exactly that value, and the
client refuses to send anything rather than failing later with a connection error
to a host that was never named.

A production build must set it:

```bash
flutter build apk --release \
  --dart-define=ATILEARN_API_BASE_URL=https://api.atilearn.ir/api/v1
```

`RemoteConfig.isCleartext` reports whether the address is plain HTTP. Cleartext is
allowed in the debug manifest only; the release manifest is untouched, so a
shipped build refuses it. The one-time code travels over this connection, which
is why the split is between build types and not a runtime setting.

---

## Phone numbers

`PhoneNumbers` mirrors the backend's `PhoneNumbers.java` rather than
independently deciding. The app needs the rules for two reasons: to catch an
impossible number before spending a request on it, and to show the number the way
the server returns it.

Both spellings are accepted, because both are the same number and refusing either
would be a decision about house style:

| Typed | Valid | Sent as |
|---|---|---|
| `09121234567` | yes | `0912 123 4567` |
| `0912 123 4567` | yes | `0912 123 4567` |
| `+98 912 123 4567` | yes | `0912 123 4567` |
| `۰۹۱۲۱۲۳۴۵۶۷` | yes | `0912 123 4567` |
| `02112345678` | no | — |
| `08121234567` | no | — |

The digit folding is not decoration. An Iranian keyboard emits U+06F0–U+06F9,
which are digits to a person and letters to a regular expression — without the
fold, every number typed on one was rejected.

The send is deliberately duplicated rather than asked of the server. A wrong
number must be caught with no network at all; a validation that needs a round trip
is not available offline.

---

## The two steps

`AuthCubit` decides which step is showing. The screen has no `bool _codeSent` of
its own to disagree with it.

```
unknown → signedOut ──requestCode──▶ requesting ──▶ codeSent ──verifyCode──▶ verifying ──▶ signedIn
             │                          │              │                        │             │
             └──────────────────────────┴──────────────┴────────────────────────┘             │
                                          failed (any state, user preserved)                    │
                                                                              signOut ─────────┘
```

Every failure lands in `failed` with an `AuthError`, never as an exception. A
sign-in that fails is an ordinary outcome.

The countdown comes from the server's own numbers — `resendAfterSeconds` on
success, `retryAfterSeconds` on a refusal. Guessing would light up a button the
server is about to refuse. It survives a wrong code, because a wrong code does not
lift the server's cooldown, and it stops when the code is locked or expired,
because then a new code is the only way forward.

---

## Where the token lives

`SecureAuthTokenStore`, in the platform keystore. The token is a bearer
credential: whoever holds it is the account, so it is worth a real keystore.

Web and the test runner have none, so there is a fallback to
`SharedPreferences`. It is weaker and it is not silent — a note is logged the
first time it is used. Both stores are written and both are cleared, so a session
is never stranded on a build that could not read it, and signing out really does
remove it.

The token is held in the cubit, not in `AuthState`. A state is printed in errors,
compared by `==`, and kept for as long as the app lives — none of which a
credential should be subject to.

---

## Errors

Every refusal carries the server's Persian `error`, ready to show. The app
branches on `code`, never on the message.

| `code` | What the user sees |
|---|---|
| `invalid_phone` | the complaint under the field, no request spent |
| `invalid_otp` | the server's message, countdown still running |
| `otp_expired` | warning styling, resend free |
| `otp_locked` | warning styling, resend free |
| `otp_cooldown` | the server's remaining seconds |
| `sms_failed` | the server's message |
| `rate_limited` | the server's message |
| `network` | "check your connection", button re-enabled |
| `notConfigured` | "the sign-in server is not set up", and that the app works without it |

Warning styling rather than error styling for the recoverable-by-waiting ones. An
expired code is not a mistake the user made, and presenting it as one reads as
though they had done something wrong.

An unmapped `code` is still a failure — never a silent success — and is passed
through so a future build can learn it.

---

## Running it against a local backend

```powershell
cd D:\litner\AtilearnBackend
docker compose up -d
.\mvnw.cmd package -DskipTests
java -jar src\adapter-web\target\atilearn-adapter-web-1.0.0.jar
```

`sms.provider: development` means no SMS is sent; the code lands in
`D:\litner\AtilearnBackend\target\dev-sms.txt` and in the console:

```
========== DEV SMS ==========
  To:   989121234567
  Code: 444765
  ==============================
```

Then:

```bash
flutter run --dart-define=ATILEARN_API_BASE_URL=http://10.0.2.2:5070/api/v1
```

On a physical device, `10.0.2.2` is wrong — use the machine's LAN address, and
make sure the firewall lets 5070 through.
