#!/data/data/com.termux/files/usr/bin/bash
# Volley Rivals - Termux se APK build (GitHub Actions ke zariye)
# Use:  bash termux_build.sh
set -e

REPO_NAME="volley_rivals"
APK_NAME="VolleyRivals.apk"

echo "==> [1/6] Packages install"
pkg update -y
pkg install -y git gh

echo "==> [2/6] Storage permission (APK Downloads me save hoga)"
[ -d "$HOME/storage/downloads" ] || termux-setup-storage || true

echo "==> [3/6] GitHub login"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login -h github.com -p https -w
fi
gh auth setup-git

echo "==> [4/6] Git repo + push"
[ -d .git ] || git init -b main
git config user.name  >/dev/null || git config user.name  "$(gh api user -q .login)"
git config user.email >/dev/null || git config user.email "$(gh api user -q .login)@users.noreply.github.com"
git add -A
git commit -m "Build Volley Rivals" || true

if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "$REPO_NAME" --private --source=. --remote=origin
fi
git push -u origin main

echo "==> [5/6] Build ka wait (5-10 min)"
sleep 8
RUN_ID=$(gh run list --workflow=build.yml --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch "$RUN_ID" --exit-status

echo "==> [6/6] APK download"
rm -rf apk_out
gh run download "$RUN_ID" -n VolleyRivals-apk -D apk_out
DEST="$HOME/storage/downloads/$APK_NAME"
[ -d "$HOME/storage/downloads" ] || DEST="$PWD/apk_out/$APK_NAME"
cp apk_out/$APK_NAME "$DEST"
echo "APK ready: $DEST"
termux-open "$DEST" || echo "Files app se APK kholkar install karo."
