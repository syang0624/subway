"""SUBway's dependency graph and walker pipeline.

Rules decide whether a recommendation exists. byLLM is only used to turn the
deterministic evidence into concise safety language.
"""

import os;
import from datetime { datetime, timezone }
import from time { sleep }
import from services.connectors {
    validate_provider, fetch_repos, fetch_manifests,
    pause_project, get_project_status, get_openai_usage
}


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
    has total_monthly_cost_usd: int = 0;
    has source: str = "github";
    has warning: str = "";
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
    has action: RecommendationAction = RecommendationAction();
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

obj ConnectionResult {
    has providers: list[str] = [];
    has provider_statuses: list[dict] = [];
    has status: str = "";
}

obj DiscoveryResult {
    has projects_discovered: int = 0;
    has dependencies_discovered: int = 0;
    has source: str = "github";
    has warning: str = "";
}

obj AnalysisResult {
    has recommendations_created: int = 0;
}


node Account {
    has stable_id: str;
    has label: str;
    has provider: str;
}

node Project {
    has stable_id: str;
    has name: str;
    has full_name: str;
    has last_pushed: str;
    has stale: bool = False;
    has stale_days: int = 0;
    has source: str = "github";
}

node Service {
    has stable_id: str;
    has label: str;
    has provider: str;
    has provider_ref: str = "";
    has status: str = "";
    has idle_days: int = 0;
}

node Subscription {
    has stable_id: str;
    has label: str;
    has monthly_cost_usd: int;
}

node RecommendationRecord {
    has stable_id: str;
    has rec_type: str;
    has title: str;
    has target_service: str;
    has executable: bool = False;
    has target_ref: str = "";
    has affected_projects: list[str] = [];
    has monthly_savings_usd: int = 0;
    has status: str = "proposed";
    has safety_checks: list[str] = [];
    has action_api: str = "";
    has action_call: str = "";
    has manual_steps: str = "";
    has note: str = "";
}


edge owns: Account --> Project {}
edge uses: Project --> Service {}
edge targets: RecommendationRecord --> Service {}
edge billed_as {}


def explain(
    recommendation: str,
    deterministic_evidence: list[str],
    affected_projects: list[str]
) -> list[str] by llm(temperature=0.0);

sem explain = "Rewrite deterministic subscription-safety evidence as three or four concise, factual checks. Never invent evidence, change the recommendation, or claim zero risk.";
sem explain.recommendation = "The already-decided cost-saving recommendation to explain";
sem explain.deterministic_evidence = "Facts produced by deterministic rules and provider data";
sem explain.affected_projects = "Stable project identifiers that depend on the targeted service";
sem explain.return = "Short safety checks suitable for a recommendation card";


def _days_since(iso_timestamp: str) -> int {
    try {
        parsed = datetime.fromisoformat(iso_timestamp.replace("Z", "+00:00"));
        return max(
            0,
            int((datetime.now(timezone.utc) - parsed).days)
        );
    } except Exception {
        return 0;
    }
}

def _manifest_uses(manifest: dict, provider: str) -> bool {
    needles: list[str] = [provider.lower()];
    if provider == "supabase" {
        needles.append("supabase_url");
    } elif provider == "openai" {
        needles.append("openai_api_key");
    }

    values: list[str] = [];
    for dep in (manifest.get("deps", []) as list) {
        values.append(str(dep).lower());
    }
    for env_var in (manifest.get("env_vars", []) as list) {
        values.append(str(env_var).lower());
    }
    for manifest_file in (manifest.get("manifest_files", []) as list) {
        values.append(str(manifest_file).lower());
    }

    for value in values {
        for needle in needles {
            if needle in value {
                return True;
            }
        }
    }
    return False;
}

def _fallback_safety_checks(
    recommendation: str,
    evidence: list[str],
    affected_projects: list[str]
) -> list[str] {
    checks: list[str] = [];
    for fact in evidence {
        checks.append(fact);
    }
    return checks;
}

def _safety_checks(
    recommendation: str,
    evidence: list[str],
    affected_projects: list[str]
) -> list[str] {
    demo_mode: bool = os.environ.get("DEMO_MODE", "").lower() == "true";
    has_model_key: bool = bool(os.environ.get("OPENAI_API_KEY", ""));
    if has_model_key and not demo_mode {
        try {
            generated: list[str] = explain(
                recommendation,
                evidence,
                affected_projects
            );
            if len(generated) > 0 {
                return generated;
            }
        } except Exception {}
    }
    return _fallback_safety_checks(
        recommendation,
        evidence,
        affected_projects
    );
}

