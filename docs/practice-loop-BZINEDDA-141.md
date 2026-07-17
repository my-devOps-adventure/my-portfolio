# Practice Loop: BZINEDDA-141

Story: **Deploy to K3s staging**

Epic: Portfolio Website

## Completed

- [x] K3s cluster running locally with Traefik ingress
- [x] Staging manifests in `k8s/staging`
- [x] GitHub environment `staging` with kubeconfig and GHCR secrets
- [x] Repository self-hosted runner on the K3s host
- [x] **Publish Image** pushes to `ghcr.io/my-devops-adventure/portfolio:latest`
- [x] **Deploy Staging** rollout succeeds on K3s
- [x] Helper scripts and lessons documented

Full post-mortem: [lessons-BZINEDDA-141-k3s-staging.md](./lessons-BZINEDDA-141-k3s-staging.md)

## Verification Checklist

- [ ] Jira BZINEDDA-141 shows linked commits/PR/builds
- [ ] GitHub Actions **Deploy Staging** green on `main`
- [ ] `kubectl get pods -n portfolio-staging` — all `Running`
- [ ] `curl http://portfolio.local/healthz` returns OK
- [ ] Move story to **Done** in Jira

## Key Commands

```bash
kubectl get pods,ingress -n portfolio-staging
curl -s http://portfolio.local/healthz
./scripts/restart-github-runner.sh    # if deploy jobs queue
```

## Next Stories

Continue the same loop for new features. See README **Next Learning Goals**.
