# Practice Loop: BZINEDDA-137

Story: **feat: portfolio homepage**

Epic: Portfolio Website

## Completed Locally

- Portfolio repository initialized at `/home/bzinedda/Desktop/portfolio`
- CI, image publish, and K3s deploy workflows configured
- Practice branch created: `BZINEDDA-137-feat-homepage`
- Jira story and subtasks created via `jira-iac apply`

## Remaining GitHub Steps

Push the repository to GitHub, then open the pull request:

```bash
git remote add origin git@github.com:Pedro-99/portfolio.git
git push -u origin main
git push -u origin BZINEDDA-137-feat-homepage
```

Open pull request:

```text
BZINEDDA-137 feat: portfolio homepage
```

After merge to `main`:

1. Confirm **Publish Image** workflow pushed to GHCR.
2. Confirm **Deploy Staging** workflow rolled out to K3s.
3. Move subtasks in Jira:
   - `Deploy to K3s staging` → Done after rollout succeeds
   - `Link GitHub PR to Jira issue` → Done after Jira development panel shows the PR
4. Move story `BZINEDDA-137` to **Done**.

## GitHub Repository Setup

Before deploy succeeds:

1. Create GitHub environment `staging`.
2. Add secret `K3S_KUBECONFIG_B64`.
3. Install **GitHub for Jira** and connect this repository.

See [k3s-staging-setup.md](./k3s-staging-setup.md) for cluster preparation.
