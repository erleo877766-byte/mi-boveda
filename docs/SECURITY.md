# Security Policy

Mi Bóveda is developed by **Leonardo Noel Salazar Mendoza**. We take the security and privacy of
our users seriously and welcome reports from security researchers.

> **Mi Bóveda is not affiliated with CAKE.com, Clockify, or security.cake.com.**
> Those services belong to unrelated companies. The only official vulnerability
> disclosure channels for Mi Bóveda are the ones listed on this page and at
> https://github.com/erleo877766-byte/mi-boveda/security.

## Reporting a vulnerability

**Please do not open a public issue, pull request, or social-media post for a
security vulnerability.** Public disclosure before a fix is available puts users'
funds and privacy at risk. Use one of the private channels below and we will
coordinate a fix and disclosure with you.

1. **GitHub private security advisory (preferred).**
   [Report a vulnerability](https://github.com/erleo877766-byte/mi-boveda/security/advisories/new).
   This gives you a private, structured thread with the maintainers and is the
   fastest way to reach us.
2. **Encrypted email.** Send details to **security@github.com/erleo877766-byte/mi-boveda**. For sensitive
   reports, please encrypt with our PGP key:
   - Key: https://github.com/erleo877766-byte/mi-boveda/.well-known/cakewallet-security.asc
   - Fingerprint: `DC91 6520 0271 AC6A 0533  3D3C BFE7 D9A5 0E4D 3A0A`

Both channels are monitored and automatically raise an alert in our internal
security channel, so reports will not be missed.

### What to include

- A clear description of the issue and its security impact.
- Step-by-step reproduction, ideally with a proof of concept.
- Affected platforms (iOS, Android, macOS, Linux, Windows) and app version.
- Affected wallet types / chains, if applicable.
- Any relevant logs, addresses, or transaction IDs (for on-chain issues).

If you used AI tooling to find or write up the report, please say so.

## Our commitment (safe harbor)

We consider security research conducted in good faith under this policy to be
authorized. We will not pursue or support legal action against researchers who:

- make a good-faith effort to avoid privacy violations, data destruction, and
  interruption or degradation of our services;
- only interact with accounts they own or have explicit permission to access; and
- give us a reasonable opportunity to fix an issue before disclosing it publicly.

If in doubt about whether an action is authorized, ask us first at
security@github.com/erleo877766-byte/mi-boveda.

## What to expect

- **Acknowledgement:** within **2 business days**.
- **Triage and initial assessment:** within **7 business days**.
- **Coordinated disclosure:** we aim to ship a fix and coordinate public
  disclosure within **90 days** of the report. We will keep you updated on
  progress and agree on a disclosure date with you.
- **Credit:** with your permission, we are happy to publicly credit you for the
  report once a fix is released.

## Scope

**In scope:** the Mi Bóveda and mi-boveda applications and the code in this
repository and its sibling `cake-tech` repositories â€” anything that could lead to
loss of funds, exposure of keys or seeds, a privacy leak, or a
failed/incorrect transaction.

**Out of scope:** issues in third-party services, exchange/swap providers, or
nodes we do not operate; reports generated solely by automated scanners without a
demonstrated impact; low-severity or informational issues on our marketing and
landing websites (for example reflected or self-XSS, missing security headers,
clickjacking on pages with no sensitive actions, or SPF/DMARC and cookie-flag
nitpicks) that do not affect the app or user funds; and social-engineering or
physical attacks.

## Rewards

At our **sole discretion**, we may offer a reward for a valid report. To be
eligible, a report must:

- be submitted **privately** through one of the channels above (a GitHub private
  security advisory or `security@github.com/erleo877766-byte/mi-boveda`) â€” anything disclosed publicly or
  sent through other channels is not eligible; and
- identify a genuine vulnerability with real impact on users â€” typically loss of
  funds, exposure of keys or seeds, a privacy leak, or a failed or incorrect
  transaction.

Trivial or low-impact findings are **not** eligible â€” for example, reflected XSS
or other low-severity issues on our marketing websites, missing security headers,
hardening or best-practice suggestions, automated-scanner output without a working
proof of concept, or already-known issues. There is no fixed bounty and no
guaranteed payout; whether a report qualifies, and any amount, are determined
solely by Leonardo Noel Salazar Mendoza.

## Supported versions

We do not maintain previous releases. Only the **latest release for each platform**
is supported; security fixes are delivered in new versions. Please keep Mi Bóveda
up to date.
