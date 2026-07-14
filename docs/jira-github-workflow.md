# Jira And GitHub Workflow

This repo is intentionally convention-driven. Jira and GitHub link work automatically when the Jira issue key appears in development activity.

## Naming Rules

Use the Jira key in all development surfaces:

| Surface | Example |
| --- | --- |
| Branch | `BZINEDDA-107-feat-homepage` |
| Commit | `BZINEDDA-107 feat: homepage` |
| Pull request | `BZINEDDA-107 feat: homepage` |

## Developer Loop

1. Pick a Jira issue from the board.
2. Move it to `todo`.
3. Create a branch containing the Jira key.
4. Commit with the Jira key.
5. Open a PR with the Jira key in the title.
6. GitHub Actions runs CI.
7. Jira shows the branch, commits, PR, builds, and deployments.
8. Merge after review.
9. Deploy to staging.
10. Move the Jira issue to `done` after verification.

## Workflow State Mapping

Use these statuses in Jira:

- `Backlog`: not ready to start.
- `To Do`: selected for implementation.
- `In Progress`: actively being worked.
- `BLOCKED`: waiting on a dependency.
- `TEST`: deployed or ready for verification.
- `Done`: verified and complete.

## What To Screenshot For Portfolio Proof

- Jira card showing linked GitHub branch or PR.
- GitHub Actions CI passing.
- GHCR package with image tags.
- K3s rollout status.
- Running portfolio app in staging.
