# Module Manifest Versioning Guide

This guide explains how to version and update `.github/starter-modules.json`, the source of truth for which files belong to which modules.

## Purpose of the Module Manifest

The module manifest (`.github/starter-modules.json`) defines:
- Which files belong to which modules
- Whether modules are core, optional, or overlay
- Default enablement status for each module
- When each module should be used

This manifest is used by:
- Validation scripts to verify file presence
- Adoption runbooks to guide module selection
- CI workflows to validate module integrity

## Versioning Strategy

The manifest uses semantic versioning:

### Major Version (X.0.0)
Increment when:
- Removing modules or files from existing modules
- Changing the structure of the manifest schema
- Breaking changes to module IDs or kinds
- Removing support for existing adoption patterns

**Example**: `1.0.0` → `2.0.0`
- Removed `core-agents` module
- Changed `kind` field values
- Restructured module hierarchy

### Minor Version (0.X.0)
Increment when:
- Adding new modules
- Adding files to existing modules
- Adding new optional fields to module definitions
- Backward-compatible schema changes

**Example**: `1.0.0` → `1.1.0`
- Added `workflow-evals` module
- Added new files to `core-governance`
- Added `description` field to modules

### Patch Version (0.0.X)
Increment when:
- Fixing typos in file paths
- Correcting module metadata
- Updating descriptions
- No structural changes

**Example**: `1.1.0` → `1.1.1`
- Fixed typo in file path
- Corrected module description

## When to Update the Manifest

### Add a New File

**Scenario**: You've added a new validation script

**Steps**:
1. Determine which module the file belongs to
2. Add the file path to the module's `files` array
3. Increment the minor version
4. Update the changelog

**Example**:
```json
{
  "version": "1.2.0",  // Incremented from 1.1.0
  "modules": [
    {
      "id": "core-governance",
      "files": [
        // ... existing files ...
        ".github/scripts/check-new-feature.sh"  // Added
      ]
    }
  ]
}
```

### Add a New Module

**Scenario**: You've created a new overlay for a specific stack

**Steps**:
1. Create a new module entry with:
   - Unique `id`
   - Appropriate `kind` (core, optional, overlay)
   - `defaultEnabled` status
   - `when` description
   - `files` array
2. Increment the minor version
3. Update the changelog

**Example**:
```json
{
  "version": "1.2.0",
  "modules": [
    // ... existing modules ...
    {
      "id": "overlay-new-stack",
      "kind": "overlay",
      "defaultEnabled": false,
      "when": "Repositories using NewStack framework",
      "files": [
        ".github/instructions/newstack.instructions.md",
        ".github/skills/newstack-helper/SKILL.md"
      ]
    }
  ]
}
```

### Remove a File

**Scenario**: You've deprecated a validation script

**Steps**:
1. Remove the file from the module's `files` array
2. Increment the major version (breaking change)
3. Document the removal in the changelog
4. Provide migration guidance

**Example**:
```json
{
  "version": "2.0.0",  // Major version bump
  "modules": [
    {
      "id": "core-governance",
      "files": [
        // ... existing files ...
        // Removed: ".github/scripts/deprecated-check.sh"
      ]
    }
  ]
}
```

### Rename a Module

**Scenario**: You want to rename a module for clarity

**Steps**:
1. Change the module `id`
2. Increment the major version (breaking change)
3. Update all references to the old module ID
4. Document the rename in the changelog

**Example**:
```json
{
  "version": "2.0.0",
  "modules": [
    {
      "id": "core-validation",  // Renamed from "core-governance"
      // ... rest of module definition ...
    }
  ]
}
```

## Validation Rules

The manifest is validated by `.github/scripts/check-starter-manifest.sh` and `.github/scripts/check-starter-manifest.ps1`.

### Required Fields

Each module must have:
- `id`: Unique identifier (lowercase, hyphens)
- `kind`: One of `core`, `optional`, `overlay`
- `defaultEnabled`: Boolean
- `when`: Description of when to use this module
- `files`: Array of file paths

### File Path Rules

- Paths must be relative to repository root
- Paths must use forward slashes (`/`)
- Paths must not contain wildcards
- All listed files must exist in the repository
- No duplicate file paths across modules

### Module ID Rules

- Must be unique across all modules
- Must use lowercase letters, numbers, and hyphens
- Must start with a letter
- Should be descriptive and stable

## Best Practices

### 1. Keep Modules Cohesive

Each module should represent a logical unit of functionality:
- **Core modules**: Essential for all repositories
- **Optional modules**: Useful for many repositories
- **Overlay modules**: Specific to certain stacks or workflows

### 2. Minimize Breaking Changes

- Prefer adding new modules over modifying existing ones
- Deprecate files before removing them
- Provide migration paths for major version bumps

### 3. Document Changes

Always update the changelog when modifying the manifest:

```markdown
### 2026-06-20 - Add evaluation harness module

- Area: starter governance
- Change type: feature
- Summary: added `workflow-evals` module with 6 eval tasks and validation scripts
- Reason: provide golden-task evaluation harness for testing agent behavior
- Affected files: .github/starter-modules.json
- Related docs: docs/runbooks/evals.md
- Validation: bash .github/scripts/check-starter-manifest.sh passed
- Discrepancies or follow-up: none
```

### 4. Test After Changes

After updating the manifest:

```bash
# Validate the manifest
bash .github/scripts/check-starter-manifest.sh

# Run full validation
bash .github/scripts/check-starter-workflow.sh
```

### 5. Review File Ownership

Before adding a file to a module, consider:
- Does this file logically belong to this module?
- Will removing this module break other modules?
- Is this file used by multiple modules? (If so, which module owns it?)

## Common Patterns

### Pattern 1: Stack-Specific Overlay

```json
{
  "id": "overlay-react",
  "kind": "overlay",
  "defaultEnabled": false,
  "when": "Repositories using React",
  "files": [
    ".github/instructions/react.instructions.md",
    ".github/skills/react-component/SKILL.md"
  ]
}
```

### Pattern 2: Core Module with Optional Files

```json
{
  "id": "core-agents",
  "kind": "core",
  "defaultEnabled": true,
  "when": "All repositories using agents",
  "files": [
    ".github/AGENTS.md",
    ".github/agents/analyst.agent.md",
    ".github/agents/tech-planner.agent.md"
    // Add more agents as needed
  ]
}
```

### Pattern 3: Feature Module

```json
{
  "id": "feature-approval-handoffs",
  "kind": "optional",
  "defaultEnabled": false,
  "when": "Repositories that want approval-gated handoffs",
  "files": [
    ".github/agents/orchestration-coordinator.agent.md",
    ".github/skills/approval-gated-handoffs/SKILL.md",
    "docs/runbooks/approval-gated-handoffs.md"
  ]
}
```

## Troubleshooting

### Validation Fails: "File not found"

**Problem**: Manifest lists a file that doesn't exist

**Solution**: 
- Check the file path for typos
- Ensure the file exists in the repository
- Use forward slashes in paths

### Validation Fails: "Duplicate file path"

**Problem**: Same file listed in multiple modules

**Solution**:
- Determine which module should own the file
- Remove the file from other modules
- Consider if the file should be in a shared module

### Validation Fails: "Invalid module kind"

**Problem**: Module `kind` is not `core`, `optional`, or `overlay`

**Solution**:
- Use one of the three valid kinds
- Check for typos

## Related Documentation

- [Starter Composition](starter-composition.md)
- [Starter Adoption](starter-adoption.md)
- [Skills](skills.md)
