---
name: web-quality
description: Audit and improve web accessibility, Core Web Vitals, responsiveness, forms, metadata, and browser compatibility with measured before-and-after evidence.
---
# Skill: web-quality

## When to Use
Use this skill when a web page or UI change needs an accessibility, performance, responsiveness, forms, SEO, or browser-compatibility audit.

## Trigger Examples
- "Audit this checkout page for accessibility and Core Web Vitals."
- "The page is slow on mobile; find the measured bottleneck before changing code."
- "Check keyboard navigation, focus, and screen-reader behavior for this dialog."
- "Improve the responsive behavior and form error handling."

## Checklist
- Accessibility: semantic HTML, keyboard path, focus management, accessible names, ARIA only when needed, contrast, reduced motion, and screen-reader announcements.
- Performance: measure LCP, INP, and CLS; inspect bundle size, images, fonts, caching, lazy loading, and third-party scripts.
- Responsiveness: breakpoints, touch targets, overflow, zoom, mobile viewport, and long or translated content.
- Forms: labels, inline validation, error association, autocomplete, submission state, and secure handling.
- Metadata: title, description, canonical, structured data, robots, and share previews.
- Compatibility: test the browsers and devices the project actually supports.
- Record before-and-after evidence from Lighthouse, axe, browser devtools, or real-device tests.

## Safety Boundaries
- Do not introduce dark patterns, inaccessible traps, or deceptive UI.
- Do not expose secrets, tokens, or internal data in client bundles or error states.
- Stop on security or privacy issues that require a different owner; do not paper over them with UI changes.

## Output Format (Strict)
1. Scope
- Page, flow, browsers, devices, and the quality dimensions audited.

2. Findings
- Severity-ordered findings with the affected element or route.

3. Fixes
- The smallest safe fixes, with accessibility and performance tradeoffs.

4. Evidence
- Before-and-after measurements, screenshots, and command or tool outputs.

5. Residual risk
- Lab versus field performance, unsupported browsers, and untested assistive technology.

6. Handoff
- Recommended next agent, inputs, decision status, and blockers or approvals needed.
