# MEMORY

Checkpoint for the Atilearn sign-in + server-backed-data project.

Last updated: 2026-10-07. Read this first in a new session.

---

## 1. Where the work is

| Thing | Path |
|---|---|
| Flutter app | `D:\litner\laitner` |
| Java backend | `D:\litner\AtilearnBackend` (sibling of the app, **not** inside it) |
| 3DP reference impl | `D:\3DP` (read-only reference, never modified) |

The backend was moved out of the Flutter repo at the user's request. Do not move it back.

---

## 2. Production server — already deployed and verified

`185.239.3.63`, Windows Server 2025, IIS, PostgreSQL 18, 4 GB RAM, ~9.3 GB free on C:.

The machine runs **12 other live IIS sites**. Nothing existing may be modified.

| Piece | Value |
|---|---|
| JDK 21 | `C:\tools\jdk21` — Temurin zip, **no installer, not on PATH, no registry entry** |
| Service | `AtilearnBackend`, via NSSM at `C:\nssm\win64\nssm.exe`, `Automatic` |
| JVM flags | `-Xmx256m -Xms128m -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8` |
| App listen | `127.0.0.1:5020` — loopback only, unreachable from the internet |
| IIS site | `AtilearnApi` → `http *:5050:` → proxies to `127.0.0.1:5020` |
| App pool | `AtilearnApiPool`, `managedRuntimeVersion=""` (No Managed Code), `AlwaysRunning` |
| Physical path | `C:\sites\atilearn\iis` (web.config only, ARR rewrite rule) |
| Config | `C:\sites\atilearn\config\application.yaml` — **contains no secrets**, ACL = Admins + SYSTEM |
| Secrets | NSSM `AppEnvironmentExtra`, REG_MULTI_SZ, exactly 3 entries |
| Logs | `C:\sites\atilearn\logs\` — `service-out.log` rotates at 10 MB |
| Database | db `atilearn`, role `atilearn` (`NOSUPERUSER NOCREATEDB NOCREATEROLE`) |
| Tables | `flyway_schema_history`, `otp_challenges`, `users` — created by Flyway on first run |
| SMS | `sms.provider: development` → code written to `logs\dev-sms.txt`, **no SMS sent** |
| Public URL | `http://185.239.3.63:5050/api/v1` |
| Firewall | inbound 5050 open. Rule registered with `Profile: Any`, not `Public` — loose but harmless since the live profile IS Public |

### Verified end-to-end from the public internet

`POST /otp/request` → `POST /otp/verify` → `GET /auth/me` (valid token, 200) → `PUT /auth/profile` (Persian display name written and read back). Rate limiting confirmed live (a second request got 429 with `retryAfterSeconds: 20`).

### Gotchas learned the hard way

- **NSSM `set AppEnvironmentExtra` REPLACES the list, it does not append.** Setting it twice with one arg each silently destroyed the first entry. Write all three in ONE call, or set the registry value directly:
  ```powershell
  $k = "HKLM:\SYSTEM\CurrentControlSet\Services\AtilearnBackend\Parameters"
  Set-ItemProperty -Path $k -Name AppEnvironmentExtra -Type MultiString -Value @("A=1","B=2","C=3")
  ```
- **Never put a secret in YAML.** A password starting with `@` broke the parse (`cannot start any token`), and a `#` would truncate the line. Secrets go in env vars only.
- PostgreSQL 18 mounts its volume at `/var/lib/postgresql`, not `/var/lib/postgresql/data` — only matters for the local Docker copy.
- `$w = @'...'@` (single-quoted here-string) is required for any file containing `{R:1}` or other `$`-like tokens; `@"..."@` would interpolate them.

---

## 3. Java backend — built and green

`D:\litner\AtilearnBackend`. 5 Maven modules, Spring Boot 4.0.2, Java 21. **73 tests pass.**

```
domain / app / adapter-persistence / adapter-sms / adapter-web
```