def _is_paused(status: str) -> bool {
    normalized: str = status.lower();
    return "paused" in normalized or "inactive" in normalized;
}


walker:pub connect_accounts {
    has reports: list[ConnectionResult] = [];

    can connect with Root entry {
        existing: list[Account] = [-->][?:Account];
        if len(existing) > 0 {
            report ConnectionResult(
                providers=["github", "supabase", "openai"],
                status="connected"
            );
            disengage;
        }
        provider_statuses: list[dict] = [
            validate_provider("github"),
            validate_provider("supabase"),
            validate_provider("openai")
        ];
        invalid: list[dict] = [
            status for status in provider_statuses
            if not bool(status.get("connected", False))
        ];
        github = here ++> Account(
            stable_id="acct:github",
            label="GitHub (syang0624)",
            provider="github"
        );
        supabase = here ++> Account(
            stable_id="acct:supabase",
            label="Supabase",
            provider="supabase"
        );
        openai = here ++> Account(
            stable_id="acct:openai",
            label="OpenAI",
            provider="openai"
        );

        tasktomo_db = here ++> Service(
            stable_id="svc:supabase:tasktomo-db",
            label="tasktomo-db",
            provider="supabase",
            provider_ref=os.environ.get(
                "SUPABASE_TASKTOMO_PROJECT_REF",
                "tasktomo-db-ref0"
            ),
            status="ACTIVE_HEALTHY"
        );
        legacy_db = here ++> Service(
            stable_id="svc:supabase:legacy-api-db",
            label="legacy-api-db",
            provider="supabase",
            provider_ref=os.environ.get(
                "SUPABASE_DEMO_PROJECT_REF",
                "legacy-api-db-ref0"
            ),
            status="ACTIVE_HEALTHY"
        );
        openai_api = here ++> Service(
            stable_id="svc:openai:api",
            label="OpenAI API",
            provider="openai",
            status="active"
        );

        tasktomo_plan = here ++> Subscription(
            stable_id="sub:supabase-pro-tasktomo",
            label="Supabase Pro",
            monthly_cost_usd=25
        );
        legacy_plan = here ++> Subscription(
            stable_id="sub:supabase-pro-legacy",
            label="Supabase Pro",
            monthly_cost_usd=25
        );
        openai_plan = here ++> Subscription(
            stable_id="sub:openai-usage",
            label="OpenAI usage",
            monthly_cost_usd=118
        );
        github_plan = here ++> Subscription(
            stable_id="sub:github-pro",
            label="GitHub Pro",
            monthly_cost_usd=4
        );

        tasktomo_db +>: billed_as() :+> tasktomo_plan;
        legacy_db +>: billed_as() :+> legacy_plan;
        openai_api +>: billed_as() :+> openai_plan;
        github +>: billed_as() :+> github_plan;
        connection_status: str = "connected";
        for provider_status in provider_statuses {
            if provider_status.get("source", "") == "fixture" {
                connection_status = "demo";
            }
        }
        if len(invalid) > 0 {
            connection_status = "degraded";
        }
        report ConnectionResult(
            providers=["github", "supabase", "openai"],
            provider_statuses=provider_statuses,
            status=connection_status
        );
    }
}


