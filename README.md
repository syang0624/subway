# SUBway

SUBway is a dependency-aware subscription manager built entirely in
[Jac](https://docs.jaseci.org/). It scans developer repositories, builds a
Project → Service → Subscription graph, recommends cost reductions, and can
execute and verify approved Supabase actions.

The central question SUBway answers is:

> What breaks if I downgrade this subscription?

## Features

- Builds a dependency graph from GitHub repository manifests.
- Detects Supabase and OpenAI usage from dependencies and environment variables.
- Flags idle services, stale projects, and model right-sizing opportunities.
- Uses Jac `by llm()` to explain deterministic recommendations.
- Executes Supabase project pauses through the Management API.
- Polls the provider to verify that an approved action completed.
- Falls back to labeled fixtures for reliable offline demos.

## Architecture

```text
main.jac
└── components/SubwayDashboard.cl.jac
    └── services/subway.sv.jac
        ├── backend/subway.jac
        │   ├── nodes and typed edges
        │   ├── discovery and analysis walkers
        │   ├── byLLM explanations
        │   └── approve, execute, and verify walkers
        └── services/connectors.sv.jac
            ├── GitHub API
            ├── Supabase Management API
            └── OpenAI usage API
```

The graph model includes:

- Nodes: `Account`, `Project`, `Service`, `Subscription`, and
  `RecommendationRecord`
- Edges: `owns`, `uses`, `billed_as`, and `targets`
- Walkers: `connect_accounts`, `discover_stack`, `analyze`, `get_graph`,
  `get_recommendations`, `approve_action`, `execute_action`, and
  `verify_action`

## Requirements

- Jac 0.34.7 or a compatible newer release
- GitHub, Supabase, and OpenAI credentials for live mode
- Graphviz if you want to inspect the graph with `jac dot`

Install Jac using the current
[official installation instructions](https://docs.jaseci.org/getting-started/installation/).

## Setup

Clone the repository and enter the project:

```bash
git clone https://github.com/syang0624/subway.git
cd subway
```

Create the local environment file:

```bash
cp .env.example .env
```

Install the project dependencies:

```bash
jac install
```

## Configuration

The following variables are documented in `.env.example`:

| Variable | Purpose |
| --- | --- |
| `GITHUB_TOKEN` | Reads repository metadata and manifests |
| `GITHUB_USERNAME` | Selects the GitHub account to scan |
| `SUPABASE_ACCESS_TOKEN` | Lists, pauses, and verifies Supabase projects |
| `SUPABASE_DEMO_PROJECT_REF` | Identifies the idle project used in the demo |
| `OPENAI_API_KEY` | Powers `by llm()` explanations |
| `OPENAI_ADMIN_KEY` | Reads organization usage data when available |
| `DEMO_MODE` | Uses deterministic fixtures when set to `true` |

Never commit `.env` or real credentials.

## Run

Start the development server:

```bash
jac dev
```

Then open the local URL printed by Jac. Connect all three providers in the UI
to trigger repository discovery, graph construction, and recommendation
analysis.

For a deterministic offline run:

```bash
jac clean --data --force
DEMO_MODE=true jac dev
```

The clean step resets only the local persisted demo graph so every rehearsal
starts with proposed recommendations and an active pause target.

## Validation

Run the compiler and targeted backend tests:

```bash
jac check main.jac
jac test backend/subway.jac
```

Optional graph inspection:

```bash
jac dot backend/subway.jac
```

## Demo Data

- `fixtures/` contains deterministic API fallback data.
- `seed/` contains the repositories used by the hackathon demo.
- `PRD.md` describes the product contract, demo flow, and team ownership.

Fixture-backed data is explicitly labeled in the UI so it is not mistaken for
a successful live API scan.

## Safety

- Recommendations are selected by deterministic rules; the LLM only explains
  their safety and impact.
- Live Supabase execution is blocked when the project reference is still a
  placeholder.
- Verification uses bounded polling instead of assuming that an accepted API
  request completed.
- The overlapping pause and cancellation recommendations are counted only once
  in projected savings.
