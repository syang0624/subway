import from services.subway {
    get_graph, get_recommendations, approve_action
}

cl import ".styles.global.css";
import from .components.SubwayDashboard { SubwayDashboard }
import from "@jac/runtime" { Router, Routes, Route, Navigate }

def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<SubwayDashboard />} />
            <Route path="*" element={<Navigate to="/" />} />
        </Routes>
    </Router>;
}
