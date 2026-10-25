---
name: network-troubleshooting
description: Diagnose connectivity, latency, throughput, DNS, TLS, routing, firewall, and packet-loss problems with packet-level evidence and read-only-first safety.
---
# Skill: network-troubleshooting

## When to Use
Use this skill when connectivity, latency, throughput, DNS, TLS, routing, firewall, NAT, load-balancer, or packet-loss behavior is failing or unexplained.

## Trigger Examples
- "Users intermittently time out against this endpoint; find the failing layer."
- "DNS resolves but TLS fails only from one network."
- "Throughput collapses after the load balancer."
- "Capture and explain the packet loss between client and server."

## Checklist
- Define the expected path and behavior: client, DNS, proxy, load balancer, firewall, NAT, server, and dependency.
- Identify the failing layer from L1 through L7 before changing anything.
- Capture at the closest points available. Record interface, filter, timestamps, and capture point.
- Check DNS resolution, TCP handshake, TLS handshake, HTTP status, retransmits, RTT, MTU, and connection reuse.
- Compare working and failing paths; isolate the first divergent packet or configuration.
- Check firewall and security-group rules, routes, proxy settings, certificate chain, and clock skew.
- Prefer read-only diagnostics first: captures, `dig`, `curl -v`, `traceroute`, `ss` or `netstat`, and logs.
- Sanitize captures and logs before sharing; redact addresses, credentials, and payloads.

## Safety Boundaries
- Do not capture or expose sensitive traffic without authorization; sanitize every artifact.
- Do not run scans or probing against systems you do not own or have permission to test.
- Do not make production routing, firewall, or DNS changes without explicit approval.
- Stop before disruptive actions such as route changes, interface resets, or traffic shaping.

## Output Format (Strict)
1. Path and symptom
- Expected path, observed path, and the smallest reproduction.

2. Evidence
- Capture points, filters, commands, timestamps, and sanitized artifacts.

3. Layer analysis
- What each layer shows and the first divergent point.

4. Root cause or leading hypothesis
- Confirmed facts versus inference.

5. Fix or next experiment
- The smallest safe change or the next discriminating capture.

6. Residual risk
- Encrypted or missing traffic, intermittent behavior, and untested paths.

7. Handoff
- Recommended next agent, inputs, decision status, and blockers or approvals needed.
