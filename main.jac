import from services.subway {
    get_graph, get_recommendations, approve_action, verify_action
}

cl import "./styles/global.css";
cl import from components.SubwayDashboard { SubwayDashboard }
cl import from "@jac/runtime" { Router, Routes, Route, Navigate }

cl {
    def:pub app() -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/" element={<SubwayDashboard />} />
                <Route path="*" element={<Navigate to="/" />} />
            </Routes>
        </Router>;
    }
}
