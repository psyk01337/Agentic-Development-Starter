---
applyTo: "{**/net/**,**/network/**,**/networking/**,**/*.pcap,**/*.pcapng,**/wireshark/**,**/cisco/**,**/juniper/**}"
---
# Networking Overlay Instructions

These rules are an optional overlay for network configuration, packet analysis, and connectivity troubleshooting. They are additive to `.github/instructions/core.instructions.md` and `.github/instructions/security.instructions.md`.

## Define The Path First
- State the expected path: client, DNS, proxy, load balancer, firewall, NAT, server, and dependency.
- Identify the first failing layer from L1 through L7 before changing configuration.
- Compare a working path with the failing path wherever possible.

## Capture Discipline
- Capture at the closest available points on both sides. Record the interface, filter, timestamps, and capture location.
- Prefer read-only diagnostics first: captures, `dig`, `curl -v`, `traceroute`, `ss` or `netstat`, and logs.
- Sanitize captures and logs before sharing; redact addresses, credentials, and payloads.
- Do not capture or expose sensitive traffic without authorization.

## Checks That Matter
- DNS resolution, TCP handshake, TLS handshake, HTTP status, retransmits, RTT, MTU, and connection reuse.
- Firewall and security-group rules, routes, proxy settings, certificate chain, and clock skew.
- Intermittent failures: correlate timestamps across client, load balancer, and server before blaming a layer.

## Safety
- Do not run scans or probing against systems you do not own or have permission to test.
- Do not make production routing, firewall, DNS, or traffic-shaping changes without explicit approval.
- Stop before disruptive actions such as route changes, interface resets, or traffic shaping.

## Evidence
- Point to sanitized packet captures, command output, timestamps, and correlated logs instead of pasting raw traffic.
