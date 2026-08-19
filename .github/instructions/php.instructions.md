---
applyTo: "**/*.php"
---
# PHP Overlay Instructions (PHP 8+ General)

These rules are an optional overlay for repositories that use PHP 8 or later. They are not the baseline for every repo using this starter.

Use this file for framework-agnostic PHP guidance.
If the repository uses Laravel, layer the dedicated Laravel overlay on top of this one rather than placing framework-specific rules here.

## Language Baseline
- Target PHP 8+ syntax and features: strict typing, constructor property promotion, enums, `readonly` properties, match expressions, and named arguments where the repo convention allows.
- Enable `declare(strict_types=1)` in new source files unless the repo has an established exception.
- Follow PSR-12 for style unless the repo configures a formatter (Laravel Pint, PHP-CS-Fixer, etc.); the repo formatter is the final source of truth.
- Prefer small classes, focused methods, and explicit control flow.

## Typing and Interfaces
- Add type declarations to public functions, methods, parameters, and return values.
- Use DTOs, value objects, or `readonly` classes for explicit input/output contracts.
- Use interfaces and `final` classes deliberately; avoid extending concrete classes except where the framework or repo pattern requires it.
- Avoid `mixed` without a concrete compatibility reason.

## Error Handling
- Throw domain-specific exceptions with actionable context.
- Catch specific exception classes; do not blanket-catch `Throwable` except at the outermost boundary.
- Keep user-facing errors safe and structured; never render stack traces or internals to end users.
- Release file handles, streams, and DB cursors deterministically.

## Dependencies and Runtime Hygiene
- Prefer the latest stable PHP release from the official supported-versions table: https://www.php.net/supported-versions.php
- Use Composer for dependencies and commit `composer.lock` for deployed applications: https://getcomposer.org/doc/
- Consult each package's official documentation for correct usage, configuration, and version-specific behavior before implementation. Cite documentation references when the pattern is non-obvious.
- Check for security advisories, deprecation notices, and breaking-change announcements before adding or upgrading any package.
- Keep third-party additions minimal and justified.

## Security
- Never concatenate untrusted input into SQL, shell commands, file paths, or output without validation and escaping.
- Validate, normalize, and constrain all untrusted input at boundaries.
- Never commit `.env` files; document required variables in `.env.example`.

## Testing
- Add or update tests for changed behavior and cover failure paths, not only happy paths.
- Use the repo's actual test runner (PHPUnit, Pest, etc.) and fixture style rather than assuming one.
- Add regression tests for production defects.

## Official References
- PHP manual: https://www.php.net/manual/
- PSR-12: https://www.php-fig.org/psr/psr-12/
- Composer docs: https://getcomposer.org/doc/
- Always verify version-specific behavior against these sources before implementation.
