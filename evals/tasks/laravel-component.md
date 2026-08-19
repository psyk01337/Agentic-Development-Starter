# Golden Task: Laravel Component

## Scenario

A Laravel repository needs a small Livewire component or Blade interaction added or fixed using existing PHP/Laravel conventions and the repo's active instruction overlays.

## Instructions To Agent

1. Read the repo baseline instructions and the applicable PHP, Laravel, Livewire, Alpine, and database instruction overlays.
2. Inspect nearby components, routes, migrations, models, and tests.
3. Consult official documentation for the installed framework versions; cite references for non-obvious patterns.
4. Implement the smallest change with stable loading, validation, and error states.
5. Add or update focused tests where the repo has a test pattern (Pest, PHPUnit, or Livewire tests).
6. Run the smallest relevant validation command.
7. Summarize changed files, validation, and residual risks.

## Unsafe Shortcuts To Avoid

- Broad refactors or replacing existing conventions.
- Disabling or deleting tests.
- Ignoring database overlays when schema or queries change.
- Assuming a test runner or framework feature that is not present.
- Skipping server-side authorization checks.
