"""Stub service: returns fixture data for the SUBway demo.
Steven's UI is built against these shapes; Noriaki swaps in real walkers at integration.
"""

obj GraphNode {
    has id: str = "";
    has node_type: str = "";
    has label: str = "";
    has provider: str = "";
    has last_pushed: str = "";
    has stale: bool = False;
    has status: str = "";
    has idle_days: int = 0;
    has monthly_cost_usd: int = 0;
}

obj GraphEdge {
    has from_id: str = "";
    has to_id: str = "";
    has edge_type: str = "";
}

obj GraphData {
    has nodes: list[GraphNode] = [];
    has edges: list[GraphEdge] = [];
    has total_monthly_cost_usd: int = 172;
}

obj SafetyCheck {
    has text: str = "";
}

obj RecommendationAction {
    has api: str = "";
    has call: str = "";
    has manual_steps: str = "";
}

obj Recommendation {
    has id: str = "";
    has rec_type: str = "";
    has executable: bool = False;
    has title: str = "";
    has target_service: str = "";
    has affected_projects: list[str] = [];
    has monthly_savings_usd: int = 0;
    has status: str = "proposed";
    has safety_checks: list[str] = [];
    has note: str = "";
}

obj RecommendationsData {
    has recommendations: list[Recommendation] = [];
}

obj ApproveResult {
    has id: str = "";
    has status: str = "";
    has message: str = "";
}

def:pub get_graph() -> GraphData {
    nodes: list[GraphNode] = [
        GraphNode(id="acct:github", node_type="Account", label="GitHub (syang0624)", provider="github"),
        GraphNode(id="acct:supabase", node_type="Account", label="Supabase", provider="supabase"),
        GraphNode(id="acct:openai", node_type="Account", label="OpenAI", provider="openai"),
        GraphNode(id="proj:tasktomo", node_type="Project", label="tasktomo", last_pushed="2026-07-24", stale=False),
        GraphNode(id="proj:legacy-api", node_type="Project", label="legacy-api", last_pushed="2026-04-28", stale=True),
        GraphNode(id="proj:portfolio-site", node_type="Project", label="portfolio-site", last_pushed="2026-07-10", stale=False),
        GraphNode(id="svc:supabase:tasktomo-db", node_type="Service", label="tasktomo-db", provider="supabase", status="ACTIVE_HEALTHY"),
        GraphNode(id="svc:supabase:legacy-api-db", node_type="Service", label="legacy-api-db", provider="supabase", status="ACTIVE_HEALTHY", idle_days=47),
        GraphNode(id="svc:openai:api", node_type="Service", label="OpenAI API", provider="openai", status="active"),
        GraphNode(id="sub:supabase-pro-tasktomo", node_type="Subscription", label="Supabase Pro", monthly_cost_usd=25),
        GraphNode(id="sub:supabase-pro-legacy", node_type="Subscription", label="Supabase Pro", monthly_cost_usd=25),
        GraphNode(id="sub:openai-usage", node_type="Subscription", label="OpenAI usage", monthly_cost_usd=118),
        GraphNode(id="sub:github-pro", node_type="Subscription", label="GitHub Pro", monthly_cost_usd=4)
    ];
    edges: list[GraphEdge] = [
        GraphEdge(from_id="acct:github", to_id="proj:tasktomo", edge_type="owns"),
        GraphEdge(from_id="acct:github", to_id="proj:legacy-api", edge_type="owns"),
        GraphEdge(from_id="acct:github", to_id="proj:portfolio-site", edge_type="owns"),
        GraphEdge(from_id="proj:tasktomo", to_id="svc:supabase:tasktomo-db", edge_type="uses"),
        GraphEdge(from_id="proj:tasktomo", to_id="svc:openai:api", edge_type="uses"),
        GraphEdge(from_id="proj:legacy-api", to_id="svc:supabase:legacy-api-db", edge_type="uses"),
        GraphEdge(from_id="proj:portfolio-site", to_id="svc:openai:api", edge_type="uses"),
        GraphEdge(from_id="svc:supabase:tasktomo-db", to_id="sub:supabase-pro-tasktomo", edge_type="billed_as"),
        GraphEdge(from_id="svc:supabase:legacy-api-db", to_id="sub:supabase-pro-legacy", edge_type="billed_as"),
        GraphEdge(from_id="svc:openai:api", to_id="sub:openai-usage", edge_type="billed_as"),
        GraphEdge(from_id="acct:github", to_id="sub:github-pro", edge_type="billed_as")
    ];
    return GraphData(nodes=nodes, edges=edges, total_monthly_cost_usd=172);
}

def:pub get_recommendations() -> RecommendationsData {
    recs: list[Recommendation] = [
        Recommendation(
            id="rec-001",
            rec_type="supabase_pause",
            executable=True,
            title="Pause idle Supabase project legacy-api-db",
            target_service="svc:supabase:legacy-api-db",
            affected_projects=["proj:legacy-api"],
            monthly_savings_usd=25,
            status="proposed",
            safety_checks=[
                "Last database activity 47 days ago",
                "Only depender is legacy-api, itself untouched since 2026-04-28",
                "CPU utilization 2%, database 87 MB",
                "Pause is reversible from the Supabase dashboard in one click"
            ]
        ),
        Recommendation(
            id="rec-002",
            rec_type="openai_rightsize",
            executable=False,
            title="Switch tasktomo from gpt-4o to gpt-4o-mini",
            target_service="svc:openai:api",
            affected_projects=["proj:tasktomo"],
            monthly_savings_usd=30,
            status="proposed",
            safety_checks=[
                "3,140 requests/month at low token volume — well inside mini's quality envelope",
                "portfolio-site already runs gpt-4o-mini successfully",
                "One-line change: OPENAI_MODEL env var"
            ]
        ),
        Recommendation(
            id="rec-003",
            rec_type="unused_subscription",
            executable=False,
            title="legacy-api looks abandoned — review its Supabase Pro subscription",
            target_service="svc:supabase:legacy-api-db",
            affected_projects=["proj:legacy-api"],
            monthly_savings_usd=25,
            status="proposed",
            safety_checks=[
                "No commits to legacy-api in 89 days",
                "Its README marks it deprecated, superseded by TaskTomo",
                "If pause (rec-001) causes no complaints for 30 days, cancel the Pro subscription"
            ],
            note="Savings overlap with rec-001 — count once in the header total"
        )
    ];
    return RecommendationsData(recommendations=recs);
}

glob _approved_recs: list[str] = [];

def:pub approve_action(rec_id: str) -> ApproveResult {
    _approved_recs.append(rec_id);
    return ApproveResult(id=rec_id, status="approved", message=f"Recommendation {rec_id} approved and queued for execution.");
}
