# Static Prototypes Runbook

Use this runbook when you need a throwaway, presentation-ready web prototype with plain HTML, CSS (Bootstrap), and HTMX, deployable to Netlify for demos and mock interactivity.

## When To Use

- Mock interactivity for stakeholder demos, design reviews, or sales pitches.
- Flows that must feel real but have no backend, data, or auth yet.
- Anything that must ship to a public URL in minutes without a build pipeline.

Do not use this approach for production features, real data, or code that must be maintained.

## Layout

```text
prototypes/<flow-name>/
  index.html
  styles.css
  app.js
  mock/
    users.json
    results.json
  netlify.toml
```

Keep one folder per demo flow. Plain files only; no package manager, no bundler.

## Dependencies

Pin exact versions from official CDNs. Verify each version in the official docs before pinning.

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://unpkg.com/htmx.org@2.0.4"></script>
```

Theme via CSS variables in `:root` instead of editing library files:

```css
:root {
  --bs-primary: #0d6efd;
  --bs-border-radius: 0.5rem;
}
```

Reference docs:

- Bootstrap: https://getbootstrap.com/docs/5.3/getting-started/introduction/
- HTMX: https://htmx.org/docs/
- Netlify deploys: https://docs.netlify.com/site-deploys/overview/

## Mock Interactivity Patterns

Fake endpoints as static JSON:

```json
{
  "results": [
    { "name": "Acme Co", "score": 92 },
    { "name": "Globex", "score": 81 }
  ]
}
```

Swap partial content with HTMX:

```html
<button hx-get="mock/results.json" hx-target="#results" hx-indicator="#spinner">
  Load results
</button>
<div id="spinner" class="spinner-border htmx-indicator" role="status"></div>
<div id="results"></div>
```

- Show `loading`, `empty`, `error`, and `success` states for every flow.
- Use `localStorage` for fake persistence across page loads.
- For multi-step flows, keep each step a separate page or a distinct HTMX swap target.

## Deploy To Netlify

Minimal `netlify.toml`:

```toml
[build]
  publish = "."
```

Then either drag-and-drop the folder at https://app.netlify.com/drop or run `netlify deploy --prod` after `netlify login`. No build command, no environment variables, no functions.

## Visual Check Before Demoing

- Spacing uses Bootstrap `p-*`/`m-*`/`gap-*` utilities on the standard scale; no one-off pixel values.
- Layout is `container` > `row` > `col-*` with no absolute positioning.
- Alignment is consistent within each section and across steps.
- Heading scale and vertical rhythm are consistent.
- Colors come from theme utilities; text contrast is readable (4.5:1 or better).
- Custom CSS stays in `styles.css`, uses `:root` variable overrides, and has no `!important`.
- Buttons, cards, and forms reuse the same Bootstrap patterns.
- No horizontal overflow; layout holds at 375px width.
- All four states (`loading`, `empty`, `error`, `success`) are reachable and visible.

## Boundaries

- No secrets, real credentials, real user data, or real third-party API keys.
- Forms are mocked; they must not POST anywhere real.
- Prototype code stays in the prototype folder and must not leak into production source paths.
- Once a flow is validated, rebuild it properly in the production stack rather than promoting prototype code.

## Related

- [Runbook Index](INDEX.md)
- [Starter Composition](starter-composition.md)
- [Static prototype instruction overlay](../../.github/instructions/static-prototype.instructions.md)
