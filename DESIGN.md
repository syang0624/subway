# Design

## Source of truth

- Status: Active
- Last refreshed: 2026-07-26
- Primary product surfaces: Single-page demo dashboard at `/`
- Evidence reviewed: `PRD.md`, `JacHacks_SF_Rubric_HACKERS.md`, `README.md`, `idea.md`, `components/SubwayDashboard.cl.jac`, `styles/global.css`, `fixtures/graph.json`, `fixtures/recommendations.json`, and `.jaccoder/screenshots/`

## Brand

- Personality: Precise, calm, technical, and financially sharp.
- Trust signals: Source labels, explicit dependency paths, reversible-action language, affected-project counts, provider verification, and visible Jac walker stages.
- Avoid: Generic “AI dashboard” language, unexplained scores, fear-based warnings, decorative charts, and claims that fixture data is live.

## Product goals

- Goals: Answer “What breaks if I downgrade this?”, reveal waste in under one minute, and safely execute one verified provider action.
- Non-goals: Full billing ingestion, autonomous deletion, consumer subscription tracking, OAuth, or broad cloud coverage.
- Success signals: A judge can name the user, explain the graph insight, see a recommendation’s evidence, witness an action complete, and identify where Jac is central.

## Personas and jobs

- Primary persona: Steven, an indie developer maintaining three side projects and paying $172/month across GitHub, Supabase, and OpenAI.
- User jobs: Understand which projects rely on each paid service; find safe savings; act without breaking production; retain evidence for each decision.
- Key contexts of use: A fast cost review, a monthly cleanup, or a live hackathon demonstration.

## Information architecture

- Primary navigation: One guided workspace rather than multiple routes.
- Core states: Before scan → scanning → dependency intelligence → execute/verify success.
- Content hierarchy: User problem and primary action → savings brief → highlighted impact path → Jac reasoning trace → full graph → remaining recommendations.

## Design principles

- Make the graph answer a human question: Every graph view must expose impact, not merely node counts.
- Evidence before automation: Show affected projects, activity, reversibility, and source before the execute button.
- Make Jac visible: Name the walker or byLLM stage beside the value it creates.
- Optimize for the four-minute demo: One primary scan action, one highlighted executable recommendation, and one unambiguous verified state.
- Tradeoffs: Prefer a curated, legible dependency path over a dense general-purpose graph visualization.

## Visual language

- Color: Indigo primary for intelligence and action; emerald for verified savings; amber for stale/idle evidence; neutral zinc surfaces.
- Typography: Inter Variable with high-contrast numeric spend and savings.
- Spacing/layout rhythm: 4/6/8 spacing cadence, wide desktop canvas, compact evidence rows.
- Shape/radius/elevation: Medium radii, thin borders, restrained rings, no heavy shadows.
- Motion: Functional status motion only. Active agent nodes pulse, handoffs signal, and progress tracks move; every loop stops when evidence is ready and honors `prefers-reduced-motion`.
- Imagery/iconography: Hugeicons line icons and compact provider initials; no stock imagery.

## Components

- Existing components to reuse: Button, Card, Badge, Separator, Spinner, and Hugeicons.
- New/changed components: Demo hero, scan pipeline, animated agent workspace, optimization brief, impact path, Jac reasoning trace, focused recommendation, compact graph layer, and verified success state.
- Variants and states: Fixture/live source, disconnected/connected, scanning/ready, advisory/executable, proposed/executed/verified.
- Token/component ownership: `styles/global.css` owns semantic tokens; `components/ui/` remains registry-managed; composite behavior stays in `components/SubwayDashboard.cl.jac`.

## Accessibility

- Target standard: WCAG 2.1 AA for the demo surface.
- Keyboard/focus behavior: All actions are native buttons with visible focus treatment.
- Contrast/readability: Semantic foreground tokens; amber is paired with text, never used as the only signal.
- Screen-reader semantics: Ordered headings, native buttons, status text, and descriptive labels.
- Reduced motion and sensory considerations: No required motion or color-only meaning.

## Responsive behavior

- Supported breakpoints/devices: Desktop stage display first; functional tablet and mobile layouts.
- Layout adaptations: Multi-column hero, impact path, stats, and recommendations collapse to single columns.
- Touch/hover differences: No hover-only information or precision-only interactions.

## Interaction states

- Loading: Show the Jac pipeline stages and the exact work being performed.
- Empty: Explain the user problem and offer one primary “Map dependencies” action.
- Error: Preserve the error message and keep the scan action available.
- Success: Show provider verification, updated monthly spend, and realized savings.
- Disabled: Busy actions retain descriptive progress copy.
- Offline/slow network: Clearly label fixture fallback and keep the end-to-end demo operable.

## Content voice

- Tone: Direct, evidence-led, and concise.
- Terminology: “Dependency map,” “affected project,” “safe to pause,” “execute and verify,” and “potential savings.”
- Microcopy rules: Lead with the consequence or proof; avoid vague “AI-powered” claims; distinguish deterministic rules from byLLM explanations.

## Implementation constraints

- Framework/styling system: Jac 0.34.7 full-stack client/server, Jac JSX, Tailwind v4, and jac-shadcn primitives.
- Design-token constraints: Use semantic tokens except for small graph-category accents.
- Performance constraints: Keep the initial bundle and scan state lightweight; no new dependencies.
- Compatibility constraints: Preserve `DEMO_MODE=true`, typed `sv import` boundaries, and the existing walker-backed service API.
- Test/screenshot expectations: `jac check main.jac`, `jac test backend/subway.jac`, then browser verification at desktop and narrow viewport.

## Open questions

- [ ] Confirm the live stage account name and replace the seeded “Steven” copy if another presenter persona is preferred / team / affects spoken demo only.
- [ ] Confirm whether the live Supabase project can be safely paused on stage / team / determines live versus fixture source badge.
