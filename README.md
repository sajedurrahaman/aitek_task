# Client Cabinet

Flutter client for the cabinet technical test. The app signs in to the Peanut and Partner services, keeps that session, and opens Profile, Signals, and Promo.

**Estimated implementation time:** 12 hours  
**Actual time spent:** 5 hours

## Submission

| Item | Location |
|---|---|
| Release APK | `dist/client-cabinet.apk` (same build as `build/app/outputs/flutter-apk/app-release.apk`) |
| Source | this repository |
| This document | `README.md` |

Review account, already filled on the sign-in screen:

- Login: `20234561`
- Password: `ladevi31`

```bash
flutter pub get
flutter test
flutter run
flutter build apk --release
```

The release APK is signed with the debug keystore because no upload keystore was provided.

## What is ready to review

| Screen | Required call | Result on the live service, 24 Oct 2026 |
|---|---|---|
| Sign in | Peanut `IsAccountCredentialsCorrect` and Partner `RequestMoblieCabinetApiToken` | Both return a token. Session is stored. Logout clears it. |
| Profile, phone | Peanut `GetLastFourNumbersPhone` | Works. The test account returns `********0000`. |
| Profile, account | Peanut `GetAccountInformation` | The app calls it correctly. The service returns HTTP 500 for a valid token, so the screen shows that error and still shows the phone. |
| Signals | Partner `GetAnalyticSignals` | The app calls it correctly with `passkey`. The service returns HTTP 500 with an empty body, so the screen shows an archive error and a retry. |
| Promo | SOAP `GetCCPromo`, `lang=en` | Works after trusting this host's expired certificate. Cards, images, and external links render. |

The other operations on the Peanut Swagger page are not part of this test. They are listed at the end so a reviewer can see they were considered and left out on purpose.

## Architecture

Feature-first clean architecture. A screen talks to a repository interface. The repository checks connectivity, then the data source builds the HTTP or SOAP call. Widgets do not parse JSON or XML.

```text
lib/
  main.dart          composition root
  app.dart           theme, session gate, offline banner
  core/              Dio client, errors, secure session store, shared widgets
  features/auth/     data / domain / presentation
  features/profile/
  features/signals/
  features/promo/
  features/home/     bottom navigation on a phone, navigation rail from 900px
```

`AuthCubit` owns the session. Profile, signals, and promo cubits are created with that session and closed on sign-out. Only the selected tab is mounted. Cubits keep the loaded data, so changing tabs does not repeat a successful request. Rotation is handled by Flutter (`configChanges` includes orientation). Coming back to the foreground rechecks connectivity. If the process was killed, the secure store restores the login and both tokens.

## Technical decisions

- Cubit for each screen. These flows are one request and one result.
- Dio, 15 second connect timeout. The body is read as text and then decoded, so `Access denied` and the SOAP envelope are not dropped by a JSON parser.
- `flutter_secure_storage` stores the login, Peanut token, and Partner token. The password is not stored.
- `connectivity_plus` shows the offline banner and blocks a request when the device reports no network. A socket failure is still shown as a network error.
- The two profile calls are independent. Phone can succeed while account information fails.
- Signals load only when the user taps **Load signals**.
- Currency codes in the Peanut schema are unnamed integers `0` to `4`. The screen labels them USD, EUR, RUB, GBP, JPY, in that order, because the documented sample uses `0`. Any other value is shown as `Code N`.
- Content width is capped at 860px. At 900px and wider the bottom bar becomes a navigation rail.

## API reference

Peanut routes come from `https://peanut.ifxdb.com/swagger/v1/swagger.json`, the document behind `https://peanut.ifxdb.com/docs/clientcabinet/index.html`. The published path prefix is `ClientCabinetBasic`. The Partner path keeps the service spelling `Moblie`.

### 1. Peanut authorization — working

`POST https://peanut.ifxdb.com/api/ClientCabinetBasic/IsAccountCredentialsCorrect`

```json
{ "login": 20234561, "password": "ladevi31" }
```

Success:

```json
{ "result": true, "token": "<peanut token>" }
```

An unknown login returns HTTP 401 and `{ "result": false, "token": "" }`. The screen says the login or password is incorrect. A bad token on a later Peanut call returns the plain text `Access denied`; the app clears the session and asks the user to sign in again.

The test login currently returns `result: true` even when the password sent to the server is empty. The app still requires a password and still sends it.

### 2. Partner authorization — working

`POST https://client-api.contentdatapro.com/api/Authentication/RequestMoblieCabinetApiToken`

The body is the same `{ "login", "password" }` object. Success is a JSON string, the partner token. The app stores it and later sends it as the signals `passkey`. Sign-in finishes only when both tokens exist. One failure does not leave a half-saved session.

### 3. Phone — working

`POST https://peanut.ifxdb.com/api/ClientCabinetBasic/GetLastFourNumbersPhone`

```json
{ "login": 20234561, "token": "<peanut token>" }
```

Success is a JSON string. For this account it is `********0000`. That value is the Phone row. The `phone` field inside account information is a hash in the documented sample, so the app does not show that field as a phone number.

### 4. Account information — called correctly, service returns 500

`POST https://peanut.ifxdb.com/api/ClientCabinetBasic/GetAccountInformation`

Same body as the phone call: `{ "login", "token" }`.

Checked behavior:

