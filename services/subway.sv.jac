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
    approval: ApproveResult = result.reports[0];
    if approval.status == "verified" {
        return ApproveResult(
            id=approval.id,
            status="approved",
            message=approval.message
        );
    }
    return approval;
}

def:pub verify_action(rec_id: str) -> ApproveResult {
    _initialize();
    result = root spawn get_recommendations_walker();
    data: RecommendationsData = result.reports[0];
    for recommendation in data.recommendations {
        if recommendation.id == rec_id {
            return ApproveResult(
                id=rec_id,
                status=recommendation.status,
                message=f"Recommendation {rec_id} is {recommendation.status}."
            );
        }
    }
    return ApproveResult(
        id=rec_id,
        status="not_found",
        message=f"Recommendation {rec_id} was not found."
    );
}
