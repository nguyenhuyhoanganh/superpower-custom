#!/usr/bin/env bash
# Local Chromium WebUI style gate, modeled on the cheap parts of
# `git cl presubmit`. Checks only the lines you changed (the git diff), so
# pre-existing violations elsewhere don't drown out your own.
#
# Usage:
#   check-style.sh                 # working-tree changes vs HEAD; if the tree
#                                  # is clean, falls back to the last commit
#                                  # (HEAD~1..HEAD)
#   check-style.sh <base-ref>      # everything changed since <base-ref>,
#                                  # e.g. origin/main, HEAD~3, a SHA
#
# Exit code: non-zero if any ERROR is found (suitable for a pre-push hook).
set -uo pipefail

BASE="${1:-}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not inside a git repository." >&2
  exit 2
fi

# Decide what to diff against.
if [ -z "$BASE" ]; then
  if ! git diff --quiet HEAD 2>/dev/null; then
    BASE="HEAD"        # uncommitted changes present -> review the working tree
  else
    BASE="HEAD~1"      # clean tree -> review the most recent commit
  fi
fi

# Changed WebUI files (added/copied/modified/renamed).
mapfile -t FILES < <(git diff --name-only --diff-filter=ACMR "$BASE" -- \
  '*.html' '*.css' '*.ts' '*.js' 2>/dev/null)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No changed WebUI (.html/.css/.ts/.js) files vs '$BASE'. Nothing to check."
  exit 0
fi

RESULTS="$(mktemp)"
trap 'rm -f "$RESULTS"' EXIT

# Emit "LINENO<TAB>CONTENT" for each added line in $1's diff vs $BASE,
# tracking new-file line numbers through the hunk headers.
added_lines() {
  git diff "$BASE" -- "$1" | awk '
    /^@@/      { s=$0; sub(/^.*\+/,"",s); sub(/[, ].*$/,"",s); nl=s+0; next }
    /^\+\+\+/  { next }
    /^\+/      { print nl "\t" substr($0,2); nl++; next }
    /^-/       { next }      # deleted or "---" header: no new-file advance
    /^\\/      { next }      # "\ No newline at end of file"
                { nl++ }     # context / blank line advances new-file counter
  '
}

# ---- awk programs (input records are "LINENO<TAB>CONTENT") -------------------

COMMON_AWK='
BEGIN { FS="\t" }
{
  if (NF==0) next
  ln=$1; c=substr($0, index($0,"\t")+1)
  if (length(c) > 80)
    print "ERROR\t" F ":" ln "\tLine exceeds 80 columns (" length(c) ")"
  if (c ~ /[ \t]$/)
    print "WARN\t" F ":" ln "\tTrailing whitespace"
  if (c ~ /\t/)
    print "WARN\t" F ":" ln "\tTab character (use 2-space indentation)"
}'

