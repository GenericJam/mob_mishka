# The upstream sync applies upstream's delta, not whole files
- Date: 2026-11-20
- Status: accepted

## Context
`sync-upstream.yml` copied every upstream component and test over the local
one through the namespace rewrite. Each sync therefore re-introduced every
block mob_mishka had cut or reworded (showcase-gallery tests, trimmed docs,
credo fixes), and the reviewer had to find and revert them again; #6 was
closed for that and #7 reconciled the range by hand. The workflow also
force-pushed over review commits every hour, and its `tests` runs never
executed (a `GITHUB_TOKEN` push is held as `action_required`). MOB-536.

## Decision
`.github/scripts/sync-upstream-apply.sh` rewrites upstream at
`.upstream-sync-sha` and at the new HEAD, diffs the two rewritten trees, and
`git apply -3`s each file's diff onto master. A file whose hunks clash with a
local edit is committed with its conflict markers and listed under "Conflicts
to resolve" in the PR body, so CI is red until a reviewer resolves it. A diff
that can't be applied at all (a local file mob_mishka deleted) is listed and
left alone. With no `.upstream-sync-sha` every file is still copied whole.

The workflow leaves `sync/upstream-mishka` alone while its PR is open and it
carries a commit `github-actions[bot]` didn't commit, and dispatches `tests` on
the branch after updating the PR.

Checked against #7: rerunning the delta for `b57c7d27..776c535b` on the
pre-#7 master (62df7d4) reproduces #7's component and test changes except the
credo edits #7 made by hand and the one `mishka_tree_test.exs` conflict (the
showcase-page block mob_mishka cut).

## Consequences
- A conflicted sync PR fails CI by design; that is the signal to resolve it.
- The upstream clone needs full history (`--filter=blob:none`, no `--depth`).
- If upstream rewrites history so `.upstream-sync-sha` is gone, the sync fails
  loudly instead of falling back to a whole-file copy.
