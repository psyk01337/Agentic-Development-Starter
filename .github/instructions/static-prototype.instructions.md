---
applyTo: "{**/*.html,**/*.htm,netlify.toml}"
---
# Static Prototype Overlay Instructions (Throwaway Presentation Prototypes)

These rules are an optional overlay for repositories (or isolated folders within a repo) that build throwaway, presentation-only web prototypes with plain HTML, Bootstrap, HTMX, and vanilla JavaScript/CSS. They are not the baseline for every repo and are not a substitute for the frontend overlay when production UI work is involved.

Enable only for fast mock interactivity and demo flows. Keep prototypes isolated from production code.

## Stack Boundaries
- Use only static assets: `.html`, `.css`, `.js`, static JSON, and images. No build step, no backend, no database, no real APIs.
- Styling: Bootstrap 5.x. Interactivity: HTMX 2.x plus small vanilla JS modules. Do not introduce React, Vue, bundlers, or frameworks just for a mock.
- Prefer pinned CDN links or vendored copies. Never use versionless or floating CDN URLs. Verify the exact version exists in the official docs before pinning.
- No secrets, API keys, real credentials, or real user data in prototypes. All data is fake or seeded.

## Structure
- Keep each prototype self-contained: one folder with `index.html`, `styles.css`, `app.js`, and any `mock/*.json` fixtures.
- Name the folder after the flow being demoed (e.g. `prototypes/checkout-flow/`). Keep prototypes out of production source paths.
- Prefer inline or sibling scripts over shared infrastructure. Plain `.js`/`.css` files used only by prototype pages follow this overlay's rules.

## Mock Interactivity
- Use HTMX attributes (`hx-get`, `hx-post`, `hx-target`, `hx-swap`, `hx-trigger`) for partial page updates against static JSON or JS-stubbed "endpoints".
- Fake endpoints with static JSON files or small JS service functions that return mock data; keep latency and loading states visible with `hx-indicator`.
- Persist fake session state in `localStorage`; do not invent a backend to store it.
- Give every interactive flow clear `loading`, `empty`, `error`, and `success` states so demos never dead-end.

## Visual Quality and Layout Discipline
- Spacing: use Bootstrap spacing utilities (`p-*`, `m-*`, `gap-*`, `g-*`) on the 0-5 + auto scale. No magic-number custom margins or padding; keep rhythm on the default spacer scale.
- Layout: structure with `container` > `row` > `col-*`. No absolute positioning, floats, or fixed pixel widths for page structure.
- Alignment: one alignment rule per block. Do not mix `text-center` and `text-start` in sibling elements; use flex `align-items`/`justify-content` consistently; keep gutters and container widths identical across steps of the same flow.
- Type hierarchy: use the Bootstrap heading scale (`h1`-`h6`, `fs-*`, `fw-*`) and consistent vertical rhythm (`mb-*`) under headings. One font; Bootstrap defaults.
- Color and contrast: use theme variables and `.text-*`/`.bg-*` utilities. Keep text contrast at or above 4.5:1; no ad-hoc inline colors.
- Components first: use Bootstrap navbar, cards, buttons, modals, and form controls instead of hand-built widgets. Reuse the same card/button patterns across screens.
- Images and icons: `img-fluid`, fixed aspect ratios, one icon set per prototype.
- Visual lint before finishing: verify spacing is on-grid, alignment is consistent, no horizontal overflow, the layout holds at mobile width, and `loading`/`empty`/`error`/`success` states are all visible.

## Bootstrap CSS Usage
- Utility-first: express spacing, sizing, and layout with Bootstrap utilities before writing any custom CSS.
- Custom CSS boundary: custom rules live only in `styles.css` and only for what utilities cannot express. No `!important`; no overriding Bootstrap internals.
- Theming: customize via CSS variables in `:root` (`--bs-primary`, `--bs-border-radius`, etc.) instead of editing library files or inline styles.
- Breakpoints: mobile-first using `sm/md/lg/xl/xxl`; verify each page at every breakpoint it uses.
- Forms and feedback: use `form-control`, `form-label`, `form-select`, `is-invalid`, and `invalid-feedback` instead of styled bare inputs.
- JS components: modals, toasts, and dropdowns via `bootstrap.bundle.min.js`; no hand-rolled equivalents.
- Icons: use the pinned Bootstrap Icons CDN and size them with `fs-*` utilities.

## Presentation and Accessibility
- Use Bootstrap's responsive grid and components; keep one visual language per prototype.
- Keep semantics, labels, keyboard flow, and visible focus states intact even in throwaway code.
- Keep pages standalone-openable (file:// or a static server) so demos work offline.

## Deployment (Netlify or any static host)
- Static-only deploys: a publish directory of plain files, no build command.
- Provide a minimal `netlify.toml` with `[build] publish = "."` (or `"public"`) and no build command, or use drag-and-drop deploys.
- No environment variables, functions, or server-side features. Forms, if shown, are mocked and must not submit real data anywhere.

## Boundaries and Precedence
- Prototypes are throwaway by intent; do not let prototype patterns (inline styles, mock endpoints, localStorage hacks) leak into production code.
- If the frontend, React, or Next.js overlays are also enabled in the same repo, this overlay takes precedence inside the prototype folder and applies only there.

## Official References
- HTMX: https://htmx.org/docs/
- Bootstrap: https://getbootstrap.com/docs/5.3/getting-started/introduction/
- Netlify static deploys: https://docs.netlify.com/site-deploys/overview/
