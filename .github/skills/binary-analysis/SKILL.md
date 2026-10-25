---
name: binary-analysis
description: Triage and analyze binaries or firmware for authorized reverse engineering, interoperability, vulnerability research, or malware analysis with isolation and evidence discipline.
---
# Skill: binary-analysis

## When to Use
Use this skill for authorized static or dynamic analysis of an unknown binary, firmware image, crash dump, protocol implementation, or malware sample.

## Trigger Examples
- "Triage this firmware image and identify the architecture, boot chain, and interesting strings."
- "Reverse engineer this protocol so we can build an interoperable client."
- "Analyze this crash dump and identify the failing function."
- "Determine whether this sample is packed and what it tries to contact."

## Checklist
- Confirm written authorization, scope, and legal or ethical boundaries before touching the sample.
- Record hashes, file type, architecture, endianness, strings, imports, sections, entropy, and packer or anti-analysis indicators.
- Preserve the original; analyze copies only. Keep an evidence chain for every finding.
- Static analysis: disassemble or decompile, map control flow, identify crypto constants, network indicators, and configuration.
- Dynamic analysis: use an isolated sandbox or VM, no production network, snapshot and rollback, and capture process, file, registry, and network behavior.
- Reproduce important findings and separate confirmed facts from inferences.
- Record the tool, version, command, and artifact for each result.
- Sanitize samples, captures, and logs before sharing.

## Safety Boundaries
- Do not execute untrusted binaries outside an isolated sandbox.
- Do not bypass licenses, DRM, or access controls, and do not analyze malware outside an authorized scope.
- Do not exfiltrate secrets or run live attacks from the analysis environment.
- Stop on legal or ethical ambiguity, or when the sample could affect production or third-party systems.

## Output Format (Strict)
1. Sample identity
- Hash, type, architecture, size, and provenance.

2. Scope and authorization
- What is authorized, what is out of scope, and the isolation used.

3. Static findings
- Structure, imports, strings, control flow, crypto, and indicators.

4. Dynamic findings
- Observed behavior, network or file activity, and reproduction steps.

5. Hypotheses and confidence
- Confirmed facts versus inference, with the evidence for each.

6. Risk and next steps
- Residual uncertainty, containment needs, and the next discriminating analysis.

7. Handoff
- Recommended next agent, inputs, decision status, and blockers or approvals needed.
