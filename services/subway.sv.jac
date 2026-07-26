"""Typed server façade used by the existing Jac client."""

import from backend.subway {
    GraphData, RecommendationsData, ApproveResult,
    connect_accounts,
    discover_stack,
    analyze,
    get_graph as get_graph_walker,
    get_recommendations as get_recommendations_walker,
    approve_action as approve_action_walker
}


def _initialize() -> None {
    connection = root spawn connect_accounts();
    if connection.reports[0].status == "error" {
        raise RuntimeError(
            "One or more provider credentials failed validation."
        );
    }
    root spawn discover_stack();
    root spawn analyze();
}

def:pub get_graph() -> GraphData {
    _initialize();
    result = root spawn get_graph_walker();
    return result.reports[0];
}

def:pub get_recommendations() -> RecommendationsData {
    _initialize();
    result = root spawn get_recommendations_walker();
    return result.reports[0];
}

def:pub approve_action(rec_id: str) -> ApproveResult {
    _initialize();
    result = root spawn approve_action_walker(rec_id=rec_id);
    return result.reports[0];
}
