---
applyTo: "{**/re/**,**/reverse-engineering/**,**/binary-analysis/**,**/samples/**,**/*.ghidra,**/*.idb}"
---
# Reverse Engineering Overlay Instructions

These rules are an optional overlay for authorized binary, firmware, and protocol analysis. They are additive to `.github/instructions/core.instructions.md` and `.github/instructions/security.instructions.md`.

## Authorization And Scope
- Confirm written authorization, the analysis scope, and the legal or ethical boundaries before touching a sample.
- Do not bypass licenses, DRM, or access controls, and do not analyze malware outside an authorized scope.
- Record what is in scope, what is out of scope, and who authorized the work.

## Evidence And Preservation
- Hash the original and analyze copies only. Never modify the original sample.
- Record the tool, version, command, and artifact for every finding.
- Keep confirmed facts separate from inference, and state confidence explicitly.
- Sanitize samples, captures, and logs before sharing.

## Isolation
- Run dynamic analysis in an isolated sandbox or VM with no production network.
- Snapshot before execution and roll back after.
- Do not exfiltrate secrets or run live attacks from the analysis environment.

## Analysis Discipline
- Start with file type, architecture, sections, imports, strings, entropy, and packer or anti-analysis indicators.
- Use static analysis to form hypotheses; use dynamic analysis to confirm or reject them.
- Reproduce important findings and point to the exact artifact or address.
- Do not trust a decompiler blindly; verify critical control flow and data flow.

## Stop Conditions
- Stop on legal or ethical ambiguity.
- Stop when a sample could affect production or third-party systems.
- Stop before executing unknown code outside the isolated environment.
