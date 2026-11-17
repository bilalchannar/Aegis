# Aegis — original product research and implementation brief

**Version note:** This describes the first MVP. The current design-only v2 removes user-facing Gemini key entry and defers live services. See [current handoff](DESIGN_V2.md) for actual behavior.

Research date: 15 October 2026. Store listings and feature availability vary by country. Marketing claims below are vendor claims, not independent accuracy benchmarks.

## Competitive review

| Product | Evidence reviewed | Product lesson |
| --- | --- | --- |
| Trend Micro ScamCheck | [Google Play listing](https://play.google.com/store/apps/details?hl=en-US&id=com.trendmicro.fraudbuster), screenshot gallery and red/white promotional presentation | Multiple protection modules can overwhelm the first screen. Prioritise a single check action and separate message, link and image entry points. Listing advertises calls, SMS, websites and fake video call detection; these require substantially different engineering. |
| Norton 360 Mobile Scam Security | [Apple App Store](https://apps.apple.com/ca/app/norton360-mobile-scam-security/id1278474169), visible iPhone promotional screenshots | Strong brand colour, readable protection overview, broad subscription suite. Availability depends on country/plan. Avoid promising the same background protection in an initial checker. |
| Bitdefender Scamio | [Official website](https://www.bitdefender.com/en-us/consumer/scamio) | Conversational explanation and low-friction content submission. Differentiate with a quieter, structured mobile result and concrete next actions. |

These references informed interaction patterns only. Aegis uses original artwork, brand and layouts. The large gallery modal on Play did not fully load during inspection; the store's visible thumbnail screenshots were reviewed. No competitor UI is copied.

## Positioning and visual system

A calm second opinion before replying, paying or sharing private information. Warm ivory background, forest/teal text, sage surfaces, restrained terracotta warnings, bespoke shield illustration, rounded floating glass navigation. No fake scans, invented protection statistics, fake community reports, or simulated subscription purchases.

Primary journey: onboarding → home → select content type → paste/upload → local assessment or consented Gemini analysis → warning signs and verification steps → history.

The implemented Flutter application includes three onboarding pages, dashboard, message/link entry, screenshot picker and Gemini vision input, structured verdicts, session history, optional device-local persistence, searchable history, educational field guide and session-only API settings. A custom logo is supplied as SVG and platform app icons. The UI uses Cupertino icons and iOS-like interactions; it is Flutter, not a native SwiftUI application.

## Accuracy boundaries

Local checks detect a small explicit set of urgency, secret-code requests, reward, unusual link and advance-fee patterns. They are not a calibrated classifier. No matches remain inconclusive (Suspicious), rather than asserting Safe. Gemini analysis is a content assessment, not an independent reputation service. Safe is rendered as “No obvious threats found”. No probability or confidence percentage is invented.

Neither mode currently performs live blocklist queries, domain age, TLS inspection, URL expansion, phone reputation or automatic browsing. Never claim those checks occurred. Malicious links are never fetched by the client. An eventual URL service must defend against SSRF, private IPs, redirects, IDN confusion, DNS rebinding and resource exhaustion.

Screenshot checks currently use Gemini vision after consent. On-device OCR, number lookup, share extensions, reporting/moderation, payment, family plans, automatic call/SMS/DNS protection and localisation are future work.

## Platform requirements

- [Apple IdentityLookup](https://developer.apple.com/documentation/identitylookup/sms-and-mms-message-filtering): filtering applies to unknown-sender SMS/MMS, not arbitrary iMessages or every message. A dedicated extension is needed; networking is mediated by the system.
- [Google Play SMS/Call Log policy](https://support.google.com/googleplay/android-developer/answer/10208820?hl=en): sensitive permissions are restricted and require eligibility and declarations. Do not request inbox access for the paste/upload MVP.
- iOS share sheet intake needs a Share Extension target, configured app groups and safe handoff; Android needs a share intent receiver. Neither is currently advertised as working in the app.
- Camera access is unnecessary for the current gallery-only picker. Only user-selected images should be processed.

## Gemini and Firebase

[Gemini generateContent API](https://ai.google.dev/api/generate-content) supports multimodal parts. The app uses JSON responses and validates the verdict, summary and reasons before rendering. Network errors remain errors, never a fake successful assessment. The model is configurable because availability changes. During this session Google rejected gemini-2.5-flash for new users and recommended gemini-3.8-flash; the default was updated. A test of the latter returned HTTP 503 high demand; a later retry timed out. Successful live AI analysis has not yet been verified.

For this BYOK prototype, the user's key is held in app memory only and is not embedded in code, saved preferences or history. Each AI submission discloses that selected content goes to Google. Google retention/training terms depend on the user's API plan. Optional local history uses device preferences and is not an encrypted vault. Disable it for sensitive content.

Firebase is not necessary for the local checker. For public launch use [Firebase AI Logic](https://firebase.google.com/docs/ai-logic) and [App Check](https://firebase.google.com/docs/ai-logic/app-check), or a server proxy with server-managed credentials, quotas and abuse controls. Do not ship a shared developer Gemini key inside the app.

Suggested later backend:

| Collection | Contents and access |
| --- | --- |
| users/{uid} | Optional profile, locale and explicit preferences; owner access only |
| reports/{id} | Normalised indicator/hash, category, evidence consent, reporter UID, moderation status; rate-limited submission endpoint |
| indicators/{hash} | Human-reviewed aggregate reputation, evidence count, review timestamp and expiry; writes restricted to service/moderators |
| alerts/{id} | Editorial notices by locale, source references and expiry; moderator writes only |

Store submitted content only when necessary and consented. Reports must not immediately become blocking verdicts. Add moderation, deduplication, appeals, deletion and retention limits. Keep subscription entitlements verified server-side.

## Before a public release

1. Register the final product name, bundle IDs and signing identities; Aegis is a working name, not a trademark clearance.
2. Configure a Firebase project only once a project owner, region and billing policy are chosen.
3. Integrate and license a real threat intelligence provider. Verify current commercial usage terms; don't assume a free consumer API permits commercial use.
4. Evaluate representative labelled scams and benign samples, including Urdu/Roman Urdu, English, bank/courier impersonation, benign OTP notifications and unreadable images. Measure false positives and false negatives by content type/language.
5. Complete native screenshot/picker tests, accessibility and large text checks, actual iOS/Android release builds and store review requirements.
6. Publish an accurate privacy policy, support contact, consent disclosures and deletion route. Add StoreKit/Play Billing only if subscriptions are actually offered.
7. Run a limited beta with clear limitations before enabling community or background protection.

No provider pricing or performance guarantee is assumed. Budget must be measured from real model usage, image size, caching, quotas and chosen provider plans.

## Detection taxonomy and source rationale

The deterministic rules are warning-sign detectors, not a verdict that a sender or
domain is malicious. They combine context and requested action where possible,
retain matched evidence, and leave clean or ambiguous input inconclusive.

| Category | Rationale from guidance | Implemented treatment |
| --- | --- | --- |
| Credentials and account takeover | Phishing commonly seeks passwords, one-time codes, recovery information, or approval of an unexpected sign-in. | Detects secret-code disclosure, MFA/security-control changes, and suspicious account actions; preventive warnings are excluded when the warning context is local to the match. |
| Urgency, authority, and secrecy | Pressure, threats, authority claims, and secrecy reduce independent verification. | Urgency alone is medium evidence and does not create a dangerous verdict; it is stronger when combined with a request. |
| Money, rewards, and impersonation | Unexpected payments, fees, prizes, refunds, and trusted-brand impersonation are recurring social-engineering patterns. | Requires an action/request for payment and rewards where practical, and records organisation-plus-action combinations. |
| Links and downloads | Suspicious links, QR codes, attachments, downloads, redirects, credentials in URLs, and unusual destinations warrant caution. | Parses URLs without opening them and reports structural indicators separately from optional reputation checks. |

Primary guidance and technical references:

- [CISA: Recognize and Report Phishing](https://www.cisa.gov/topics/cyber-threats-and-advisories/recognize-and-report-phishing) — credential requests, urgency, links, attachments, sender anomalies, and independent verification.
- [NIST: Phishing](https://www.nist.gov/itl/smallbusinesscyber/guidance-topic/phishing) — phishing as deceptive electronic communication intended to obtain information or induce unsafe actions.
- [UK NCSC: Phishing](https://www.ncsc.gov.uk/collection/phishing-scams) — suspicious links, urgency, requests for credentials, authority/emotion, QR-code caution, and avoiding replies/clicks.
- [Google Web Risk: URI Lookup](https://cloud.google.com/web-risk/docs/lookup-api) — optional threat-list lookup for categories such as malware and social engineering; no match is not proof of safety.
- [Ma et al., Beyond Blacklists: Learning to Detect Malicious Web Sites](https://dl.acm.org/doi/10.1145/1315245.1315291) — lexical and host features can assist classification but do not replace behavioral or reputation context.
- [Le et al., URLNet](https://arxiv.org/abs/1802.03162) — URL lexical representations are useful but remain exposed to changing URLs and adversarial variation.

The URL heuristics therefore treat IP hosts, shorteners, encoded redirects,
Unicode/punycode, unusual ports, long paths, and executable downloads as
indicators only. They do not assert that HTTPS, an unfamiliar suffix, or a
successful reputation lookup proves safety. No URL is fetched, expanded, or
executed by the deterministic scanner.
