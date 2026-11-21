#!/usr/bin/env bash
# Bring upstream's mob components and their tests into this checkout, for
# .github/workflows/sync-upstream.yml. Run from the repo root on a clean tree.
#
#   sync-upstream-apply.sh <upstream clone> <last sync sha or ""> <new sha> <report file>
#
# <upstream clone> is a clone of mishka-group/mishka_chelekom with full history
# (a blob-less partial clone is enough); it is left checked out at <new sha>.
#
# With a last sync sha, only upstream's DELTA is applied: upstream at both shas
# goes through rewrite(), the two rewritten trees are diffed, and each file's
# diff is `git apply -3`'d here. So what mob_mishka cut or reworded since the
# last sync (showcase-gallery tests, trimmed docs, credo fixes) stays cut, and
# upstream's new files are added and its deleted ones removed. A file whose
# hunks clash with local edits is left with conflict markers, staged, and
# listed in <report file>; so is a file whose diff can't be applied at all
# (a local file mob_mishka deleted, say), without markers.
#
# With no last sync sha there is nothing to diff against, so every upstream
# file is copied over whole.
set -euo pipefail
shopt -s nullglob

UPSTREAM_PATH=development/mob/lib/mishka_mob/components
UPSTREAM_TEST_PATH=development/mob/test/mishka_mob/components
LOCAL_PATH=lib/mob_mishka/components
LOCAL_TEST_PATH=test/mob_mishka/components

src=$1
last=$2
new=$3
report=$4
: > "$report"

# The namespace rewrite: a whole-word substitution on the `MishkaMob.Components`
# namespace. Any other `MishkaMob.*` left afterwards (upstream's showcase
# gallery, which mob_mishka doesn't ship) is for the reviewer to cut. ERE with
# an explicit non-word class rather than `\b`, so it runs the same under GNU
# and BSD sed.
rewrite() {
  sed -E \
    -e 's/MishkaMob\.Components/MobMishka.Components/g' \
    -e 's/defmodule MishkaMob([^[:alnum:]_]|$)/defmodule MobMishka\1/g' \
    -e 's/alias MishkaMob([^[:alnum:]_]|$)/alias MobMishka\1/g' \
    "$1" > "$2"
}

# Upstream at <sha>, rewritten, under <root>/lib/... and <root>/test/....
transform() {
  local sha=$1 root=$2 f
  git -C "$src" checkout -q --detach "$sha"
  mkdir -p "$root/$LOCAL_PATH" "$root/$LOCAL_TEST_PATH"
  for f in "$src/$UPSTREAM_PATH"/*.ex; do
    rewrite "$f" "$root/$LOCAL_PATH/$(basename "$f")"
  done
  for f in "$src/$UPSTREAM_TEST_PATH"/*.exs; do
    rewrite "$f" "$root/$LOCAL_TEST_PATH/$(basename "$f")"
  done
}

if [ -z "$last" ]; then
  transform "$new" .
  exit 0
fi

if ! git -C "$src" cat-file -e "$last^{commit}" 2>/dev/null; then
  echo "::error::last sync $last is not in upstream's history; cannot compute the delta" >&2
  exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work" "$work.patch" "$work.err"' EXIT

git -C "$work" init -q
transform "$last" "$work"
git -C "$work" add -A
git -C "$work" -c user.name=sync -c user.email=sync@localhost commit -q --allow-empty -m "upstream $last"
rm -rf "${work:?}/lib" "${work:?}/test"
transform "$new" "$work"
git -C "$work" add -A

# git apply -3 falls back on a 3-way merge only when the preimage blobs (the
# rewritten upstream at LAST_SYNC) are in this repo's object store.
git fetch -q --no-tags "$work" HEAD

git -C "$work" diff --cached --name-only --no-renames | while IFS= read -r path; do
  git -C "$work" diff --cached --binary --no-renames -- "$path" > "$work.patch"
  if git apply -3 "$work.patch" 2> "$work.err"; then
    echo "applied: $path"
  elif [ -n "$(git ls-files --unmerged -- "$path")" ]; then
    # Staged with its markers, so the PR commits them and CI stays red until
    # a reviewer resolves them.
    git add -- "$path"
    echo "conflict: $path"
    echo "- \`$path\`: conflict markers" >> "$report"
  else
    echo "not applied: $path"
    sed 's/^/    /' "$work.err"
    reason=$(grep -m1 '^error: ' "$work.err" || echo "error: git apply failed")
    reason=${reason#error: }
    echo "- \`$path\`: not applied, ${reason#"$path": }" >> "$report"
  fi
done
