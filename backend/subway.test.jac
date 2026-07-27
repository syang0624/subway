import from backend.subway {
    _manifest_uses,
    _is_paused,
    ConnectionResult,
    DiscoveryResult,
    AnalysisResult,
    GraphData,
    RecommendationsData,
    ApproveResult,
    connect_accounts,
    discover_stack,
    analyze,
    get_graph,
    get_recommendations,
    approve_action
}


test "manifest dependency detection is provider aware" {
    manifest: dict = {
        "deps": ["@supabase/supabase-js", "openai"],
        "env_vars": ["SUPABASE_URL", "OPENAI_API_KEY"]
    };
    assert _manifest_uses(manifest, "supabase");
    assert _manifest_uses(manifest, "openai");
    assert not _manifest_uses(manifest, "github");
}

test "paused provider statuses are normalized" {
    assert _is_paused("PAUSED");
    assert _is_paused("INACTIVE");
    assert not _is_paused("ACTIVE_HEALTHY");
}

test "walker pipeline builds the agreed graph and recommendations" {
    connected = root spawn connect_accounts();
    discovered = root spawn discover_stack();
    analyzed = root spawn analyze();
    graph_result = root spawn get_graph();
    recommendations_result = root spawn get_recommendations();

    connection: ConnectionResult = connected.reports[0];
    discovery: DiscoveryResult = discovered.reports[0];
    analysis: AnalysisResult = analyzed.reports[0];
    graph: GraphData = graph_result.reports[0];
    recommendations: RecommendationsData = recommendations_result.reports[0];

    assert connection.status in ["connected", "demo"];
    assert discovery.projects_discovered in [0, 3];
    assert discovery.dependencies_discovered in [0, 4];
    assert analysis.recommendations_created in [0, 3];
    assert len(graph.nodes) == 13;
    assert len(graph.edges) == 11;
    assert graph.total_monthly_cost_usd == 172;
    assert graph.source in ["github", "fixture"];
    assert len(recommendations.recommendations) == 3;
}

test "approval rejects an unknown recommendation" {
    result = root spawn approve_action(rec_id="rec-missing");
    approval: ApproveResult = result.reports[0];
    assert approval.status == "not_found";
}
