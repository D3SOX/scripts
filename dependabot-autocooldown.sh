#!/usr/bin/env bash
set -euo pipefail

# Config
BASE_DIR="$HOME/dependabot-autocooldown-repos"
COMMIT_TITLE="ci: configure dependency cooldown"
COMMIT_BODY="See: https://blog.yossarian.net/2025/11/21/We-should-all-be-using-dependency-cooldowns"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd gh
require_cmd git
require_cmd python
# Disable pagers for scripted git output
export GIT_PAGER=cat
export LESS=FRX

# Ensure ruamel.yaml is available (needed to preserve comments/quotes)
python - <<'PY'
import sys
try:
    import ruamel.yaml  # type: ignore
except Exception:
    sys.stderr.write("ruamel.yaml is required. Install with pip install or preferably via your system package manager (named python-ruamel-yaml on most distros).\n")
    sys.exit(1)
PY

SKIP_FETCH=0
USE_HTTPS=0
for arg in "$@"; do
  case "$arg" in
    --no-fetch) SKIP_FETCH=1 ;;
    --https) USE_HTTPS=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--no-fetch] [--https]" >&2
      exit 1
      ;;
  esac
done

echo "Base directory: ${BASE_DIR}"
mkdir -p "${BASE_DIR}"

echo "Listing non-fork repositories for authenticated user (owned + member orgs)..."
mapfile -t REPOS < <({
  gh api -X GET /user/repos --paginate -F per_page=100 -f type=owner -q '.[] | select((.fork|not) and (.archived|not)) | "\(.full_name)|\(.ssh_url)|\(.clone_url)"'
  gh api -X GET /user/repos --paginate -F per_page=100 -f type=member -q '.[] | select((.fork|not) and (.archived|not)) | "\(.full_name)|\(.ssh_url)|\(.clone_url)"'
} | sort -u)

echo "Found ${#REPOS[@]} repositories."

for entry in "${REPOS[@]}"; do
  IFS="|" read -r name_with_owner ssh_url https_url <<<"${entry}"
  repo_name="${name_with_owner#*/}"
  repo_dir="${BASE_DIR}/${repo_name}"
  clone_url="${ssh_url}"
  if [ "${USE_HTTPS}" -eq 1 ]; then
    clone_url="${https_url}"
  fi

  echo
  echo "=== ${name_with_owner} ==="

  if [ ! -d "${repo_dir}/.git" ]; then
    echo "Cloning into ${repo_dir}..."
    git clone "${clone_url}" "${repo_dir}"
  elif [ "${SKIP_FETCH}" -eq 0 ]; then
    echo "Repo already cloned at ${repo_dir}, fetching latest..."
    git -C "${repo_dir}" fetch --all --prune
  else
    echo "Repo already cloned at ${repo_dir}, skipping fetch (per --no-fetch)."
  fi

  dependabot_yml="${repo_dir}/.github/dependabot.yml"
  dependabot_yaml="${repo_dir}/.github/dependabot.yaml"
  if [ -f "${dependabot_yml}" ]; then
    dependabot_file="${dependabot_yml}"
  elif [ -f "${dependabot_yaml}" ]; then
    dependabot_file="${dependabot_yaml}"
  else
    echo "No .github/dependabot.yml or .github/dependabot.yaml found; skipping."
    continue
  fi

  echo "Ensuring cooldown defaults are set in ${dependabot_file}..."
  change_status=$(DEPENDABOT_FILE="${dependabot_file}" python - <<'PY'
from pathlib import Path
import os
import sys
from ruamel.yaml import YAML

path = Path(os.environ["DEPENDABOT_FILE"])
yaml = YAML()
yaml.preserve_quotes = True
yaml.representer.ignore_aliases = lambda *args: True

data = yaml.load(path.read_text()) or {}

updates = data.get("updates", [])
if not isinstance(updates, list):
    sys.stderr.write("updates is not a list; skipping modification.\n")
    print("SKIPPED")
    sys.exit(0)

changed = False
for update in updates:
    if not isinstance(update, dict):
        continue
    desired = {"default-days": 7}
    if update.get("cooldown") != desired:
        update["cooldown"] = desired
        changed = True

if changed:
    with path.open("w") as fh:
        yaml.dump(data, fh)
    print("CHANGED")
else:
    print("UNCHANGED")
PY
)

  echo "Status: ${change_status}"

  if [ "${change_status}" != "CHANGED" ]; then
    continue
  fi

  echo "Committing change..."
  git -C "${repo_dir}" add .github/dependabot.yml
  if git -C "${repo_dir}" diff --cached --quiet -- .github/dependabot.yml; then
    echo "No staged changes for dependabot.yml; skipping commit."
    git -C "${repo_dir}" reset .github/dependabot.yml >/dev/null
    continue
  fi

  git -C "${repo_dir}" commit -m "${COMMIT_TITLE}" -m "${COMMIT_BODY}" -- .github/dependabot.yml || true
done

echo
echo "Review commits and optionally push:"
for entry in "${REPOS[@]}"; do
  name_with_owner="${entry%% *}"
  repo_name="${name_with_owner#*/}"
  repo_dir="${BASE_DIR}/${repo_name}"
  [ -d "${repo_dir}/.git" ] || continue

  commit_line=$(git -C "${repo_dir}" log -1 --oneline --grep "${COMMIT_TITLE}" -- .github/dependabot.yml .github/dependabot.yaml || true)
  if [ -z "${commit_line}" ]; then
    continue
  fi

  commit_sha="${commit_line%% *}"
  current_branch=$(git -C "${repo_dir}" symbolic-ref --short HEAD 2>/dev/null || echo "")
  remote_sha=""
  if [ -n "${current_branch}" ]; then
    remote_sha=$(git -C "${repo_dir}" ls-remote --heads origin "${current_branch}" | awk 'NR==1 {print $1}')
  fi

  if [ -n "${remote_sha}" ] && git -C "${repo_dir}" merge-base --is-ancestor "${commit_sha}" "${remote_sha}"; then
    echo
    echo "${name_with_owner}: ${commit_line}"
    echo "Commit already on origin/${current_branch}; skipping push prompt."
    continue
  fi

  echo
  echo "${name_with_owner}: ${commit_line}"
  git -C "${repo_dir}" show -w --stat --patch --color=always -- .github/dependabot.yml .github/dependabot.yaml
  if [ -t 0 ]; then
    read -r -p "Push this commit? [y/N] " reply || true
    if [[ "${reply:-}" =~ ^[Yy]$ ]]; then
      if ! git -C "${repo_dir}" push; then
        echo "Push failed for ${name_with_owner}; continuing to next repo."
      fi
    else
      echo "Skipped push for ${name_with_owner}."
    fi
  else
    echo "Non-interactive session; not pushing ${name_with_owner}. Run: git -C \"${repo_dir}\" push"
  fi
done

echo "All done."