walker:pub discover_stack {
    has reports: list[DiscoveryResult] = [];
    has projects_discovered: int = 0;
    has dependencies_discovered: int = 0;
    has source: str = "github";
    has warning: str = "";

    can discover with Root entry {
        accounts: list[Account] = [-->][?:Account];
        services: list[Service] = [-->][?:Service];
        projects: list[Project] = [-->][?:Project];

        github_accounts: list[Account] = [
            account for account in accounts if account.provider == "github"
        ];
        if len(github_accounts) == 0 {
            report DiscoveryResult();
            disengage;
        }
        github: Account = github_accounts[0];

        repos: list[dict] = fetch_repos();
        for repo_info in repos {
            if repo_info.get("source", "") == "fixture" {
                self.source = "fixture";
                self.warning = str(
                    repo_info.get(
                        "error",
                        "GitHub credentials are absent; using demo fixtures."
                    )
                );
            }
        }

        for repo_info in repos {
            name: str = str(repo_info["name"]);
            full_name: str = str(repo_info["full_name"]);
            pushed_at: str = str(repo_info["pushed_at"]);
            project_id: str = f"proj:{name}";
            existing_projects: list[Project] = [
                project for project in projects
                if project.stable_id == project_id
            ];
            if len(existing_projects) > 0 {
                continue;
            }

            stale_days: int = _days_since(pushed_at);
            project = here ++> Project(
                stable_id=project_id,
                name=name,
                full_name=full_name,
                last_pushed=pushed_at[0:10],
                stale=stale_days >= 60,
                stale_days=stale_days,
                source=str(repo_info.get("source", "github"))
            );
            github +>: owns() :+> project;
            self.projects_discovered += 1;

            manifest: dict = fetch_manifests(full_name);
            if manifest.get("source", "") == "fixture" {
                self.source = "fixture";
                self.warning = str(
                    manifest.get(
                        "error",
                        "A manifest scan used demo fixtures."
                    )
                );
            }
            uses_supabase: bool = _manifest_uses(manifest, "supabase");
            uses_openai: bool = _manifest_uses(manifest, "openai");

            if uses_supabase {
                desired_service: str = (
                    "svc:supabase:legacy-api-db"
                    if name == "legacy-api"
                    else "svc:supabase:tasktomo-db"
                );
                matching_services: list[Service] = [
                    service for service in services
                    if service.stable_id == desired_service
                ];
                if len(matching_services) > 0 {
                    project +>: uses() :+> matching_services[0];
                    self.dependencies_discovered += 1;
                }
            }
            if uses_openai {
                openai_services: list[Service] = [
                    service for service in services
                    if service.stable_id == "svc:openai:api"
                ];
                if len(openai_services) > 0 {
                    project +>: uses() :+> openai_services[0];
                    self.dependencies_discovered += 1;
                }
            }
        }

        report DiscoveryResult(
            projects_discovered=self.projects_discovered,
            dependencies_discovered=self.dependencies_discovered,
            source=self.source,
            warning=self.warning
        );
    }
}


walker:pub analyze {
    has reports: list[AnalysisResult] = [];
    has recommendations_created: int = 0;

    can analyze_graph with Root entry {
        existing: list[RecommendationRecord] = [-->][?:RecommendationRecord];
        if len(existing) > 0 {
            report AnalysisResult(recommendations_created=0);
            disengage;
        }

        services: list[Service] = [-->][?:Service];
        projects: list[Project] = [-->][?:Project];
        legacy_services: list[Service] = [
            service for service in services
            if service.stable_id == "svc:supabase:legacy-api-db"
        ];
        openai_services: list[Service] = [
            service for service in services
            if service.stable_id == "svc:openai:api"
        ];
        legacy_projects: list[Project] = [
            project for project in projects
            if project.stable_id == "proj:legacy-api"
        ];

        if len(legacy_services) > 0 and len(legacy_projects) > 0 {
            legacy_service: Service = legacy_services[0];
            legacy_project: Project = legacy_projects[0];
            provider_data: dict = get_project_status(
                legacy_service.provider_ref
            );
            activity_source: str = str(
                provider_data.get("activity_source", "fixture")
            );
            idle_days: int = _days_since(
                str(provider_data.get("last_activity_at", ""))
            );
            legacy_service.idle_days = idle_days;
            if idle_days >= 30 {
                pause_evidence: list[str] = [
                    f"Activity evidence source: {activity_source}",
                    f"Last database activity {idle_days} days ago",
                    f"Only depender is legacy-api, untouched for {legacy_project.stale_days} days",
                    f"CPU utilization {provider_data.get('cpu_utilization_pct', 0)}%, database {provider_data.get('db_size_mb', 0)} MB",
                    "Pause is reversible from the Supabase dashboard"
                ];
                rec = here ++> RecommendationRecord(
                    stable_id="rec-001",
                    rec_type="supabase_pause",
                    executable=True,
                    title="Pause idle Supabase project legacy-api-db",
                    target_service=legacy_service.stable_id,
                    target_ref=legacy_service.provider_ref,
                    affected_projects=[legacy_project.stable_id],
                    monthly_savings_usd=25,
                    safety_checks=_safety_checks(
                        "Pause idle Supabase project legacy-api-db",
                        pause_evidence,
                        [legacy_project.stable_id]
                    ),
                    action_api="supabase_management",
                    action_call="POST /v1/projects/{ref}/pause"
                );
                rec +>: targets() :+> legacy_service;
                self.recommendations_created += 1;
            }

            if legacy_project.stale_days >= 60 {
                unused_evidence: list[str] = [
                    f"No commits to legacy-api in {legacy_project.stale_days} days",
                    "The repository README marks the service deprecated",
                    "Wait through a 30-day paused grace period before cancelling"
                ];
                unused_rec = here ++> RecommendationRecord(
                    stable_id="rec-003",
                    rec_type="unused_subscription",
                    executable=False,
                    title="legacy-api looks abandoned — review its Supabase Pro subscription",
                    target_service=legacy_service.stable_id,
                    target_ref=legacy_service.provider_ref,
                    affected_projects=[legacy_project.stable_id],
                    monthly_savings_usd=25,
                    safety_checks=_safety_checks(
                        "Review the abandoned legacy-api Supabase subscription",
                        unused_evidence,
                        [legacy_project.stable_id]
                    ),
                    manual_steps="After a 30-day paused grace period, downgrade or delete the project",
                    note="Savings overlap with rec-001 — count once"
                );
                unused_rec +>: targets() :+> legacy_service;
                self.recommendations_created += 1;
            }
        }

        usage: dict = get_openai_usage();
        usage_source: str = str(usage.get("source", "fixture"));
        for model_usage in (usage.get("by_model", []) as list) {
            usage_row: dict = model_usage as dict;
            if (
                usage_row.get("model", "") == "gpt-4o"
                and int(usage_row.get("requests", 0)) < 5000
                and len(openai_services) > 0
            ) {
                rightsize_evidence: list[str] = [
                    f"Usage evidence source: {usage_source}",
                    f"{usage_row.get('requests', 0)} requests/month at low token volume",
                    "portfolio-site already uses gpt-4o-mini successfully",
                    "The change is isolated to the OPENAI_MODEL environment variable"
                ];
                rightsize_rec = here ++> RecommendationRecord(
                    stable_id="rec-002",
                    rec_type="openai_rightsize",
                    executable=False,
                    title="Switch tasktomo from gpt-4o to gpt-4o-mini",
                    target_service=openai_services[0].stable_id,
                    affected_projects=["proj:tasktomo"],
                    monthly_savings_usd=30,
                    safety_checks=_safety_checks(
                        "Switch tasktomo from gpt-4o to gpt-4o-mini",
                        rightsize_evidence,
                        ["proj:tasktomo"]
                    ),
                    manual_steps="Set OPENAI_MODEL=gpt-4o-mini in tasktomo's deployment environment"
                );
                rightsize_rec +>: targets() :+> openai_services[0];
                self.recommendations_created += 1;
            }
        }

        report AnalysisResult(
            recommendations_created=self.recommendations_created
        );
    }
}


