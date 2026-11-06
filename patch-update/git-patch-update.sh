#!/bin/bash
# Update a git-installed web app while keeping your own edits to its files.
# https://github.com/wgourley/vps-scripts
#
# Saves your local changes as a patch, pulls the update, then re-applies the
# patch. If upstream changed the same lines, it stops and tells you, instead
# of overwriting their fix or silently dropping yours.

set -e

# ---- settings -----------------------------------------------------------
REPO_DIR="/srv/myapp"                         # git checkout of the app
FILES="view/contact.php objects/sendEmail.json.php"   # files you have edited
PATCH="/root/myapp-local.patch"               # where your changes are kept
OWNER="33:33"                                 # web server uid:gid (www-data = 33 on Debian)
# --------------------------------------------------------------------------

cd "$REPO_DIR"

# 1. Save current local changes (only replace the saved patch if there are any).
# shellcheck disable=SC2086
git diff -- $FILES > "$PATCH.latest" || true
[ -s "$PATCH.latest" ] && cp "$PATCH.latest" "$PATCH"

# 2. Set them aside and update.
# shellcheck disable=SC2086
git stash push -m "local-patch" -- $FILES >/dev/null 2>&1 || true
git pull --ff-only

# 3. Put them back, but only if they still fit.
if git apply --check "$PATCH" 2>/dev/null; then
  git apply "$PATCH" && echo "Local changes re-applied OK"
  git stash drop >/dev/null 2>&1 || true
else
  echo "WARNING: local changes could NOT be re-applied automatically."
  echo "Upstream changed one of: $FILES"
  echo "Your changes are saved in $PATCH (and in 'git stash list'). Re-apply them by hand."
fi

chown -R "$OWNER" "$REPO_DIR" 2>/dev/null || true
