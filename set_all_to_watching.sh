#!/usr/bin/env bash
set -euo pipefail

# Extract the logged-in GitHub username
USER=$(gh auth status 2>/dev/null | grep -oE 'account [^ ]+' | awk '{print $2}')

if [ -z "${USER:-}" ]; then
  echo "❌ Could not detect logged-in GitHub username. Run 'gh auth login' first."
  exit 1
fi

echo "👤 Logged in as $USER"
echo "🔍 Checking repositories..."

# Loop through your repos and subscribe to all activity if not already watching
gh repo list "$USER" --limit 1000 --json name,owner | jq -r '.[] | "\(.owner.login)/\(.name)"' | while read -r repo; do
  echo "Checking $repo..."
  sub=$(gh api "repos/$repo/subscription" --jq '.subscribed' 2>/dev/null || echo "false")
  if [ "$sub" != "true" ]; then
    echo "➡️ Subscribing to $repo"
    gh api --method PUT "repos/$repo/subscription" \
      --input <(echo '{"subscribed": true, "ignored": false}') \
      >/dev/null || echo "❌ Failed to subscribe to $repo"
  else
    echo "✅ Already watching $repo"
  fi
done

echo "🎯 Done! All your repositories are now set to 'Watching (All Activity)'."

