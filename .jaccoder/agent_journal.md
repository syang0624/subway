## Issues
- [turn 1-3] Port conflicts from zombie Vite/esbuild processes — must kill ALL with `pkill -9 -f "bun.*vite"; pkill -9 -f esbuild` before restart
- [turn 3] `jac retheme --style lyra` creates duplicate `.cl.jac` files alongside existing `.jac` in components/ui/ — causes "Identifier already declared" errors; delete all `.cl.jac` duplicates
- [turn 3] `backend/subway.jac` circular import error — `_manifest_uses` not found during partial init; fell back to stubService
- [turn 4] CSS not rendering despite Vite serving it — `__vite__updateStyle` injection may fail through preview proxy; needs restart from JacHammer UI

## Learnings
- `jac retheme` creates `.cl.jac` duplicates of shadcn components — always check and remove after retheme
- Zombie Vite processes (bun + esbuild) survive `pkill -f "jac start"` — must kill them separately
- `port = 8000` in jac.toml is needed for preview URL to work (maps to port 8000)
- `lib/utils.jac` (not `.cl.jac`) is the correct filename for shadcn's `cn()` utility
- `shadcn = "^3.8.5"` npm package resolves `shadcn/tailwind.css` import in global.css

## Last Action
Server running on port 8000, zero compile errors. App renders all content (header, connect panel, graph placeholder, recommendations). CSS not visually applying — Vite serves it correctly but browser injection fails through preview proxy. Needs JacHammer restart to fix.
