#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# create-github-repo.sh
# Create a new GitHub repository with branch protection and CODEOWNERS
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") [REPO_NAME] [DESCRIPTION] [public|private]

Arguments:
  REPO_NAME     Repository name (interactive if omitted)
  DESCRIPTION   Repository description (interactive if omitted, empty is OK)
  public|private  Visibility (interactive if omitted)

Options:
  -h, --help    Show this help message and exit

Examples:
  $(basename "$0") my-repo "My description" private
  $(basename "$0") my-repo
  $(basename "$0")
EOF
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

ARG_REPO_NAME="${1:-}"
ARG_DESCRIPTION="${2:-}"
ARG_VISIBILITY="${3:-}"

# ---------------------------------------------------------------------------
# Cleanup trap
# ---------------------------------------------------------------------------
TMPDIR_PATH=""
cleanup() {
  if [[ -n "$TMPDIR_PATH" && -d "$TMPDIR_PATH" ]]; then
    rm -rf "$TMPDIR_PATH"
  fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# 1. Authenticate
# ---------------------------------------------------------------------------
echo "==> Logging in to GitHub..."
gh auth login

# ---------------------------------------------------------------------------
# 2. Get GitHub username
# ---------------------------------------------------------------------------
USERNAME=$(gh api user --jq '.login')
echo "==> Logged in as: $USERNAME"

# ---------------------------------------------------------------------------
# 3. Collect inputs (args take precedence over interactive)
# ---------------------------------------------------------------------------

# Repository name (empty is not OK)
if [[ -n "$ARG_REPO_NAME" ]]; then
  REPO_NAME="$ARG_REPO_NAME"
else
  while true; do
    read -rp "Repository name: " REPO_NAME
    if [[ -n "$REPO_NAME" ]]; then
      break
    fi
    echo "Error: Repository name cannot be empty. Please try again."
  done
fi

# Description (empty is OK)
if [[ $# -ge 2 ]]; then
  DESCRIPTION="$ARG_DESCRIPTION"
else
  read -rp "Description (optional): " DESCRIPTION
fi

# Visibility
if [[ -n "$ARG_VISIBILITY" ]]; then
  case "$ARG_VISIBILITY" in
    public|private)
      VISIBILITY="$ARG_VISIBILITY"
      ;;
    *)
      echo "Error: Visibility must be 'public' or 'private', got: $ARG_VISIBILITY" >&2
      exit 1
      ;;
  esac
else
  while true; do
    read -rp "Visibility [public/private] (default: private): " VISIBILITY
    VISIBILITY="${VISIBILITY:-private}"
    case "$VISIBILITY" in
      public|private)
        break
        ;;
      *)
        echo "Error: Please enter 'public' or 'private'."
        ;;
    esac
  done
fi

echo ""
echo "==> Creating repository: $USERNAME/$REPO_NAME"
echo "    Description : ${DESCRIPTION:-<none>}"
echo "    Visibility  : $VISIBILITY"
echo ""

# ---------------------------------------------------------------------------
# 4. Create repository
# ---------------------------------------------------------------------------
gh repo create "$USERNAME/$REPO_NAME" \
  --"$VISIBILITY" \
  --description "$DESCRIPTION" \
  --enable-issues

echo "==> Repository created."

# ---------------------------------------------------------------------------
# 5. Clone → add CODEOWNERS → push
# ---------------------------------------------------------------------------
TMPDIR_PATH=$(mktemp -d)
echo "==> Cloning into $TMPDIR_PATH ..."
gh repo clone "$USERNAME/$REPO_NAME" "$TMPDIR_PATH"

pushd "$TMPDIR_PATH" > /dev/null

mkdir -p .github
echo "* @$USERNAME" > .github/CODEOWNERS

git add .github/CODEOWNERS
git commit -m "chore: add CODEOWNERS to require code review"
git push -u origin main

popd > /dev/null
echo "==> CODEOWNERS committed and pushed."

# ---------------------------------------------------------------------------
# 6. Enable Discussions and Projects
# ---------------------------------------------------------------------------
echo "==> Enabling Discussions and Projects..."
gh repo edit "$USERNAME/$REPO_NAME" \
  --enable-discussions \
  --enable-projects

# ---------------------------------------------------------------------------
# 7. Create branch protection ruleset for main
# ---------------------------------------------------------------------------
echo "==> Creating branch protection ruleset for 'main'..."
gh api "repos/$USERNAME/$REPO_NAME/rulesets" \
  -X POST \
  --input - <<EOF
{
  "name": "Protect main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
EOF

echo "==> Ruleset created."

# ---------------------------------------------------------------------------
# 8. Logout and finish
# ---------------------------------------------------------------------------
echo "==> Logging out..."
gh auth logout --hostname github.com

REPO_URL="https://github.com/$USERNAME/$REPO_NAME"
echo ""
echo "====================================================="
echo " Repository created successfully!"
echo " URL: $REPO_URL"
echo "====================================================="
