## Issues
- [turn 1] `@vitejs/plugin-react@6.0.4` incompatible with Vite 6.x — pinned to `^4.3.4`
- [turn 1] Shadcn npm deps (hugeicons, radix-ui, clsx, etc.) not auto-added by `jac install --shadcn` — added manually to jac.toml
- [turn 1] `tw-animate-css` and `@fontsource-variable/inter` missing — added to [dependencies.npm]
- [turn 1] `shadcn/tailwind.css` virtual import in global.css unresolvable when `[client.vite]` overrides default Vite config — removed `[client.vite]` section and removed the import from global.css
- [turn 1] Port conflicts: multiple jac start processes fighting over port 8000; fix = kill all with `pkill -9 -f "jac start"; pkill -9 -f "vite"` and let supervisor restart
- [turn 1] Docstrings inside function bodies cause parse errors (E0002) — must go before the def, not inside the body
- [turn 1] `node` is a reserved keyword — renamed parameter to `gnode`

## Learnings
- `jac install --shadcn` does NOT add npm peer deps to jac.toml — must add manually: @hugeicons/react, @hugeicons/core-free-icons, class-variance-authority, radix-ui, clsx, tailwind-merge, tw-animate-css, @fontsource-variable/inter
- `[client.vite]` section overrides the jac runtime's default Vite config (which includes shadcn virtual module support) — only add it when you need extra plugins beyond what jac provides
- `shadcn/tailwind.css` in global.css is a virtual module from jac runtime; removing `[client.vite]` restores it, OR just delete the import (CSS vars are already in global.css)
- Supervisor runs `jac start main.jac -p 8000 --dev` from /app; leftover Vite processes block port 8000 — kill all with pkill -9
- `[plugins.client.vite]` is old format; `[client.vite]` is current — but both can interfere with jac-shadcn virtual modules

## Last Action
Built Steven's part of SUBway: services/stubService.sv.jac (fixture data), services/connectors.sv.jac (HTTP connectors), components/SubwayDashboard.cl.jac (full UI), main.jac (router). App renders at preview URL with header ($172/mo), connect panel, dependency graph (13 nodes, 11 edges), and 3 recommendation cards with Approve button. Core flow (Approve → status update) is wired but not visually confirmed due to scroll position. Noriaki's real backend walkers can be swapped in by replacing stubService.sv.jac.