- A wrong token returns HTTP 500 and the text `Access denied`. The app treats that as an expired session.
- The token from a successful login is accepted far enough to pass that check, then the service returns HTTP 500 with a WCF fault: “The server was unable to process the request due to an internal error.”
- `GetPersonalInfo` on the same Swagger page, with the same body, returns the same fault. It is not a substitute, and the task does not ask for it.

The Profile screen keeps the login and the phone, shows “The service is temporarily unavailable,” and offers Retry. When the service starts returning the documented object (`name`, `balance`, `equity`, `freeMargin`, `leverage`, address fields, and the numeric `currency`), the same parser will render those fields. No client change is required for that.

### 5. Signals — called correctly, service returns 500

`GET https://client-api.contentdatapro.com/clientmobile/GetAnalyticSignals/{login}?tradingsystem=3&pairs=EURUSD,GBPUSD&from={unix}&to={unix}`

Header: `passkey: <partner token>`

This matches the assignment example: trading system `3`, comma-separated pairs, unix seconds. The end date includes that local day through 23:59:59. The pair list is the seven test symbols: EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD.

Checked behavior:

- No `passkey`, or `Authorization: Bearer` alone, returns HTTP 403. The header name is `passkey`.
- The same request with a valid `passkey` returns HTTP 500 and an empty body. This was reproduced for one pair, several pairs, `pairs[0]` form, a 7-day range, a 30-day range, and the sample 2016 range from the assignment.
- `POST` to that URL returns HTTP 404, so the method is GET.

The screen shows: “The signals service could not return this archive. Try fewer pairs or a shorter date range.” Retry calls the same endpoint again. A JSON list, or an object that contains a list, is parsed into cards (pair, buy/sell, entry, take profit, stop loss, time, period). `cmd` `0` is Buy and `1` is Sell.

### 6. Promo — working

`POST https://api-forexcopy.contentdatapro.com/Services/CabinetMicroService.svc?lang=en`

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
  <soap:Body>
    <tem:GetCCPromo>
      <tem:lang>en</tem:lang>
    </tem:GetCCPromo>
  </soap:Body>
</soap:Envelope>
```

`SOAPAction` is `http://tempuri.org/CabinetMicroService/GetCCPromo`, taken from the WSDL.

Two service quirks are handled in the client:

1. The host certificate is expired (`curl` error 60). Android rejects the handshake, which is why the first build showed “The connection was interrupted” even though the phone was online. The app now accepts a bad certificate only for `api-forexcopy.contentdatapro.com`. Every other host is still verified.
2. `GetCCPromoResult` is not a list of XML cards. It is a JSON object embedded in the SOAP body. Keys are campaign names. Each value has `image`, `text`, `link`, and `button_text`. Booleans arrive as `True` / `False` and are normalized before decoding. Image hosts `forex-images.instaforex.com` are rewritten to `forex-images.ifxdb.com`. The button opens the `link` outside the app.

Verified on a device after the fix: Forex Copy and Ferrari cards render with images and their action buttons.

## Peanut operations that are not used

The Swagger page also publishes Bonus, Open Account, trades, balance history, withdrawals, leverage, password, swap, FAQ, and app-update methods. Examples: `GetOpenTrades`, `GetClosedTrades`, `GetPersonalInfo`, `GetMyStats`, `opendemoaccount`, `activatestartupbonus`.

This test asks for three Peanut methods only: `IsAccountCredentialsCorrect`, `GetAccountInformation`, and `GetLastFourNumbersPhone`. The signals call and the promo call are on different hosts and are not on that Swagger page. Those extra Peanut operations are not called.

## Session, errors, and network

- Sign-in, logout, and an expired token all go through `AuthCubit`.
- HTTP 401, HTTP 403, or a body containing `access denied` on an authenticated call clears secure storage and returns to the sign-in screen with “Your session has expired.”
- Login HTTP 401 is invalid credentials, not an expired session.
- No network, a timeout, or a dropped socket shows a connection message and leaves the last successful data in place when there is any.
- Empty promo or signal results have their own empty state. The current signals failure is a 500, so it uses the error state, not the empty state.

## Reusable verification module

I would ship verification as its own package, not as screens copied into each app.

The package would expose one entry point, `VerificationFlow.start(context, dependencies)`, and return a sealed `VerificationResult` (`completed`, `cancelled`, `failed`). Inside the package the flow is a state-machine Cubit. Each step is a sealed state (`collectDocument`, `confirmCode`, `pendingReview`), and only that Cubit moves between them. Host apps do not import step widgets.

Dependency isolation is a small set of interfaces passed in at the start: `VerificationApi`, `SecureStore`, `Clock`, `Analytics`, and `VerificationTheme`. The package does not construct the host Dio client, read the host route table, or call another feature’s repository. Tests replace those interfaces with fakes. A host with a different backend implements `VerificationApi` and leaves the flow alone.

Navigation stays inside a nested `Navigator` owned by the package. The host pushes one route, or presents one modal, and waits for the result. Deep links enter through a single `VerificationEntry` route that the package registers. Step routes are private to the nested navigator, so a host refactor cannot change the order of the steps. The back button walks the nested stack first. Leaving the flow returns `cancelled`.

Visuals come from the theme argument: colors, type, and padding. Country-specific copy and document rules stay behind `VerificationApi`, so another app reuses the same state machine.