Sign-in endpoints: `POST /auth/otp/request`, `POST /auth/otp/verify`, `GET /auth/me`, `PUT /auth/profile`.

Sync endpoints, all scoped to the caller: `GET /sync/collection`, `PUT /sync/collection`,
`POST /sync/review-logs`.

Device endpoints: `GET /devices`, `DELETE /devices/{deviceId}`.

Migrations: `V1` identity, `V2` content (spaces/decks/cards/review_logs), `V3` devices.
All three verified against real PostgreSQL, not only H2.

### Devices — the shape of the feature

- `device_id` is a UUID minted by the app and stored in the **JWT** as a `device`
  claim. A header would be forgeable and would make "sign out that device" decoration.
- A token with **no** device claim is let through and not registered: those predate
  devices and refusing them would sign out every install on deploy.
- Signing in does **not** sign anything else out. This is the soft model: list,
  remove, and the removed device finds out on its next call.
- Only the **sync** endpoints check. A removed device gets `401 device_signed_out`
  (its own code, so the app can forget its token and explain rather than showing a
  signed-in screen where everything fails).
- `TokenIssuer.issue(userId, phone, deviceId, lifetime)` — the deviceId may be null.
  `AuthService.verifyCode` has a 3-arg overload delegating with null, so the ~15
  existing call sites and tests were left alone.

**Not done:** the client half. No `deviceId` is generated or sent by the app, no
settings screen, no warning banner. And the deployed jar is now **three migrations
behind** — redeploying is a separate, undone step.

### The sync server is built and verified — but the deployed jar is stale

The jar on the server predates all of this. Redeploying is a separate step that has
not been done.

**The time-zone trap — do not remove this setting.**
`hibernate.type.java_time_use_direct_jdbc: true` in `application.yaml` and in the
test config. Without it pgjdbc routes `LocalDateTime` through `java.sql.Timestamp`
and converts it **in both directions** using the JVM's zone. The API round trip then
looks perfect while the column holds a shifted value (09:30 stored as 06:00), and
the illusion breaks when the service and the database stop agreeing. Found only by
running against real PostgreSQL — H2 does no such conversion, so **no test in the
repo can catch it**. That setting also lives in the test config so both environments
bind the same way.

**Tests do not run the migrations.** `src/adapter-web/src/test/resources/application.yaml`
sets `flyway.enabled: false` and `ddl-auto: create-drop`, so Hibernate generates the
schema from the mappings. The integration tests therefore verify the controllers and
the mappings, **not** `V1`/`V2`. The migrations are verified by running the app
against real PostgreSQL, which is what the compose file is for. Both checks pass, but
they happen in different places — do not report one as the other.

OTP rules mirror `D:\3DP\3DPBackend\...\AuthService.cs`: 6-digit SecureRandom code, SHA-256 of `"{pepper}:{phone}:{code}"`, 5-min expiry, 120s resend cooldown, 5 max attempts, constant-time compare, SMS failure rolls the row back.

Build/test: `.\mvnw.cmd test` from the backend root, with
`$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"`.

### Boot 4 traps already hit

- `HibernateJpaAutoConfiguration` → `org.springframework.boot.hibernate.autoconfigure`
- `DataSourceAutoConfiguration` → `org.springframework.boot.jdbc.autoconfigure`
- `@EntityScan` **removed**; entities are discovered from the application class's package
- `HibernatePropertiesCustomizer.customize(Map<String,Object>)` — not the settings object
- `@AutoConfigureBefore` and `@DependsOn` on `@Configuration` do **not** order Flyway before JPA. What works: the migrator is a constructor/parameter dependency of a bean Spring Boot collects while building the EMF (`MigrateFirst` inside `HibernatePropertiesCustomizer`).
- `jjwt-impl` must be **compile** scope. With runtime scope the app starts and only dies on the first token request.
- `Profiles.of("prod*")` matches **nothing**, and `Profiles.of("prod","production")` matches neither. `SmsConfiguration.isProduction` compares the active names itself.
- Tests need `TIMESTAMP WITH TIME ZONE`, not `TIMESTAMPTZ` — H2 rejects the alias even in PostgreSQL mode.

