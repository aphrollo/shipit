---
name: careful
description: Global safety hook — active in ALL phases, ALL projects. Before executing rm -rf, DROP TABLE, force-push, terraform destroy, or any destructive command — STOP and ask user for confirmation.
---

# Careful — Destructive Command Guard

**Before executing ANY of these, STOP and ask the user for explicit confirmation:**

## Blocked Commands

- `rm -rf` (except: node_modules, .next, dist, __pycache__, build, target, _build, out, coverage, tmp)
- `DROP TABLE`, `TRUNCATE`, `DELETE FROM` (without WHERE) — including via `psql -c`, `mysql -e`, or SQL files
- `git push --force`, `git reset --hard`, `git checkout .`, `git clean -f`, `git stash drop`, `git stash clear`
- `kubectl delete`, `kubectl scale --replicas=0`, `kubectl rollout restart`
- `docker rm -f`, `docker rmi -f`, `docker system prune`
- `terraform destroy`, `aws s3 rm --recursive`
- `chmod -R 777`, `chown -R`
- Overwriting `.env`, `.env.production`, or any credentials/secrets file
- Any command that could destroy data, overwrite history, or affect production

**Never run destructive commands silently. If unsure whether a command is destructive, ask.**
