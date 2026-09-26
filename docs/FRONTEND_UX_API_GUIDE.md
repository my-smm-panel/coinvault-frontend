# CoinVault Frontend UX & API Guide

## Source of truth

The Android app is a client of the CoinVault API hosted on Render. The backend/PostgreSQL owns wallet balances, rewards, eligibility, spins, referrals, withdrawals, and redemption. Firebase is used for sign-in identity only; **this frontend change does not move coin balances to Firestore**. The app does not calculate, grant, deduct, or persist coin balances locally. It keeps only the most recently fetched balance in memory and clears it on sign-out or account change.

## Sign-in and session flow

1. On launch, Firebase restores the user's sign-in state. A cached profile may supply only display name, email, and avatar—not financial values.
2. The app sends the Firebase ID token to `POST /api/auth/google` on the Render API, without a backend bearer token. The API returns a backend access JWT.
3. Protected requests send `Authorization: Bearer <backend-JWT>` and `Accept: application/json`.
4. The app enters protected screens only after backend authentication succeeds. If it cannot obtain a backend JWT, it stays at sign-in and shows a retryable connection message rather than opening a half-loaded dashboard.
5. On sign-out, the backend token and in-memory wallet balance are cleared.

## Screen data and actions

### Request lifecycle

The mobile app sends requests to the Render API base URL configured in `lib/core/api_config.dart`. `ApiClient` encodes JSON, sets `Accept: application/json`, and applies a 15-second timeout. For protected requests it adds `Authorization: Bearer <backend-JWT>`. Public catalog/health requests explicitly disable auth where needed. A resource ID is URL-encoded before it is added to the offer-start path. The UI treats a valid successful empty list as empty; a failed or malformed response is unavailable and should show an error/retry state, not a fake zero or mock record.

The Earn screen loads surveys, general offers, activity, Offerwall.GG offers, and Paymentwall offers. It shows activity counts, not an estimated balance or promised rewards on offer cards. The Home and Wallet screens fetch the authenticated wallet balance. Earn categories are navigation/filter controls only; they do not decide eligibility or rewards. Selecting a general offer opens its detail and calls the backend start route only when the user chooses to start. Provider offers route into the corresponding provider catalog, where its server-returned start URL is used.

| UX area | Read/API call | User action |
| --- | --- | --- |
| Home wallet | `GET /api/wallet/balances` (auth) | Shows only the authenticated available balance; no locally calculated earned total. |
| Offers/tasks | `GET /api/offers` (public catalogue) | `POST /api/offers/:id/start` (auth); server supplies any tracking destination/reward data. |
| Offerwall.GG | `GET /api/offerwall-gg` (auth) | `POST /api/offerwall-gg/:id/start` (auth). |
| Paymentwall offers | `GET /api/offers`, filtered to records whose backend provider is Paymentwall | Uses the verified generic `POST /api/offers/:id/start`; no unsupported `/api/paymentwall` catalogue is called by the app. |
| Surveys | `GET /api/surveys` (public) | `POST /api/surveys/:id/start` (auth); open only the URL returned by the server. |
| Spin | `GET /api/spin/status`, `GET /api/spin/history` (auth) | `POST /api/spin/spin` (auth). The server chooses and credits the result; the UI refreshes balance/status. |
| Scratch card | `GET /api/scratch/status` (auth) | `POST /api/scratch` (auth); display and wallet refresh use the response. |
| Quiz | `GET /api/quiz` (public) | `POST /api/quiz/submit` (auth) with the user's selected answers; no default answer is sent for unanswered questions. |
| Withdrawals | `GET /api/withdrawals/methods`, `GET /api/withdrawals/my` (auth) | `POST /api/withdrawals/request` (auth); server validates method, amount, and account details. |
| Gift cards | `GET /api/giftcards` (public) | `POST /api/giftcards/redeem/:id` (auth); show code/PIN only after server confirms redemption. |
| Referrals and leaderboard | `GET /api/referrals/info`; `GET /api/leaderboard/:period` (auth) | Read-only display of server-returned statistics. |
| Notifications | `GET /api/notifications` (auth) | `PATCH /api/notifications/:id/read` or `/read-all` (auth). |

## Loading, empty, and failure UX

Screens should start with a loading state, then show only API-provided data. A legitimate empty response uses an empty state; a network/invalid response uses an error state with retry where implemented. Missing reward or balance fields are shown as unavailable—not as `0` or an estimated rupee value. A missing server feature, such as missions without a verified endpoint, must not be represented as a completed offer or guaranteed reward.

## Release and verification status

This guide describes the frontend request flow and the changes proposed for review. It is **not a claim of Play Store or production readiness**: Flutter SDK/analyzer/build and signed AAB are not available in this work environment, and authenticated end-to-end tests still need a real user session. Changes require review and a real Flutter build/test before release. This local snapshot does not include a PR, merge, Render deploy, Firestore migration, or balance change.