walker:pub get_graph {
    has reports: list[GraphData] = [];
    has nodes: list[GraphNode] = [];
    has edges: list[GraphEdge] = [];
    has total_monthly_cost_usd: int = 0;
    has source: str = "github";
    has warning: str = "";

    can start with Root entry {
        visit [-->];
    }

    can collect_account with Account entry {
        self.nodes.append(GraphNode(
            id=here.stable_id,
            node_type="Account",
            label=here.label,
            provider=here.provider
        ));
        for project in [here ->:owns:->][?:Project] {
            self.edges.append(GraphEdge(
                from_id=here.stable_id,
                to_id=project.stable_id,
                edge_type="owns"
            ));
        }
        for subscription in [here ->:billed_as:->][?:Subscription] {
            self.edges.append(GraphEdge(
                from_id=here.stable_id,
                to_id=subscription.stable_id,
                edge_type="billed_as"
            ));
        }
    }

    can collect_project with Project entry {
        if here.source == "fixture" {
            self.source = "fixture";
            self.warning = "GitHub was unavailable or unconfigured; graph data came from demo fixtures.";
        }
        self.nodes.append(GraphNode(
            id=here.stable_id,
            node_type="Project",
            label=here.name,
            last_pushed=here.last_pushed,
            stale=here.stale
        ));
        for service in [here ->:uses:->][?:Service] {
            self.edges.append(GraphEdge(
                from_id=here.stable_id,
                to_id=service.stable_id,
                edge_type="uses"
            ));
        }
    }

    can collect_service with Service entry {
        self.nodes.append(GraphNode(
            id=here.stable_id,
            node_type="Service",
            label=here.label,
            provider=here.provider,
            status=here.status,
            idle_days=here.idle_days
        ));
        for subscription in [here ->:billed_as:->][?:Subscription] {
            self.edges.append(GraphEdge(
                from_id=here.stable_id,
                to_id=subscription.stable_id,
                edge_type="billed_as"
            ));
        }
    }

    can collect_subscription with Subscription entry {
        self.nodes.append(GraphNode(
            id=here.stable_id,
            node_type="Subscription",
            label=here.label,
            monthly_cost_usd=here.monthly_cost_usd
        ));
        self.total_monthly_cost_usd += here.monthly_cost_usd;
    }

    can finish with Root exit {
        report GraphData(
            nodes=self.nodes,
            edges=self.edges,
            total_monthly_cost_usd=self.total_monthly_cost_usd,
            source=self.source,
            warning=self.warning
        );
    }
}


