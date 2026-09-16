# Security Policy

## Scope

Reports must be demonstrated against the **released application** — the build
distributed through the App Store — or against the backend endpoints it talks
to. The source published here is context for research, not the target of it.

Specifically **out of scope**:

- Findings derived from reading this source alone, without a demonstration
  against the released application. This mirror has configuration stripped and
  replaced with placeholders, tests and CI removed, and some dependencies
  omitted; a `PLACEHOLDER_*` value is not a hardcoded secret, and code paths
  that appear unreachable here may not be.
- Anything requiring a build of this repository. It is not intended to build.
- Issues in third-party dependencies, which should go to their maintainers.

## Supported versions

Only the **latest published state** of this repository, corresponding to the
current release of the application, is in scope. Earlier snapshots are not
supported.

## Known limitations

Some issues are already known and tracked internally. A report matching one of
them may be closed as a duplicate without detail.

## Reporting

Report findings through our bug bounty program on HackerOne:
https://hackerone.com/common_codes. Do not report vulnerabilities via GitHub
issues.

## Safe harbour

Security research conducted in good faith and in accordance with this policy
and the applicable rules of the bug bounty program
(https://hackerone.com/common_codes) will not lead to legal action from us. Stay
within scope, do not access or modify data belonging to other people, and
maintain the confidentiality of vulnerability information and affected data.
Vulnerability details may be disclosed only after we have confirmed that the
vulnerability has been remediated.

## Upstream dependencies

This application depends on public upstream libraries, including the AusweisApp2
SDK and the EU reference wallet libraries. Vulnerabilities in those belong to
their respective maintainers.
