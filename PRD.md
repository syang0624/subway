# PRD: SUBway — Dependency-Aware Subscription Autopilot

**Version:** 1.0 (post-interview) · **Date:** 2026-07-26
**Context:** JacHacks SF 2026 (Founders Inc, Jul 26) · **3-hour build window** · **team of 2** · no code pre-building allowed (data/account seeding is allowed) · **4-minute demo**, scored per `JacHacks_SF_Rubric_HACKERS.pdf`
**Primary language:** Jac ([jaclang.org/docs/latest](https://jaclang.org/docs/latest)) — judges evaluate idiomatic Jac usage (nodes/edges/walkers/byLLM). **Both backend AND frontend are written in Jac** using Jac's full-stack client/server model: UI components in `.cl.jac` files (JSX-in-Jac, shadcn components), server services in `.sv.jac` files, served together by `jac start main.jac`. No hand-written HTML/JS/Python anywhere in the stack.

---

## 1. Product Statement

SUBway is a subscription manager that understands **what each subscription powers**. It scans your GitHub repos to auto-build a dependency graph (Project → Service), detects waste (idle projects, oversized plans, mismatched models), explains what's safe to change and why, and — with one click of approval — **actually executes** the change via the provider's API and verifies the result.

The one question competitors can't answer, SUBway answers first:
> *"What breaks if I downgrade this?"*

## 2. What We Are NOT Building (3-hour reality)

- ❌ Any hand-written non-Jac application code (the UI is Jac JSX compiled by Jac's full-stack client runtime)
- ❌ Real OAuth (tokens come from config behind "Connect" buttons)
- ❌ Full repo cloning/grepping (shallow GitHub API manifest scan only)
- ❌ Rollback walker (undo = restore in Supabase dashboard)
- ❌ Teams, multi-user, billing/invoice ingestion, policies
- ❌ Vercel/AWS/consumer connectors (future-work slide only)

## 3. Demo Script (the contract for scope — 4:00 hard limit)

0. *(0:00–0:25)* **Name one person and one fear:** "Steven is an indie developer with three side projects. He pays $172 every month, but he cannot tell which subscription is safe to touch—so he keeps paying for all of them."
1. *(0:25–0:55)* Open SUBway and click **Map Steven's stack**. Do not narrate the implementation yet. Let the UI show `discover_stack → analyze → byLLM`, three connected evidence sources, and the 13-node/11-edge result.
2. *(0:55–1:45)* **★ WOW MOMENT:** point to the highlighted impact trace: `legacy-api → legacy-api-db → Supabase Pro`. Ask the product's question out loud: **"What breaks if we pause this?"** Answer from the graph: one stale project, zero production dependers, reversible in one click.
3. *(1:45–2:30)* Show the recommendation evidence: 47 idle days, 89 days since the only depender changed, 2% CPU, 87 MB database. Explain the division of labor: deterministic Jac rules choose the action; byLLM only turns those facts into concise safety language.
4. *(2:30–3:15)* Click **Approve, execute, and verify**. The `execute_action` walker calls `POST /v1/projects/{ref}/pause`; `verify_action` checks the provider state. Hold on the green **Supabase confirmed PAUSED** state and the spend change `$172 → $147`.
5. *(3:15–3:40)* Point to the second controlled move: right-size TaskTomo's model for another $30/month. The optimized target is **$117/month, a 32% reduction / $660 per year**.
6. *(3:40–4:00)* **Show where Jac runs:** flash `backend/subway.jac` at the node/edge declarations, `discover_stack`, `analyze`, `execute_action`, `verify_action`, and the byLLM `explain` ability. Then flash `components/SubwayDashboard.cl.jac`: the UI itself is Jac. Close with: **"The graph is the decision engine, not a visualization layer."**

**Fallback:** if live execution misbehaves on stage, the graph + recommendations + reasoning still carry the demo (per priority decision: the auto-built graph is the must-not-lose moment; execution is the encore).

## 4. Pre-Event Preparation (rule-legal: data, not code)

**All demo data lives in this repo** — `seed/` holds the three seed repos' full contents plus step-by-step setup in `seed/README.md`; `fixtures/` holds the fallback/rehearsal dataset (also the source of truth for the `get_graph` / `get_recommendations` report shapes); `.env.example` lists every credential needed (copy to gitignored `.env`).

| Item | Detail |
|---|---|
| Seed repos | Push `seed/tasktomo`, `seed/legacy-api` (backdated commit → stale), `seed/portfolio-site` to GitHub per `seed/README.md`. Manifests reference `@supabase/supabase-js`, `openai`, `supabase` so the scanner finds real edges. |
| Supabase | Create `tasktomo-db` (healthy) and `legacy-api-db` (left idle — the pause target). Confirm the Management API token can pause/restore it. **Dry-run pause+restore once before the event** (curl commands in `seed/README.md`). |
| Tokens | Fill `.env` from `.env.example`: GitHub PAT (repo read), Supabase access token + demo project ref, OpenAI key (byLLM) and optional admin key (usage API — falls back to fixtures without it). `.env` is gitignored. |
| Rehearsal | Full flow once with `DEMO_MODE=true` (fixtures, offline-safe) and once live; screenshot the live run as the stage fallback. |
| Env check | Install Jac dependencies with `jac install` on both laptops, run `jac check main.jac`, and boot the full-stack app once. Skim [jaclang.org/docs/latest](https://jaclang.org/docs/latest) for current node/edge/walker, full-stack client, and byLLM syntax. |

## 5. Architecture

```
 main.jac                          — app entry + router (`jac start main.jac`)
 components/SubwayDashboard.cl.jac — Jac client UI: connect panel, layered
 │   dependency graph, recommendation cards, approve buttons, savings header
 │        `sv import` calls server functions directly (typed, no REST glue)
 ▼
 services/subway.sv.jac            — typed façade: spawns walkers, returns the
 │   agreed shapes (stubService.sv.jac kept as offline fallback reference)
 services/connectors.sv.jac        — Steven's HTTP connectors (GitHub, Supabase
 │   Management API, OpenAI costs) with DEMO_MODE + fixture fallback
 ▼
 backend/subway.jac                — Noriaki's graph + walkers (INTEGRATED):
       Graph: Account ─owns→ Project ─uses→ Service ─billed_as→ Subscription
              RecommendationRecord ─targets→ Service
       Walkers: connect_accounts · discover_stack ★ · analyze · get_graph ·
                get_recommendations · approve_action → execute_action →
                verify_action (live status polling) · explain (byLLM, rules decide)
       Tests: backend/subway.test.jac (jac test)
```

The client imports server functions via `sv import` with the same names/shapes as the stub, so swapping in Noriaki's walker-backed module changes zero UI code. The dependency graph renders as typed layers (Accounts → Projects → Services → Subscriptions) with edge-type labels between them. The UI gates the graph behind connecting all three accounts — the connect → scan → graph-materializes beat is the demo's wow moment.

**Graph schema (trimmed from idea.md's 12 nodes to 5):**

- **Nodes:** `Account` (github/supabase/openai), `Project` (a repo), `Service` (a provider resource, e.g. a Supabase project, OpenAI API), `Subscription` (plan + monthly cost), `Recommendation` (type, savings, risk notes, status: proposed→approved→executed→verified)
- **Edges:** `owns` (Account→Project), `uses` (Project→Service), `billed_as` (Service→Subscription), `targets` (Recommendation→Service)

**Detection rules (deterministic — byLLM explains, rules decide):**

- Manifest contains `supabase` dep or `SUPABASE_URL` in `.env.example` → `uses` edge to Supabase service; same pattern for `openai`.
- Supabase project with no recent activity (API-reported status/last usage) → **pause recommendation**.
- Repo default branch with no commits in 60+ days but outgoing `uses` edges → **unused-subscription flag**.
- OpenAI usage dominated by an expensive model at low volume → **model right-sizing** (advisory; savings estimated from public per-token pricing).

## 6. Team Split & Hour-by-Hour Plan

**Noriaki — backend:** graph schema, all walkers, byLLM explain ability, execution/verify logic — delivered as a `.sv.jac` module exposing the same functions as `services/stubService.sv.jac`.
**Steven — frontend + connectors (`components/SubwayDashboard.cl.jac`, `services/connectors.sv.jac`):** the Jac client UI (connect panel, graph view, recommendation cards, approve buttons) plus the GitHub/Supabase/OpenAI HTTP connector functions — all written in Jac.

**Collaboration contract (agree in the first 15 minutes, then work independently):**
- The **walker interface is the contract**: agree on walker names + the shape each reports — the exact shapes are already written down in `fixtures/graph.json` (`get_graph`) and `fixtures/recommendations.json` (`get_recommendations`); `approve_action(rec_id)` reports the new status. Steven builds the UI against a stub module that reports the fixtures verbatim; swap in Noriaki's real module at integration — same names, zero UI changes.
- The **connector functions are the second interface**: Steven writes `fetch_manifests(repo)`, `pause_project(ref)`, `get_project_status(ref)`, `get_openai_usage()` in `backend/connectors.jac`; Noriaki imports them inside walkers. Signatures agreed up front, bodies filled in later.
- One git repo with backend ownership in `backend/` and client ownership in `components/`/`services/` — near-zero merge conflicts. Commit small and often; integrate at 2:30, not earlier if things are flowing.

| Time | Noriaki (backend Jac) | Steven (frontend Jac + connectors) |
|---|---|---|
| 0:00–0:30 | Schema (nodes/edges) + `connect_accounts`; `get_graph` walker reports a hardcoded graph | Jac client hello + layout shell; prove GitHub manifest fetch + Supabase pause with curl |
| 0:30–1:15 | `discover_stack` walker consuming Steven's connector functions → real graph | Graph view rendering from the typed `get_graph` report ★ |
| 1:15–2:00 | `analyze` rules + `Recommendation` nodes + byLLM `explain` | Recommendation cards + Approve button spawning `approve_action` |
| 2:00–2:30 | `approve_action` → `execute_action` (real pause) → `verify_action` | Savings header, card status transitions, polish |
| 2:30–3:00 | **Integration (swap stub → real module) + full demo run-through ×2** | Same + fallback screenshots of a successful run |

The entire stack is Jac, so both names appear throughout the judged surface — Noriaki in the graph/walkers, Steven in the Jac client UI and connectors.

**Cut lines, in order, when behind:** (1) drop OpenAI right-sizing card → hardcode its numbers; (2) drop byLLM explain → template strings; (3) drop verify walker → optimistic UI + show Supabase dashboard; (4) drop connect buttons → start pre-connected. **Never cut:** discover_stack → live graph render.

## 6.5 Rubric Alignment (how we score)

| Criterion | Weight | Our play |
|---|---|---|
| Use of Jac | **40%** | Target 5/5 "CENTRAL" — the rubric's own words ("walkers, graph traversal, byLLM, agentic flows") describe our stack literally: graph traversal IS the product insight (dependency-aware recommendations), walkers orchestrate discover→analyze→execute→verify, byLLM writes safety reasoning, and even the UI is Jac. Highest score here also wins **Best JacHammer**. |
| Real-World Use Case | 20% | Named person, not a market: an indie dev with side projects bleeding subscription money, afraid to downgrade. Open the demo with him. |
| Technical Execution | 20% | The hard part genuinely done: live GitHub scanning → auto-built graph + one real Supabase API execution round-trip. Not scaffolding. |
| Demo & Story | 20% | Core flow runs end-to-end live in 4:00 (rubric: "run it, don't describe it"). Fixtures + rehearsal protect against stage failures. |

**Rubric floor:** a 3+ on Use of Jac is mandatory to qualify for anything — one more reason the all-Jac decision is right, and why the cut lines never touch walker logic.

## 7. Success Criteria

- Graph auto-builds from live GitHub API data in front of judges (no manual edges).
- ≥3 recommendation cards with dollar savings and plain-English safety reasoning.
- One real, verifiable API execution (Supabase pause) round-trips during the demo.
- The whole application stack — graph, walkers, connectors, and client UI — is authored in Jac; there is no hand-written Python, JavaScript, or HTML application layer.

## 8. Risks

| Risk | Mitigation |
|---|---|
| Jac syntax drift vs our memory of it | Verify against jaclang.org/docs/latest at coding time; hello-world before the event |
| Jac client/runtime drift or persisted rehearsal state | Run `jac check`, clear only local demo graph data with `jac clean --data --force`, then rehearse the browser flow from a clean start |
| Supabase pause slow/fails live | Dry-run pre-event; verify walker polls; fallback = dashboard screenshot |
| GitHub rate limits / API hiccups | PAT-authenticated requests; scan only the 3 seed repos |
| OpenAI usage API needs admin key | Confirm key scope pre-event; else hardcode usage numbers (advisory card anyway) |
| jac-cloud auth friction on endpoints | Establish token/endpoint pattern in the first 30 min while stakes are low |

## 9. Future Work (pitch slide, not build)

More executable connectors (Vercel, AWS, GitHub seats), rollback walker, policy nodes ("never touch prod"), scheduled re-scans, consumer subscriptions (advisory), Slack approvals.