A full README with the layout, endpoints, rules and gotchas is at `AtilearnBackend/README.md`.

---

## 4. Flutter app — current state

`D:\litner\laitner`. **506 tests pass** (260 pre-existing + 107 auth + 40 device + 99 sync). `dart analyze` has zero errors; the 4 pre-existing warnings were verified via `git stash` and must be left alone.

### Sign-in feature (complete, tested, not yet shipped to users)

```
lib/core/remote/remote_config.dart                  base URL, String.fromEnvironment
lib/domain/entities/phone_numbers.dart              validation + normalisation
lib/domain/entities/auth_user.dart
lib/domain/entities/auth_error.dart                 AuthFailure enum + AuthError
lib/domain/repositories/auth_token_store.dart       interface
lib/data/datasources/auth_api_client.dart           the 4 endpoints
lib/data/datasources/secure_auth_token_store.dart   keystore + preferences fallback
lib/presentation/blocs/auth/auth_cubit.dart         the state machine
lib/presentation/blocs/auth/auth_state.dart
lib/presentation/screens/sign_in_screen.dart
lib/presentation/widgets/account_section.dart        settings tile + the warning
lib/core/remote/README-auth.md                      full doc
test/auth/                                          104 tests
```

`http` and `flutter_secure_storage` were added to `pubspec.yaml` as direct deps.

### Sync — the contract, built and tested, not yet wired to anything

```
lib/domain/services/id_generator.dart                  IdGenerator port
lib/data/utils/uuid_id_generator.dart                  UUID v4 impl
lib/domain/repositories/sync_remote.dart               SyncRemote port + SyncCollection
lib/domain/repositories/sync_state_store.dart          SyncStateStore port (the watermark)
lib/domain/usecases/sync_collection_usecase.dart       SyncCollectionUseCase
lib/domain/usecases/reconcile_card_progress.dart       rebuilds box from the history
test/support/in_memory_sync_state_store.dart
test/support/fake_sync_remote.dart
test/sync/sync_collection_usecase_test.dart            21 tests
test/sync/reconcile_card_progress_test.dart            10 tests
```

**Nothing is registered in `injection.dart` yet and nothing calls it.** It exists so the
server has a specification to implement against.

#### The three endpoints the server must provide

| Call | Meaning |
|---|---|
| `replaceCollection(spaces, decks, cards)` | Replace the structure. Never touches review history. |
| `appendReviewLogs(logs)` | Append. An id already held is **upserted, not duplicated**. |
| `pull()` | Return the whole collection, history included. |

#### Rules the tests encode

- **Structure is uploaded only when the device has some.** An empty device must not erase
  an account. This was a real hole: an earlier single-`push` design sent empty lists and
  the server could not tell "nothing to say" from "erase everything".
- **The watermark is written only after a successful upload.** Written optimistically, a
  failed upload is never retried and a review is lost silently.
- **The comparison is `>=`, not `>`.** The newest entry is re-sent on every sync. That
  costs one row and is deliberate: `DateTime.now()` is millisecond-resolution on some
  platforms, so an entry can share a timestamp with the last one uploaded, and `>` would
  drop it. Review log ids are deterministic, so the re-send upserts.
- **`download()` exists** for the explicit "throw away this device and take the server's
  copy" case. It is never automatic.
- **Push then pull.** Push first so the pull can only add. Pulling first would overwrite
  local work the server had never seen.
