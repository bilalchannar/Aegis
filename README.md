# Aegis

Aegis is a Flutter personal-safety app that helps people pause and assess suspicious messages, links, and screenshots. It combines on-device detection rules with optional AI analysis, and presents evidence and practical next steps in a calm, privacy-conscious interface.

> Aegis provides an automated assessment, not proof that content is safe or malicious. Risk scores are heuristic indicators, not calibrated probabilities.

## Features

- **Text and link checks:** inspect content with deterministic, on-device rules or choose the AI analysis mode when configured and entitled.
- **Screenshot checks:** select an image for supported AI vision analysis. The Free plan keeps the image local and reports the current local OCR limitation.
- **Evidence-based reports:** review risk indicators, evidence, recommendations, and known analysis limitations.
- **Safety resources:** browse scam patterns and guides, take a quiz, manage a trusted circle, and use recovery checklists.
- **Personal dashboard and history:** review saved assessments and analytics. Saving scan history is optional and local to the device.
- **PDF reports:** export or share reports generated from an actual scan, with plan-based usage limits.
- **Subscription preview:** compare Free, Pro, and Ultra. In debug builds, the owner panel can switch test entitlements without creating a store purchase.

## Plans and limits

| Plan | AI requests | PDF exports | Access |
| --- | ---: | ---: | --- |
| Free | 0 per local calendar day | 2 per calendar month | Rules-based text and link checks, basic resources, limited history, local screenshot guidance |
| Pro | 10 successful requests per local calendar day | 10 per calendar month | AI text, link and supported screenshot analysis; full pattern library, advanced dashboard and quiz, custom rules, extended history, advanced PDF options |
| Ultra | No Aegis app-imposed quota | No Aegis app-imposed quota | Pro features and unlimited locally saved history |

Daily AI usage resets at local midnight. PDF usage resets at the start of the next local calendar month. Failed AI requests and canceled or failed PDF exports do not consume usage. Ultra remains subject to external provider availability, rate limits, and costs.

## Run locally

Install Flutter and the platform tools for your target device, then run:

```sh
flutter pub get
flutter run
```

To run in Chrome:

```sh
flutter run -d chrome
```

On the subscription page, debug builds show **Owner Testing · Debug Only**. Use **Test Free**, **Test Pro**, and **Test Ultra** to switch the in-memory test plan, inspect unlocked and locked features, and reset local test usage. This panel is compiled out of release builds and does not grant a real store entitlement.

## Optional AI configuration

AI is optional; deterministic scanning works without provider configuration. For local development, copy the placeholder file and add your own provider credentials:

```powershell
Copy-Item config\example.json config\local.json
flutter run -d chrome --dart-define-from-file=config/local.json
```

`config/local.json` is ignored by Git. Never replace the placeholder values in `config/example.json` with real keys or commit a local configuration file.

Gemini is the primary configured provider. Groq can be configured as an optional fallback where supported. AI mode sends the selected scan content or image to the configured provider; rules mode stays on-device. Review sensitive content before choosing AI analysis.

**Client-side keys are not secret.** Build-time values can be extracted from a distributed app, may incur charges, and may be abused. This repository has no server-side AI proxy or secret management. Do not ship shared provider keys in a public release; use an authenticated backend with quotas and provider-side restrictions for production AI.

## Store setup and purchase limitations

Store products must be created and configured in the supported Android store listing. Supply the actual Pro and Ultra product identifiers at build time:

```sh
flutter run \
  --dart-define=AEGIS_PRO_PRODUCT_ID=your_pro_product_id \
  --dart-define=AEGIS_ULTRA_PRODUCT_ID=your_ultra_product_id
```

The app displays prices returned by the store and does not invent prices. The repository does not include configured store products or a purchase-verification backend. Store purchase state is handled on-device, so production subscriptions still need server-side receipt validation and renewal/revocation handling. Web builds provide plan comparison and debug owner testing but cannot process store purchases.

## Privacy and data

- Rules-based text and link scans run locally.
- Scan history is saved locally only when the user enables it.
- AI mode sends the selected content or image to the configured external provider.
- Local preferences and usage counters are stored on the device; they are not synced to an account or backend.
- A local account preview is not a cloud authentication service.

## Project layout

```text
lib/
  app_state.dart             Local app preferences and saved data
  features/                  Scanner, profile, dashboard, and safety screens
  models/                    Scan and report models
  services/                  Detection, AI, usage, purchases, PDF, and analytics
  ui/                        Shared visual components and subscription screen
test/                        Scanner, service, quota, and widget tests
docs/                        Design and research notes
```

## Validate and build

```sh
flutter analyze
flutter test --concurrency=1
flutter build web --release
```

The PDF generator currently uses built-in fonts; some non-Latin characters may not render correctly in exported reports. Store billing and real provider calls require external configuration and are not covered by the local test suite.

## License

No license is currently specified. All rights are reserved unless the repository owner adds a license.