CSS_AWK='
BEGIN { FS="\t" }
{
  if (NF==0) next
  ln=$1; c=substr($0, index($0,"\t")+1)
  if (c ~ /(^|[: (])0(px|em|rem|pt|ex|ch|vh|vw|cm|mm|in|pc)([; )]|$)/)
    print "WARN\t" F ":" ln "\tZero value should omit its unit (e.g. 0px -> 0)"
  if (c ~ /[: ]0?\.[0-9]+s([ ;)]|$)/)
    print "WARN\t" F ":" ln "\tSub-second time: use ms granularity (e.g. 200ms)"
  if (c ~ /!important/)
    print "WARN\t" F ":" ln "\tAvoid !important; use selector specificity"
  if (c ~ /@apply/ || c ~ /^[[:space:]]*--[a-zA-Z0-9-]+:[[:space:]]*\{/)
    print "ERROR\t" F ":" ln "\tCSS Mixins are banned; use Shadow Parts / vars / classes"
  # Double quotes (single quotes preferred), except @charset.
  if (c ~ /"/ && c !~ /@charset/)
    print "WARN\t" F ":" ln "\tUse single quotes in CSS, not double quotes"
}'

# CSS alphabetical-order check needs block context: read added line numbers
# first (NR==FNR), then walk the whole file, resetting at each { or }.
CSS_ORDER_AWK='
NR==FNR { added[$1]=1; next }
{
  if ($0 ~ /[{}]/) { prev=""; next }
  if (match($0, /^[[:space:]]*[-a-zA-Z][-a-zA-Z0-9]*[[:space:]]*:/)) {
    p=substr($0, RSTART, RLENGTH); gsub(/[[:space:]:]/,"",p)
    if (prev != "" && p < prev && (FNR in added))
      print "WARN\t" F ":" FNR "\tCSS property \x27" p "\x27 out of alphabetical order (after \x27" prev "\x27)"
    prev=p
  }
}'

HTML_AWK='
BEGIN { FS="\t" }
{
  if (NF==0) next
  ln=$1; c=substr($0, index($0,"\t")+1)
  if (c ~ /<[^>]*[[:space:]]style[[:space:]]*=/)
    print "ERROR\t" F ":" ln "\tInline style= attribute; move styling to CSS"
  if (c ~ /<[^>]*[[:space:]]on[a-z]+[[:space:]]*=/)
    print "ERROR\t" F ":" ln "\tInline event handler; wire it up in TS (on-click binding is ok)"
  if (c ~ /<(input|img|br|hr|meta|link|source|area|base|col|embed|param|track|wbr)([ \t][^>]*)?\/>/)
    print "WARN\t" F ":" ln "\tDo not self-close void tags (e.g. <input type=\"radio\">)"
  if (c ~ /<br[ >\/]/)
    print "WARN\t" F ":" ln "\tAvoid <br>; use block elements / margins"
  if (c ~ /<input[^>]*type[[:space:]]*=[[:space:]]*["\x27]button["\x27]/)
    print "WARN\t" F ":" ln "\tUse <button> instead of <input type=\"button\">"
}'

TS_AWK='
BEGIN { FS="\t" }
{
  if (NF==0) next
  ln=$1; c=substr($0, index($0,"\t")+1)
  if (c ~ /document\.getElementById/)
    print "WARN\t" F ":" ln "\tPrefer $(\x27id\x27) over document.getElementById"
  if (c ~ /(^|[^.A-Za-z_$])var[[:space:]]/)
    print "ERROR\t" F ":" ln "\tDo not use var; use const or let"
  if (c ~ /(^|[^.A-Za-z0-9_$])isNaN[[:space:]]*\(/)
    print "WARN\t" F ":" ln "\tUse Number.isNaN() instead of global isNaN()"
  if (c ~ /[^=!<>]==[^=]/ && c !~ /==[[:space:]]*null/)
    print "WARN\t" F ":" ln "\tUse strict === (== allowed only against null)"
  if (c ~ /[^=!]!=[^=]/ && c !~ /!=[[:space:]]*null/)
    print "WARN\t" F ":" ln "\tUse strict !== (!= allowed only against null)"
}'

# ---- run checks -------------------------------------------------------------

for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue          # skip deletes / files removed from worktree
  al="$(added_lines "$f")"
  [ -n "$al" ] || continue

  printf '%s\n' "$al" | awk -v F="$f" "$COMMON_AWK" >> "$RESULTS"

  case "${f##*.}" in
    css)
      printf '%s\n' "$al" | awk -v F="$f" "$CSS_AWK" >> "$RESULTS"
      awk -v F="$f" "$CSS_ORDER_AWK" \
        <(printf '%s\n' "$al" | cut -f1) "$f" >> "$RESULTS"
      ;;
    html)
      printf '%s\n' "$al" | awk -v F="$f" "$HTML_AWK" >> "$RESULTS"
      ;;
    ts|js)
      printf '%s\n' "$al" | awk -v F="$f" "$TS_AWK" >> "$RESULTS"
      ;;
  esac
done

# ---- report -----------------------------------------------------------------

errors=$(grep -c '^ERROR' "$RESULTS" 2>/dev/null || true)
warns=$(grep -c '^WARN'  "$RESULTS" 2>/dev/null || true)
errors=${errors:-0}; warns=${warns:-0}

echo "Chromium WebUI style check (diff base: $BASE, files: ${#FILES[@]})"
echo "---------------------------------------------------------------"
if [ "$((errors + warns))" -eq 0 ]; then
  echo "Clean: no style issues on changed lines."
  echo "(Remember the manual checklist in SKILL.md + the real git cl presubmit.)"
  exit 0
fi

sort -t: -k1,1 "$RESULTS" | sed 's/^ERROR\t/  [ERROR] /; s/^WARN\t/  [warn]  /'
echo "---------------------------------------------------------------"
echo "Summary: $errors error(s), $warns warning(s)."

[ "$errors" -gt 0 ] && exit 1
exit 0
