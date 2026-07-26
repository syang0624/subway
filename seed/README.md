# Demo Data Setup (do this BEFORE the event — data seeding, not code)

Everything the demo needs to exist in the real world. Budget ~45 minutes, a few
days before the hackathon so the "idle" clocks are already ticking.

## 1. Push the three seed repos to GitHub

Each subdirectory here (`tasktomo/`, `legacy-api/`, `portfolio-site/`) is the
full content of one seed repo. Create them under the demo GitHub account:

```bash
cd seed/tasktomo
git init && git add -A
git commit -m "tasktomo v0.3.1"
gh repo create syang0624/tasktomo --private --source=. --push
# repeat for portfolio-site
```

**legacy-api must look stale** (the >60-days-idle rule keys off `pushed_at`).
Backdate its commit and don't touch it afterwards:

```bash
cd seed/legacy-api
git init && git add -A
GIT_AUTHOR_DATE="2026-04-28T09:30:00Z" GIT_COMMITTER_DATE="2026-04-28T09:30:00Z" \
  git commit -m "legacy-api maintenance"
gh repo create syang0624/legacy-api --private --source=. --push
```

Note: GitHub's `pushed_at` reflects the actual push time, so the scanner's
staleness rule should read the **latest commit date on the default branch**
(available via the commits API), not `pushed_at`. This is a connector detail —
flag it to whoever writes `fetch_manifests`.

## 2. Supabase projects

1. Create project **`tasktomo-db`** — this is the healthy one. Any region.
2. Create project **`legacy-api-db`** — the pause target. Create it, run one
   trivial query, then leave it alone so it reads as idle.
3. Generate a personal access token: Dashboard → Account → Access Tokens.
4. Put the token and `legacy-api-db`'s project ref into `.env`
   (`SUPABASE_ACCESS_TOKEN`, `SUPABASE_DEMO_PROJECT_REF`).
5. **Dry-run the pause once** and restore, so there are no surprises on stage:

```bash
curl -X POST "https://api.supabase.com/v1/projects/$SUPABASE_DEMO_PROJECT_REF/pause" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
# verify status, then restore:
curl -X POST "https://api.supabase.com/v1/projects/$SUPABASE_DEMO_PROJECT_REF/restore" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
```

(If the account is on the free tier, fixture costs still tell the $25/mo Pro
story — the pause itself is what must be real.)

## 3. Tokens into .env

```bash
cp .env.example .env   # in the repo root, then fill in:
```

- `GITHUB_TOKEN` — fine-grained PAT, Contents:read on the three seed repos
- `SUPABASE_ACCESS_TOKEN` + `SUPABASE_DEMO_PROJECT_REF`
- `OPENAI_API_KEY` (byLLM) and `OPENAI_ADMIN_KEY` (usage API; optional —
  without it the OpenAI card reads from `fixtures/openai_usage.json`)

## 4. Rehearsal

Run the whole flow once with `DEMO_MODE=true` (all fixtures, offline-safe),
then once with `DEMO_MODE=false` (live APIs). Screenshot the successful live
run — that's the stage fallback.

## Demo-day checklist

- [ ] `legacy-api-db` is ACTIVE (restore it if still paused from rehearsal)
- [ ] Tokens in `.env` are valid (GitHub PATs expire!)
- [ ] `jac streamlit frontend/app.jac` boots on the demo laptop
- [ ] Supabase dashboard open in a background tab as live proof
- [ ] Fallback screenshots on the desktop