- **A pulled collection is corrected before it is stored.** `Flashcard.box` and
  `lastReviewed` are derived from the history, so after a merge they are rebuilt from the
  newest review (`reconcile_card_progress.dart`, applied in `SyncCollectionUseCase._apply`,
  so `download` gets it too). Without this a device that had been offline would push a
  week-old box over reviews another device had already recorded, and the card would slide
  backwards with nothing to show it. A card with **no** reviews is left alone — treating
  "no history" as "box 1" would reset every card somebody had created but not studied.
  Ties are broken by id, because the clock has millisecond resolution on some platforms
  and a cache that disagreed with itself between runs would be worse than a slow one.
  The server's own copy is left stale on purpose: it is never read without passing through
  here first, and the next sync uploads the corrected structure over it.

Two `prefer_initializing_formals` infos in `sync_collection_usecase.dart` are left alone:
the codebase has ~20 of the same, and the lint's suggestion is illegal for a private
field on a public named constructor.

### Active devices — the client half

```
lib/data/datasources/device_identity.dart              device id + label, DeviceLabelSource
lib/domain/entities/auth_device.dart                   a device as the app sees it
lib/domain/repositories/device_remote.dart             DeviceRemote port
lib/data/datasources/auth_api_client.dart              also implements DeviceRemote
lib/presentation/blocs/devices/active_devices_cubit.dart + _state.dart
lib/presentation/widgets/active_devices_section.dart   settings section + warning
test/device/                                           40 tests
```

- The device id is minted once and kept under `recall.device.id` — **not** under the auth
  namespace, so signing out and back in does not add a row to the list every time.
- It is sent **at sign-in and nowhere else**. It travels into the token the server hands
  back, and a device that could name itself on a later call could rename itself out of a
  sign-out.
- `AuthCubit.deviceIdentity` is **optional**, so the ~15 existing auth tests were untouched.
  A failure to read it costs the device its row in the list, and nothing else.
- The warning condition is `ActiveDevicesState.anotherDeviceIsNewer` — computed purely
  from the list, false when this device's own `lastSeenAt` is unknown. A comparison that
  cannot be made cannot justify a warning, and an unjustified warning is one the user
  learns to dismiss.
- `lastUsedLabel` compares in **UTC**. These timestamps are the server's clock, so a local
  timezone applied to them would be wrong by exactly the offset.
- The server answers the device list wrapped in `{"devices":[...]}`, not as a bare array.
  A top-level array cannot grow, and `_send` would have had to accept two shapes of
  success.
- `ApiTransport` was extracted from `AuthApiClient` when sync arrived: both talk to the
  same service, with the same base address, timeout and error shape. **This removed
  `dart:io` from `auth_api_client.dart`**, so one of the two web-build blockers is gone;
  the other (`notification_service.dart`) remains.
- `HttpSyncRemote` leans on the entities' own `toJson`/`fromJson` — the same methods the
  backup file uses — so there is no second wire format to keep in step. A field added to a
  card reaches the server without anybody editing the remote.
- `AuthFailure.deviceSignedOut` and the `device_signed_out` mapping. It is in
  `canRetryImmediately == false`: signing in again is what fixes it, not trying harder.
- `PreferencesSyncStateStore` keeps the watermark as a **local** ISO string, matching the
  history it is compared against. Storing it as UTC while the history stayed local would be
  the thing that broke the comparison — an entry just after the watermark could read as
  before it and never be uploaded.
- `SyncCollectionUseCase` and `HttpSyncRemote` are registered in DI, and the sync screen
  below is what runs them.

### The sync screen

```
lib/presentation/blocs/sync/sync_cubit.dart + _state.dart
lib/presentation/widgets/sync_section.dart
```

- `SyncSection` renders for somebody signed in **and** for somebody who has just been
  signed out from elsewhere. That second case is the one that matters: once the token is
  gone there is no account block left to explain anything, and without it the app would
  simply appear to have forgotten the user.
- `SyncCubit` handles `deviceSignedOut` itself, calling an injected
  `onSignedOutElsewhere` callback (DI wires it to `AuthCubit.signOut()`). Every caller of a
  sync would otherwise have to know that one code, and whichever forgot would leave the
  user on a screen whose every action fails.
