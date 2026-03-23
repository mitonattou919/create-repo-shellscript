# create-github-repo.sh

A shell script that creates a GitHub repository and configures branch protection, CODEOWNERS, and various features all at once.

## Features

When executed, the script automatically performs the following:

1. Logs in via GitHub CLI (`gh auth login`)
2. Creates a repository (with configurable visibility and description)
3. Adds a `CODEOWNERS` file and pushes it (requires owner approval for all file changes)
4. Enables Discussions and Projects
5. Creates a protection ruleset for the `main` branch:
   - Prevents branch deletion
   - Prevents force pushes
   - Requires at least 1 approver before merging a PR
   - Requires code owner review
   - Dismisses stale reviews on push
6. Logs out from GitHub CLI

## Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) must be installed
- `git` must be installed

## Usage

```bash
# Interactive mode (no arguments)
./create-github-repo.sh

# Run with arguments
./create-github-repo.sh <REPO_NAME> [DESCRIPTION] [public|private]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `REPO_NAME` | Repository name | Interactive input |
| `DESCRIPTION` | Repository description (optional) | Interactive input |
| `public\|private` | Visibility setting | Interactive input (default: `private`) |

### Examples

```bash
# Specify repository name, description, and visibility
./create-github-repo.sh my-repo "My description" private

# Specify repository name only (other fields via interactive input)
./create-github-repo.sh my-repo

# All fields via interactive input
./create-github-repo.sh
```

## Branch Protection Rule Details

The following ruleset (`Protect main`) is created for the `main` branch:

| Rule | Setting |
|------|---------|
| Branch deletion | Prohibited |
| Force push | Prohibited |
| Required approvers | 1 |
| Code owner review | Required |
| Dismiss stale reviews on push | Enabled |

## Notes

- The temporary directory is automatically deleted when the script exits
- `gh auth logout` is automatically executed after the script completes
- Repository name cannot be empty