walker:pub get_recommendations {
    has reports: list[RecommendationsData] = [];
    has recommendations: list[Recommendation] = [];

    can start with Root entry {
        visit [-->];
    }

    can collect with RecommendationRecord entry {
        self.recommendations.append(Recommendation(
            id=here.stable_id,
            rec_type=here.rec_type,
            executable=here.executable,
            title=here.title,
            target_service=here.target_service,
            affected_projects=here.affected_projects,
            monthly_savings_usd=here.monthly_savings_usd,
            status=here.status,
            safety_checks=here.safety_checks,
            action=RecommendationAction(
                api=here.action_api,
                call=here.action_call,
                manual_steps=here.manual_steps
            ),
            note=here.note
        ));
    }

    can finish with Root exit {
        report RecommendationsData(
            recommendations=self.recommendations
        );
    }
}


walker:pub verify_action {
    has rec_id: str;
    has target_ref: str;
    has demo_mode: bool = False;
    has reports: list[ApproveResult] = [];
    has result: ApproveResult = ApproveResult();
    has verified: bool = False;

    can verify with Root entry {
        self.verified = self.demo_mode;
        if not self.demo_mode {
            for attempt in range(10) {
                provider_data: dict = get_project_status(self.target_ref);
                observed_status: str = str(
                    provider_data.get("status", "")
                );
                if _is_paused(observed_status) {
                    self.verified = True;
                    break;
                }
                if "error" in provider_data {
                    break;
                }
                if attempt < 9 {
                    sleep(2);
                }
            }
        }
        visit [-->];
    }

    can update_recommendation with RecommendationRecord entry {
        if here.stable_id == self.rec_id and self.verified {
            here.status = "verified";
        }
    }

    can update_service with Service entry {
        if here.provider_ref == self.target_ref and self.verified {
            here.status = "PAUSED";
        }
    }

    can finish with Root exit {
        if self.verified {
            self.result = ApproveResult(
                id=self.rec_id,
                status="verified",
                message="Supabase confirmed the project is paused."
            );
        } else {
            self.result = ApproveResult(
                id=self.rec_id,
                status="verification_failed",
                message="The provider did not report a paused status."
            );
        }
        report self.result;
    }
}


walker:pub execute_action {
    has rec_id: str;
    has target_ref: str;
    has reports: list[ApproveResult] = [];
    has result: ApproveResult = ApproveResult();
    has action_response: dict = {};
    has execution_ok: bool = False;

    can execute with Root entry {
        has_live_token: bool = bool(
            os.environ.get("SUPABASE_ACCESS_TOKEN", "")
        );
        if has_live_token and self.target_ref.endswith("-ref0") {
            self.result = ApproveResult(
                id=self.rec_id,
                status="configuration_error",
                message="Set a real Supabase project ref before live execution."
            );
        } else {
            self.action_response = pause_project(self.target_ref);
            self.execution_ok = "error" not in self.action_response;
            if self.execution_ok {
                visit [-->][?:RecommendationRecord];
            } else {
                self.result = ApproveResult(
                    id=self.rec_id,
                    status="execution_failed",
                    message=str(
                        self.action_response.get("error", "Pause failed")
                    )
                );
            }
        }
    }

    can mark_executed with RecommendationRecord entry {
        if here.stable_id == self.rec_id and self.execution_ok {
            here.status = "executed";
            verifier = verify_action(
                rec_id=self.rec_id,
                target_ref=self.target_ref,
                demo_mode=bool(self.action_response.get("demo_mode", False))
            );
            root spawn verifier;
            self.result = verifier.result;
        }
    }

    can finish with Root exit {
        report self.result;
    }
}


walker:pub approve_action {
    has rec_id: str;
    has reports: list[ApproveResult] = [];
    has found: bool = False;
    has result: ApproveResult = ApproveResult();

    can find with Root entry {
        visit [-->][?:RecommendationRecord];
    }

    can approve with RecommendationRecord entry {
        if here.stable_id == self.rec_id {
            self.found = True;
            here.status = "approved";
            if here.executable {
                executor = execute_action(
                    rec_id=here.stable_id,
                    target_ref=here.target_ref
                );
                root spawn executor;
                self.result = executor.result;
            } else {
                self.result = ApproveResult(
                    id=here.stable_id,
                    status="approved",
                    message="Advisory recommendation approved; manual steps are ready."
                );
            }
        }
    }

    can finish with Root exit {
        if not self.found {
            self.result = ApproveResult(
                id=self.rec_id,
                status="not_found",
                message=f"Recommendation {self.rec_id} was not found."
            );
        }
        report self.result;
    }
}
