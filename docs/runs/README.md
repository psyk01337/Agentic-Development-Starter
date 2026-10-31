# Run Archives

This directory holds one Markdown file per archived engine run: `<run-id>.md`.

Run state lives under `.agentic/state/`, which is gitignored. Without an archive a completed run leaves no evidence behind — the commit shows the diff, and nothing shows which gates it passed, what evidence was recorded, or why a repair happened.

## Producing An Entry

Generate the file; do not hand-write it.

```bash
python .github/scripts/agentic_engine.py archive --run-id <run-id>
```

`--out <path>` writes somewhere other than the default. The command reads the run state, so the entry is only as complete as the run was: archive a run before deleting its state, because deleting first destroys the history the archive would have captured.

## What An Entry Contains

Task identity, acceptance criteria, the declared write set, the status and final stage, every history entry in order, and any blocker. It is a record of what the engine observed, not a summary of what someone believes happened.

## Committing

A run archive belongs with the change it describes, so commit it in the same change as the code. It is reviewed like any other file: an archive showing a `NOT_VERIFIED` verify that reached `review` is a defect in the run, and it should be visible in the pull request rather than buried in an operator's local state.
