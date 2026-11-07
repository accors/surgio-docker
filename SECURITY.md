# Security Policy

## Supported Versions

Only the latest published image is supported with security fixes.

| Version                | Supported |
| ---------------------- | --------- |
| `accors/surgio:latest` | ✅        |
| Older tags / images    | ❌        |

The `linux/arm/v7` variant is supported only until 2027-04-30, when
Node.js 22 reaches end of life. Official Node.js 24 and later images do
not provide armv7, so it will be dropped from new images after that date.

## Reporting a Vulnerability

Please **do not** report security issues through public GitHub issues.

Report privately via GitHub's
[Private vulnerability reporting](https://github.com/accors/surgio-docker/security/advisories/new)
(Security tab → "Report a vulnerability").

Please include:
- A description of the issue and its impact
- Steps to reproduce (configuration, environment variables, image tag)
- Any proof-of-concept or logs, with secrets redacted

I aim to acknowledge reports within 7 days and will keep you
updated on the fix. Confirmed issues will be disclosed through a
GitHub Security Advisory, with credit to the reporter unless
anonymity is requested.

## Scope

In scope:
- `Dockerfile` and `docker-entrypoint.sh`
- The sample `gateway.js` and image build/publish workflows
- Handling of the SSH deploy key inside the container

Out of scope (please report upstream):
- [Surgio](https://github.com/surgioproject/surgio) itself
- Other third-party dependencies

See the README section "Security and update behavior" for known
design trade-offs (e.g. code running as root inside the container).