- `reviewsSinceLastUpload()` counts strictly **after** the watermark, unlike the send,
  which includes the boundary entry. Counting the same way would leave the badge reading
  "1" forever, and a badge that never clears is one the user stops seeing.
- `SyncStateStore` gained `readLastSyncedAt`/`writeLastSyncedAt`, cleared with the rest on
  sign-out.
- `_SyncCard.syncStatusLine` compares in **local** time, unlike the device list: this
  timestamp is written by this device's own clock, so comparing it with `DateTime.now()` is
  the right thing. The device list compares the *server's* clock and works in UTC for that
  reason.
- **Auto-sync** runs on start and on returning to the foreground, from `main.dart`. It is
  throttled **in memory** (5 minutes): the point is to stop a burst of app switches from
  each starting a full pull, and a fresh launch always gets one attempt — which is how a
  dropped connection recovers. It is **silent about failures** but still refreshes the
  pending count, because that count is the signal the user acts on. It does nothing when
  nobody is signed in, checked against the token store rather than left to the remote —
  leaving it to the remote would leave a failed status behind an account that does not
  exist.
- **A sign-out clears the sync state.** `AuthCubit` takes `onSessionEnded`, wired in DI to
  `SyncStateStore.clear()`, and every path that ends a session calls it: an explicit
  sign-out, an expired token, and a rejected token. Without it, signing out and then
  signing in as **another account** left the previous watermark in place, and every review
  older than it was silently never uploaded. That was the most serious bug found in this
  project — silent data loss with no symptom to notice.
- The removal notice is gated on **not being signed in** as well as on the flag. The flag
  outlives the sign-out it describes, so a stale one would otherwise accuse somebody who
  had since signed in.

### Android cleartext — the facts

- `targetSdk = 36`. Merged release manifest has **neither** `usesCleartextTraffic` nor `networkSecurityConfig`, so cleartext is blocked **by Android's default for API ≥ 28**.
- This is a *default that can be opted into*, not a prohibition. `android:usesCleartextTraffic="true"` in the main manifest, or better, a `res/xml/network_security_config.xml` scoped to just the server host. One file, deleted later when HTTPS arrives.
- `android/app/src/debug/AndroidManifest.xml` already sets `usesCleartextTraffic="true"` (debug only).

### Signing / reinstall (data preservation)

- `applicationId = com.recall.recall`, release signed with `android/recall-release.jks` via `android/key.properties`. Unchanged signing + same applicationId means **an in-place upgrade keeps all user data**.
- Installing a **debug** APK over a release build would fail (different signature) and require an uninstall = **data loss**. Always build release.
- ⚠️ **Unresolved security issue:** `android/key.properties` holds the literal release passwords in plaintext and `.gitignore` has no entry for `key.properties` / `*.jks`. Not investigated whether they are tracked. Flagged to the user once, not acted on.

---

## 5. The architectural decision being made

### Context

The user wants to put the app on the web because **iOS apps cannot practically be distributed in Iran** (App Store is not usable). Web/iOS work is **explicitly postponed** — do not start it.

### Decisions made

1. **Model A — two modes in one app:**
   - No account → exactly as today: offline-first, data on device. **Zero code change.**
   - With account → server-backed, local DB becomes cache + write queue.
2. Web/iOS postponed.
3. User chose to **refactor the app's data layer first**, before building the server-side data model and APIs. (I recommended server-first as the safer order; user overrode. Commitment made: the app must be fully working at the end of every step, never half-migrated.)

   **Done so far, both steps verified with the full suite green and an APK built:**
   - `generateId` extracted out of `LocalDataSource` into its own port.
   - The sync contract (`SyncRemote`, `SyncStateStore`, `SyncCollectionUseCase`) written and
     tested with a fake server. Nothing wired into the app yet.
   - Finding: the data layer needed far less than feared. `getAll*` and `replaceCollection`
     already are the push and pull primitives, and an append-only review log means the delta
     is a watermark comparison. The remaining work is the server and the wiring, not a
     rewrite of the 383 tests.

