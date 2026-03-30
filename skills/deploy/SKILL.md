---
name: deploy
description: Post-merge deployment automation — detect platform, deploy, monitor, revert if needed. Supports Fly.io, Render, Vercel, Netlify, Heroku, Railway, Docker, and GitHub Actions.
---

# Deploy — Platform-Aware Deployment

**Merge the PR, deploy to the detected platform, monitor health, offer revert if anything breaks.**

## When to Use

- After `/review` passes and code is ready to ship
- After `/ship` completes pre-flight checks
- When user says "deploy" or "push to production"

## Step 1: Detect Platform

Check for platform indicators in order:

| Platform | Detection |
|----------|-----------|
| Fly.io | `fly.toml` exists |
| Render | `render.yaml` exists |
| Vercel | `vercel.json` or `.vercel/` exists |
| Netlify | `netlify.toml` or `_redirects` exists |
| Heroku | `Procfile` exists |
| Railway | `railway.json` or `railway.toml` exists |
| Docker | `Dockerfile` or `docker-compose.yml` exists |
| GitHub Actions | `.github/workflows/deploy*.yml` exists |
| Custom | Check CLAUDE.md for `## Deploy Configuration` section |

If multiple detected, ask user which to use.
If none detected, ask user for deploy instructions and offer to save them to CLAUDE.md.

## Step 2: Pre-Deploy Gate

Before deploying:
1. Verify all tests pass (refuse if they don't)
2. Check git status is clean (no uncommitted changes)
3. Verify on correct branch (main/master or release branch)
4. Confirm with user: "Ready to deploy to [platform]. Proceed?"

## Step 3: Deploy

Execute platform-specific deploy command:

| Platform | Command |
|----------|---------|
| Fly.io | `fly deploy` |
| Render | `git push` (auto-deploys) or Render API |
| Vercel | `vercel --prod` |
| Netlify | `netlify deploy --prod` |
| Heroku | `git push heroku main` |
| Railway | `railway up` |
| Docker | `docker compose up -d --build` |
| GitHub Actions | `git push` (triggers workflow) |

## Step 4: Health Check

After deploy completes:
1. Wait 10-30 seconds for service to stabilize
2. Hit the health check URL (from CLAUDE.md or auto-detect from platform config)
3. Check for HTTP 200 response
4. If `/canary` is available, suggest running it for extended monitoring

## Step 5: Revert Option

If health check fails:
- Show the error
- Offer: "Deploy appears unhealthy. Revert to previous version?"
- If user confirms, execute platform-specific rollback:
  - Fly.io: `fly releases` then `fly deploy --image [previous]`
  - Vercel: `vercel rollback`
  - Heroku: `heroku rollback`
  - Docker: `docker compose down && git checkout HEAD~1 -- docker-compose.yml && docker compose up -d`
  - Others: `git revert HEAD && git push`

## Rules

- NEVER deploy without user confirmation
- NEVER auto-rollback without user confirmation
- Always run health check after deploy
- If this is the first deploy, run in "teacher mode" — explain each step before executing
- Save successful deploy configuration to CLAUDE.md for future runs
- Dev before prod when both environments exist
