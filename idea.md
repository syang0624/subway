# Project: SUBway (Working Title)

## One-line Pitch

A dependency-aware subscription autopilot for developers. Instead of
only tracking subscriptions, SUBway understands what every
subscription powers, recommends the safest way to reduce costs, and can
execute supported changes with approval.

------------------------------------------------------------------------

# Problem

Developers and startups quickly accumulate subscriptions:

-   Supabase
-   OpenAI API
-   GitHub Copilot
-   Vercel
-   AWS
-   Monitoring tools
-   Analytics
-   Email providers

Current products answer:

-   What am I paying for?
-   Which subscriptions exist?
-   Which employees have licenses?

They do **not** answer:

> What will break if I downgrade this subscription?

------------------------------------------------------------------------

# Solution

Build a graph of:

User → Team → Project → Subscription → Resources → Features → Usage →
Cost

The AI traverses this graph before making recommendations.

Example:

TaskTomo ├── GitHub Repository ├── Supabase Database ├── OpenAI API └──
Vercel

Instead of saying:

"Downgrade Supabase."

It says:

"Downgrade Supabase from Small → Micro.

✓ Saves \$20/month ✓ CPU usage only 18% ✓ Database size fits ✓ All
required features remain available ✓ Only development environment
affected"

------------------------------------------------------------------------

# Why Jac?

Jac is graph-native.

Perfect for representing:

Project → Resource → Subscription → Usage → Cost → Recommendation

Walkers naturally traverse dependency graphs and orchestrate multiple
agents.

Suggested walkers:

-   discover_stack
-   sync_usage
-   map_dependencies
-   optimize_portfolio
-   trace_change_impact
-   request_approval
-   execute_action
-   verify_action
-   rollback_action

------------------------------------------------------------------------

# Hackathon MVP

Connect only:

1.  Supabase
2.  GitHub
3.  OpenAI API

Flow:

1.  Connect accounts
2.  Import projects
3.  Build dependency graph
4.  Analyze usage
5.  Generate recommendations
6.  User approves
7.  Execute supported API action
8.  Verify result

------------------------------------------------------------------------

# Demo

1.  User connects GitHub, Supabase, OpenAI.
2.  Graph appears automatically.
3.  AI detects an inactive project.
4.  Finds oversized Supabase compute.
5.  Shows affected projects and risks.
6.  User approves resize.
7.  API executes.
8.  Dashboard confirms savings.

------------------------------------------------------------------------

# Architecture

``` text
          GitHub
             │
             │
         OpenAI API
             │
             │
         Supabase
             │
             ▼
      Connector Layer
             │
             ▼
        Jac Graph Model
             │
   ┌─────────┼──────────┐
   ▼         ▼          ▼
 Usage    Dependency   Billing
 Agent      Agent       Agent
   │         │          │
   └─────────┼──────────┘
             ▼
      Optimization Engine
             │
             ▼
      Recommendation Agent
             │
             ▼
      Approval / Execution
             │
             ▼
        Verification
```

------------------------------------------------------------------------

# Graph Schema

Nodes

-   User
-   Team
-   Project
-   Subscription
-   Plan
-   Feature
-   Resource
-   UsageSnapshot
-   Invoice
-   Policy
-   Recommendation
-   Action

Edges

-   OWNS
-   PAYS_FOR
-   USES
-   REQUIRES
-   PROVIDES
-   CONTAINS
-   GENERATES
-   IMPACTS
-   IMPLEMENTS

------------------------------------------------------------------------

# Multi-Agent Roles

## Discovery Agent

Imports projects and services.

## Usage Agent

Collects metrics and costs.

## Dependency Agent

Maps project relationships.

## Optimizer Agent

Calculates cheapest safe configuration.

## Recommendation Agent

Explains savings and risks.

## Execution Agent

Calls supported APIs.

## Verification Agent

Confirms success and measures savings.

------------------------------------------------------------------------

# Differentiation

Existing products:

Rocket Money - Finds subscriptions

Zylo - Manages enterprise licenses

CloudZero - Optimizes cloud spend

SUBway:

✓ Understands project dependencies ✓ Knows what breaks before changing
plans ✓ Optimizes across multiple developer services ✓ Executes
supported changes ✓ Verifies savings afterwards

------------------------------------------------------------------------

# Future Integrations

-   Vercel
-   AWS
-   Cloudflare
-   Stripe
-   Neon
-   Railway
-   Resend
-   Anthropic
-   Gemini
-   Cursor
-   Slack

Consumer connectors (recommendation only):

-   Netflix
-   Spotify
-   ChatGPT
-   Amazon Prime

------------------------------------------------------------------------

# Team Split

Backend - Jac graph - Walkers - Optimization engine

Frontend - Dashboard - Graph visualization - Recommendation cards

Integrations - GitHub API - Supabase API - OpenAI Usage API

AI - Explanation agent - Feature mapping - Recommendation generation

------------------------------------------------------------------------

# Elevator Pitch

"SUBway is a dependency-aware subscription autopilot for developers.
Unlike traditional subscription managers that only track recurring
charges, SUBway understands which projects depend on every paid
service. Using Jac's graph-native architecture, it safely recommends and
executes subscription optimizations while showing exactly what will be
affected before any change is made."