### Why the conflict problem is mostly solved

Flashcard data is unusually sync-friendly. The bulk of it is an append-only event log, which merges by union and cannot conflict. Derived state (Leitner box position, due queue) is recomputed, never synced, so it cannot conflict either. Only concurrent edits to card text and deck structure are genuinely lossy.

Grounding: the Anki manual (`docs.ankiweb.net/syncing.html`) states reviews and note edits merge normally; both reviews of the same card are kept in the revision history and the card takes the most recent answer; structural changes (adding a field, removing a template) cannot merge and force a one-way sync where **one side is lost**.

Anki is local-first for historical reasons (offline study, pre-cloud). This project wants server-as-truth, which is a different and simpler problem.

---

## 6. Load-bearing facts about the app's data layer

Expensive to re-derive. Verified by reading the code.

### Seams

- `LocalDataSource` (`lib/data/datasources/local_data_source.dart`) has **21 members**. It used to also own `generateId()` — that was extracted to `IdGenerator` (`lib/domain/services/id_generator.dart`) so the presentation layer no longer depends on the storage interface at all. Five cubits previously took the whole interface only to call that one method.
- **Three storage mechanisms wired side by side with no shared transaction scope:** Isar via `LocalDataSource`, `ExcelImportStore` (SharedPreferences), `SpaceSettingsStore` (SharedPreferences). `AuthTokenStore` is a fourth and is already isolated and optional.
- `replaceCollection` is the only bulk primitive, atomic on Isar only, and has **one** production caller (`restore_collection_backup_usecase.dart:54`) which then does three more non-atomic writes.
- `delete_space_usecase.dart:22-46` is the widest operation and is **not atomic anywhere**: N× `updateDeck`, review-history reassign (whole-table rewrite), excel-import reassign, then `deleteSpace`, plus an unconditional `SpaceSettingsStore.delete`.
- `getCardsBySpaceId` has no data-source counterpart — it fetches all cards and filters in Dart (`flashcard_repository_impl.dart:14-21`). Used in 5 places; would be a full scan on a server.

### Entities

- `ReviewLog`: `id, spaceId, cardId, deckId, rating, boxBefore, boxAfter, reviewedAt`. Stores a **state snapshot** (`boxBefore`/`boxAfter`). `spaceId` is denormalised, which is why deleting a space must touch history separately.
- **Review log ids are deterministic**: `'${reviewedAt.microsecondsSinceEpoch}-${card.id}'` (`review_card_usecase.dart:72`). This is deliberate — it makes a retried review overwrite instead of duplicating. **A server that mints its own ids breaks that idempotency.**
- `Flashcard`: `id, deckId, front, back, box, lastReviewed, createdAt, tags, frontStyle, backStyle, media`.
- `generateId()` is UUID v4, synchronous, client-side, in both implementations.
- **Leitner state lives in two places:** `Flashcard.box` (per card) and `LeitnerBoxConfig` (per space, inside settings). "Is learned" is `box > settings.leitnerBoxes.maxBox`, derived across two stores that must sync together.
- `CardMedia.relativePath` is a **device-local filesystem path embedded in the card record**. The media store is outside every repository; its web implementation throws `UnsupportedError`. Media is **not** deleted when a card or space is deleted, and is **not** in `CollectionBackup`. `CardMedia.id` is a microsecond timestamp, not a UUID.

### The hard one: Excel imports

`ExcelImport` is an **entire spreadsheet as one JSON blob per file** under `recall_excel_imports_v1`, unbounded row count. Four use cases mutate it by full read-modify-write of the whole blob (`update_excel_row`, `remove_excel_rows`, `add_selected_excel_rows`, `sync_excel_import_added_status`). It carries client-derived `isAdded`/`addedAt` kept in sync by diffing against live cards — entirely client-side today. **This is the hardest data to move server-side.**

### Implementation divergences (Isar vs Web) that must be decided, not inherited

