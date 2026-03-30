---
applyTo: "**/*.{ts,tsx,js,jsx}"
---
# Next.js Overlay Instructions (React Fullstack)

These rules are an optional overlay for repositories that use Next.js.
They are additive to the general frontend and React overlays and should only be enabled where Next.js conventions are established.

## Routing and Boundaries
- Follow the repository's Next.js router style (App Router or Pages Router) consistently.
- Keep server-only and client-only concerns clearly separated.
- Use route-level loading and error handling patterns consistently.

## Data Fetching and Rendering
- Choose rendering strategy intentionally: static, dynamic, or incremental based on data volatility and UX needs.
- Avoid redundant client fetching when data can be resolved on the server boundary.
- Keep cache and revalidation behavior explicit for data-sensitive routes.

## Server and Client Components
- Use Server Components by default where the repo pattern supports it; opt into Client Components only when interaction requires it.
- Keep browser-only APIs out of server execution paths.
- Keep serialization boundaries explicit when passing data to client components.

## API Routes and Actions
- Validate all untrusted input at route or action boundaries.
- Keep endpoint/action contracts explicit and error responses consistent.
- Do not expose secrets or internal stack details in responses.

## Assets and Performance
- Use built-in Next.js asset and image optimization patterns adopted by the repo.
- Keep bundle impact in check; avoid large client-only dependencies without clear benefit.
- Prefer route-level code splitting and lazy loading for heavy UI surfaces.

## Testing
- Cover route behavior, data loading, and error states for changed flows.
- Verify that server/client boundaries remain correct after refactors.
- Use repository-standard test and e2e conventions.
