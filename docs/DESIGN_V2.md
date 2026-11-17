# Aegis v2 — design handoff

## Scope decision

On 15 October 2026, the user clarified: “on later you make design only.” This version implements the visual experience and device-local interactions. Live Firebase, Unity, sign-in providers, billing and notifications are intentionally deferred. Existing Firebase projects were listed read-only before this clarification; no project was modified or selected.

## Design system

Forest green, warm white and fresh lime accents create a more distinctive consumer identity. Depth comes from translucent navigation, restrained gradients, custom shield art and soft surface separation. Typography uses the platform system face. Transitions, entrance reveals, segmented controls, checklist progress and selected-plan changes animate; no endless animation blocks interaction tests. The main entrance reveal respects the system reduced-motion setting.

Navigation: Home / History / central Check / Learn / Profile. Bottom padding keeps scrollable content above the glass navigation and device safe area. Important recovery and result screens have no ad placement.

## Screen map

- Three onboarding steps, skip and optional create-account entry
- Home: check hero, content shortcuts, safety tools, recent checks, education and banner placeholder
- Check: message, link and screenshot modes; validation, loading, error, and explicitly unavailable-analysis states
- Clarity card: verdict, evidence, trusted-circle action, recovery action, original content
- History: search, verdict filters, empty state, result detail
- Learn: editorial guides, interactive practice, quiz feedback and completion
- Trusted circle: add, copy and remove local contacts; no messages or invitations
- Before you pay: three independent-verification prompts
- Recovery: three scenarios, persistent checklist progress and completion state
- Profile: local name, guest state, optional authentication entry, Plus, preferences and privacy
- Authentication: signup/signin switch, email/name/password validation, show password, forgot password, Apple and Google preview actions, continue as guest
- Plus: monthly/yearly selection, feature comparison, proposed price, purchase/restore explanatory sheets
- Preferences: working dark appearance, language availability sheet, notification preferences, optional saved history and clear-history confirmation
- Privacy centre: actual preview data handling
- Notifications: honest empty state and settings entry

## Distinctive value

The app helps users act after noticing a warning sign: verify with a real trusted person, pause before a payment, or organize recovery steps. The quiz teaches habits rather than claiming perfect detection. These features are product differentiation ideas; no claim is made that competitors lack all of them.

The recovery guidance is adapted from [FTC: What to do if you were scammed](https://consumer.ftc.gov/articles/what-do-if-you-were-scammed). The trusted-circle verification pattern follows [FTC family emergency guidance](https://consumer.ftc.gov/articles/scammers-use-fake-emergencies-steal-your-money). Country-specific reporting and legal routes must be researched during localization.

## Local behavior and limitations

Local text and URL checks use a small, explicit ruleset and produce schema-versioned audit reports with evidence, recommendations, risk scores, and limitations. These checks make no network requests; there are no live reputation, domain-age, TLS or phone-number queries. No-match checks remain inconclusive. Screenshot selection displays a local preview and returns an unavailable-analysis report until a vision provider is configured; configured screenshot analysis sends the selected image to that provider. Authentication and payment actions do not create real accounts or entitlements.

Notification toggles save preferences only. No OS permission is requested and no notification is scheduled. Profile, contacts and recovery progress use local preferences. Saved scan history is opt-in; local preferences are not an encrypted vault. Clearing checks does not remove contacts or preferences. Contacts can be removed individually.

## Future integration

1. Pick/register final app identifiers and a Firebase project. Add platform configuration through FlutterFire.
2. Use Firebase Authentication with email/password, Apple and Google; implement reset, verification, account linking/deletion and guest upgrade. Enable providers and configure Apple capabilities/OAuth redirect schemes before claiming login works.
3. Manage Gemini on the backend. If using a Cloud Function, keep the developer key in Secret Manager and rotate it there. Never put secrets in Remote Config. Remote Config can select model, quotas and feature flags. Alternatively use Firebase AI Logic with App Check.
4. Add rate limits, App Check, validated structured responses, timeout/retry and a clear content-transfer consent flow.
5. Configure Unity LevelPlay app keys/ad-unit IDs and Unity Ads mediation adapter. The design reserves a home-screen banner placement away from scan/results/recovery/navigation. Add appropriate consent and privacy declarations before loading ads; remove ads only for verified paid entitlements.
6. Configure App Store/Play subscription products. Suggested design prices are USD $3.99/month and $29.99/year (about $2.50/month, 37% lower than twelve monthly payments). These are proposals, not loaded store prices. Final offers must come from store product data; verify receipts server-side, handle restore/cancel/expiry and disclose renewal terms.
7. Connect notification permission, tokens and delivery to the saved user preferences. Localization is a separate phase; do not pretend an unimplemented language is active.

References: [Firebase federated authentication](https://firebase.google.com/docs/auth/flutter/federated-auth), [Firebase function secrets](https://firebase.google.com/docs/functions/config-env), [Unity Flutter banner integration](https://docs.unity.com/en-us/grow/levelplay/sdk/flutter/banner-integration).
