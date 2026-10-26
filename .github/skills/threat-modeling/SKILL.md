---
name: threat-modeling
description: Build a lightweight design-time threat model that names assets, trust boundaries, attackers, and mitigations before implementation.
---
# Skill: threat-modeling

## When to Use
Use this skill at design time for a new feature, endpoint, integration, identity flow, data store, or any change that moves a trust boundary.

## Trigger Examples
- "Threat model this file upload feature before we build it."
- "What can go wrong if we add SSO here?"
- "Review this integration for abuse cases."
- "Model the trust boundaries for this multi-tenant API."

## Checklist
- Name the assets: data, capabilities, money, identity, availability, and reputation.
- Draw the trust boundaries: browser, service, queue, database, third party, and operator access.
- Enumerate entry points and who can reach them, including unauthenticated paths.
- Apply STRIDE per boundary: spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege.
- Identify abuse cases, not only technical attacks: enumeration, scraping, replay, resource exhaustion, and insider misuse.
- Map existing controls and find the gap for each credible threat.
- Prefer deny-by-default, least privilege, server-side enforcement, and validation at the boundary.
- Record accepted risks explicitly with an owner; do not leave them implicit.
- Re-check the model when the design changes or a new trust boundary appears.

## Safety Boundaries
- Do not claim a control exists without pointing at code or configuration that implements it.
- Do not treat authentication as authorization.
- Do not propose security theater or controls that the runtime cannot enforce.
- Stop and ask before accepting a high-severity risk, introducing a new external trust boundary, or weakening an existing control.

## Output Format (Strict)
1. Scope and assets
- What is being modeled and what is worth protecting.

2. Trust boundaries and entry points
- Each boundary, who crosses it, and how.

3. Threats
- Ordered table: `Threat | STRIDE | Boundary | Existing control | Gap`.

4. Mitigations
- The smallest controls that close the credible gaps, with where they belong.

5. Accepted risks
- Residual risk, owner, and review date.

6. Handoff
- Recommended next agent, inputs, decision status, and approvals needed.