- `update*` is an **upsert** on Isar (inserts a phantom row if missing) and a **silent no-op** on web.
- `deleteDeck`/`deleteSpace` are transactional on Isar, multiple non-atomic writes on web.
- `replaceCollection` is one wipe+rewrite on Isar, four independent `SharedPreferences` writes on web with no wipe-first.
- The test fake `InMemoryLocalDataSource.deleteSpace` also deletes review logs — **neither production implementation does**.

### Test coupling

- 4 test files construct `InMemoryLocalDataSource` (which deliberately mirrors production semantics).
- 7 test files use `FakeReviewHistoryRepository` — **the repository interface is the more-coupled seam, not the data source.**
- 24 further hand-rolled repository fakes inline across 12 test files.
- Production `LocalDataSource` implementations are **never directly tested**.

### Use cases

40 files. Writers: 17. Readers only: 12. Pure computation: 4 (`leitner_logic`, `build_reminder_schedule`, `build_daily_excel_feed_plan`, `statistics_aggregator`).
Four use cases and five cubits take a raw `LocalDataSource` rather than a repository.

---

## 7. Open decisions — do not guess these

1. **HTTP vs HTTPS for the release APK.** The user correctly challenged my earlier claim that release "blocks" HTTP. The accurate statement: their *current* build blocks it because the flag is absent and targetSdk is 36; one line opts in. Security still argues for HTTPS, but the choice is theirs. No domain exists yet.
2. **Whether reminder settings sync.** `ReminderSettings.hour/minute/daysOfWeek` and `dailyExcelFeed.lastRunDay` are device-local by nature. The current code encodes no opinion.
3. **Media on the server.** Only 9.3 GB free. Card images/audio need upload; `relativePath` is meaningless on another device. This is the biggest hidden cost and should be settled before the rest.
4. **First-sync direction when a user signs in with existing local data.** Partly settled:
   `sync()` is now safe by default — a device with no spaces does not upload structure, so
   a fresh sign-in cannot erase an account — and `download()` covers the explicit "replace
   this device" case. What is still open is the *preference* when both ends have different
   structure: currently local always wins, silently. A UI decision.
5. **Real Kavenegar SMS.** Needs the API key and verification template. Currently `development` mode.

---

## 8. Bugs found by tests during this work

Both were real production bugs, not test bugs:

- `AuthState.failed` dropped the signed-in user, so a failed display-name save showed the user as signed out. Fixed with `failedWhileSignedIn`; `isSignedIn` now keys on `user != null` across `signedIn` and `failed`.
- The resend countdown reset to zero on a wrong code, lighting up a button the server was about to refuse. Now carried through `verifying` and preserved on ordinary failures, cleared only when the code is locked or expired.

And two validation bugs that would have rejected every real number:

- `PhoneNumbers.isValid` checked `substring(2)` instead of `substring(1)`, rejecting all valid Iranian mobiles.
- `+98 912...` was not accepted at all.

---

## 9. House rules for this project

- Run Maven from `AtilearnBackend` root: `.\mvnw.cmd test`. Never `-pl` alone.
- **Changing a method signature may need `clean`.** After `TokenIssuer.issue` gained a
  parameter, `mvn test` did not recompile a test that implemented it with a lambda, and
  the failure surfaced as `AbstractMethodError` at run time rather than a compile error.
  When an interface changes and the tests fail strangely, run `.\mvnw.cmd clean test`.
- Do not "fix" the 4 pre-existing analyzer warnings in the Flutter app.
- Dart records have no structural `==`; map to fields before comparing.
- `SpaceSettingsStore.load` returns a default on `FormatException`/`TypeError` — round-trip values in tests, this bit the project before.
- Keep answering in Persian.
- Give deployment steps as short, individually-pasted commands. A long paste with special characters previously got mangled mid-way and left the console stuck at `>>`.
- The user is terse and does not want unsolicited security lectures. Mention a risk once, plainly, then respect the decision.
