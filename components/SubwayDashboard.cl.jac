import from ".ui.card" { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }
import from ".ui.button" { Button }
import from ".ui.badge" { Badge }
import from ".ui.separator" { Separator }
import from ".ui.spinner" { Spinner }
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CheckmarkCircle01Icon,
    Analytics01Icon,
    ArrowRight01Icon,
    InformationCircleIcon
}

sv import from ..services.stubService {
    GraphData, GraphNode, GraphEdge, Recommendation, RecommendationsData, ApproveResult,
    get_graph, get_recommendations, approve_action
}

def:pub SubwayDashboard() -> JsxElement {
    has loading: bool = True;
    has graph_data: GraphData | None = None;
    has recs_data: RecommendationsData | None = None;
    has connected_github: bool = False;
    has connected_supabase: bool = False;
    has connected_openai: bool = False;
    has connecting: str = "";
    has approving: str = "";
    has approved_ids: list[str] = [];
    has total_cost: int = 172;
    has error_msg: str = "";

    async can with entry {
        loading = True;
        try {
            gd: GraphData = await get_graph();
            rd: RecommendationsData = await get_recommendations();
            graph_data = gd;
            recs_data = rd;
            total_cost = gd.total_monthly_cost_usd;
        } except Exception as e {
            error_msg = str(e);
        }
        loading = False;
    }

    async def handle_connect(provider: str) -> None {
        connecting = provider;
        if provider == "github" {
            connected_github = True;
        } elif provider == "supabase" {
            connected_supabase = True;
        } elif provider == "openai" {
            connected_openai = True;
        }
        connecting = "";
    }

    async def handle_approve(rec_id: str) -> None {
        approving = rec_id;
        try {
            result: ApproveResult = await approve_action(rec_id=rec_id);
            if result.status == "approved" {
                approved_ids = approved_ids + [rec_id];
                if rec_id == "rec-001" {
                    total_cost = total_cost - 25;
                } elif rec_id == "rec-002" {
                    total_cost = total_cost - 30;
                }
            }
        } except Exception as e {
            error_msg = str(e);
        }
        approving = "";
    }

    def get_rec_status(rec: Recommendation) -> str {
        if rec.id in approved_ids {
            return "approved";
        }
        return rec.status;
    }

    def savings_potential() -> int {
        if recs_data == None {
            return 0;
        }
        total: int = 0;
        for rec in (recs_data as RecommendationsData).recommendations {
            if rec.id not in approved_ids {
                if rec.id != "rec-003" {
                    total = total + rec.monthly_savings_usd;
                }
            }
        }
        return total;
    }

    if loading {
        return <div className="flex min-h-screen items-center justify-center bg-background">
            <div className="flex flex-col items-center gap-4">
                <Spinner className="size-8 text-primary" />
                <p className="text-sm text-muted-foreground">Scanning your stack...</p>
            </div>
        </div>;
    }

    return <div className="min-h-screen bg-background">
        {#* Header *#}
        <header className="border-b border-border bg-card">
            <div className="mx-auto max-w-7xl pl-6 pr-6 pt-4 pb-4">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="flex size-8 items-center justify-center rounded-md bg-primary">
                            <HugeiconsIcon icon={Analytics01Icon} strokeWidth={2} className="size-4 text-primary-foreground" />
                        </div>
                        <div>
                            <h1 className="text-lg font-semibold tracking-tight">SUBway</h1>
                            <p className="text-xs text-muted-foreground">Subscription dependency manager</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-6">
                        <div className="text-right">
                            <p className="text-xs text-muted-foreground">Monthly spend</p>
                            <p className="text-2xl font-semibold tabular-nums text-foreground">${total_cost}/mo</p>
                        </div>
                        {savings_potential() > 0 and <div className="text-right">
                            <p className="text-xs text-muted-foreground">Potential savings</p>
                            <p className="text-2xl font-semibold tabular-nums text-primary">${savings_potential()}/mo</p>
                        </div> or None}
                    </div>
                </div>
            </div>
        </header>

        <main className="mx-auto max-w-7xl pl-6 pr-6 pt-8 pb-8">
            <div className="flex flex-col gap-8">

                {#* Connect Panel *#}
                <section>
                    <div className="mb-4">
                        <h2 className="text-lg font-semibold">Connect your accounts</h2>
                        <p className="text-sm text-muted-foreground">Connect your developer accounts to scan your dependency graph.</p>
                    </div>
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                        <Card className={cn("transition-colors", connected_github and "border-primary/50 bg-primary/5" or "")}>
                            <CardContent className="pt-6 pb-6 pl-6 pr-6">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className={cn("flex size-10 items-center justify-center rounded-lg border", connected_github and "border-primary/30 bg-primary/10" or "border-border bg-muted")}>
                                            <span className="text-sm font-bold">GH</span>
                                        </div>
                                        <div>
                                            <p className="font-medium">GitHub</p>
                                            <p className="text-xs text-muted-foreground">{connected_github and "syang0624" or "Not connected"}</p>
                                        </div>
                                    </div>
                                    {connected_github and
                                        <Badge variant="outline" className="border-primary/30 text-primary">
                                            <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mr-1 size-3" />
                                            Connected
                                        </Badge>
                                    or
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            onClick={lambda { handle_connect("github"); }}
                                            disabled={connecting == "github"}
                                        >
                                            {connecting == "github" and "Connecting..." or "Connect"}
                                        </Button>
                                    }
                                </div>
                            </CardContent>
                        </Card>

                        <Card className={cn("transition-colors", connected_supabase and "border-primary/50 bg-primary/5" or "")}>
                            <CardContent className="pt-6 pb-6 pl-6 pr-6">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className={cn("flex size-10 items-center justify-center rounded-lg border", connected_supabase and "border-primary/30 bg-primary/10" or "border-border bg-muted")}>
                                            <span className="text-sm font-bold">SB</span>
                                        </div>
                                        <div>
                                            <p className="font-medium">Supabase</p>
                                            <p className="text-xs text-muted-foreground">{connected_supabase and "2 projects" or "Not connected"}</p>
                                        </div>
                                    </div>
                                    {connected_supabase and
                                        <Badge variant="outline" className="border-primary/30 text-primary">
                                            <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mr-1 size-3" />
                                            Connected
                                        </Badge>
                                    or
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            onClick={lambda { handle_connect("supabase"); }}
                                            disabled={connecting == "supabase"}
                                        >
                                            {connecting == "supabase" and "Connecting..." or "Connect"}
                                        </Button>
                                    }
                                </div>
                            </CardContent>
                        </Card>

                        <Card className={cn("transition-colors", connected_openai and "border-primary/50 bg-primary/5" or "")}>
                            <CardContent className="pt-6 pb-6 pl-6 pr-6">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className={cn("flex size-10 items-center justify-center rounded-lg border", connected_openai and "border-primary/30 bg-primary/10" or "border-border bg-muted")}>
                                            <span className="text-sm font-bold">AI</span>
                                        </div>
                                        <div>
                                            <p className="font-medium">OpenAI</p>
                                            <p className="text-xs text-muted-foreground">{connected_openai and "$118/mo usage" or "Not connected"}</p>
                                        </div>
                                    </div>
                                    {connected_openai and
                                        <Badge variant="outline" className="border-primary/30 text-primary">
                                            <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mr-1 size-3" />
                                            Connected
                                        </Badge>
                                    or
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            onClick={lambda { handle_connect("openai"); }}
                                            disabled={connecting == "openai"}
                                        >
                                            {connecting == "openai" and "Connecting..." or "Connect"}
                                        </Button>
                                    }
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                </section>

                <Separator />

                {#* Dependency Graph *#}
                {graph_data != None and <section>
                    <div className="mb-4">
                        <h2 className="text-lg font-semibold">Dependency graph</h2>
                        <p className="text-sm text-muted-foreground">Auto-built from GitHub manifest scans. Walkers traversed {len((graph_data as GraphData).nodes)} nodes and {len((graph_data as GraphData).edges)} edges.</p>
                    </div>
                    <Card>
                        <CardContent className="pt-6 pb-6 pl-6 pr-6">
                            <GraphView graph={(graph_data as GraphData)} />
                        </CardContent>
                    </Card>
                </section> or None}

                <Separator />

                {#* Recommendations *#}
                {recs_data != None and <section>
                    <div className="mb-4">
                        <div className="flex items-center justify-between">
                            <div>
                                <h2 className="text-lg font-semibold">AI recommendations</h2>
                                <p className="text-sm text-muted-foreground">Dependency-aware cost optimizations. Approve to execute.</p>
                            </div>
                            <Badge variant="secondary" className="text-sm">
                                {len((recs_data as RecommendationsData).recommendations)} recommendations
                            </Badge>
                        </div>
                    </div>
                    <div className="flex flex-col gap-4">
                        {for rec in (recs_data as RecommendationsData).recommendations {
                            <RecommendationCard
                                key={rec.id}
                                rec={rec}
                                status={get_rec_status(rec)}
                                approving={approving == rec.id}
                                on_approve={lambda { handle_approve(rec.id); }}
                            />
                        }}
                    </div>
                </section> or None}

            </div>
        </main>
    </div>;
}

def:pub GraphView(graph: GraphData) -> JsxElement {
    node_colors: dict = {
        "Account": "bg-blue-500/20 border-blue-500/40 text-blue-400",
        "Project": "bg-violet-500/20 border-violet-500/40 text-violet-400",
        "Service": "bg-amber-500/20 border-amber-500/40 text-amber-400",
        "Subscription": "bg-emerald-500/20 border-emerald-500/40 text-emerald-400"
    };

    accounts: list[GraphNode] = [n for n in graph.nodes if n.node_type == "Account"];
    projects: list[GraphNode] = [n for n in graph.nodes if n.node_type == "Project"];
    services: list[GraphNode] = [n for n in graph.nodes if n.node_type == "Service"];
    subscriptions: list[GraphNode] = [n for n in graph.nodes if n.node_type == "Subscription"];

    return <div className="flex flex-col gap-6">
        {#* Legend *#}
        <div className="flex flex-wrap items-center gap-4">
            {for entry in [["Account", "bg-blue-500/20 border-blue-500/40 text-blue-400"], ["Project", "bg-violet-500/20 border-violet-500/40 text-violet-400"], ["Service", "bg-amber-500/20 border-amber-500/40 text-amber-400"], ["Subscription", "bg-emerald-500/20 border-emerald-500/40 text-emerald-400"]] {
                <div key={entry[0]} className="flex items-center gap-2">
                    <div className={cn("size-3 rounded-sm border", entry[1])}></div>
                    <span className="text-xs text-muted-foreground">{entry[0]}</span>
                </div>
            }}
        </div>

        {#* Graph layers *#}
        <div className="flex flex-col gap-4">
            <GraphLayer label="Accounts" nodes={accounts} color_map={node_colors} />
            <div className="flex items-center gap-2 pl-4">
                <div className="h-px flex-1 border-t border-dashed border-border"></div>
                <span className="text-xs text-muted-foreground">owns / billed as</span>
                <div className="h-px flex-1 border-t border-dashed border-border"></div>
            </div>
            <GraphLayer label="Projects" nodes={projects} color_map={node_colors} />
            <div className="flex items-center gap-2 pl-4">
                <div className="h-px flex-1 border-t border-dashed border-border"></div>
                <span className="text-xs text-muted-foreground">uses</span>
                <div className="h-px flex-1 border-t border-dashed border-border"></div>
            </div>
            <GraphLayer label="Services" nodes={services} color_map={node_colors} />
            <div className="flex items-center gap-2 pl-4">
                <div className="h-px flex-1 border-t border-dashed border-border"></div>
                <span className="text-xs text-muted-foreground">billed as</span>
                <div className="h-px flex-1 border-t border-dashed border-border"></div>
            </div>
            <GraphLayer label="Subscriptions" nodes={subscriptions} color_map={node_colors} />
        </div>
    </div>;
}

def:pub GraphLayer(label: str, nodes: list[GraphNode], color_map: dict) -> JsxElement {
    return <div className="flex flex-wrap items-center gap-3">
        <span className="w-24 shrink-0 text-xs font-medium text-muted-foreground">{label}</span>
        {for node in nodes {
            <GraphNodeChip key={node.id} gnode={node} color_map={color_map} />
        }}
    </div>;
}

def:pub GraphNodeChip(gnode: GraphNode, color_map: dict) -> JsxElement {
    color_class: str = color_map.get(gnode.node_type, "bg-muted border-border text-foreground");
    is_stale: bool = gnode.stale or gnode.idle_days > 0;

    return <div className={cn("relative flex items-center gap-2 rounded-lg border pl-3 pr-3 pt-2 pb-2 text-sm", color_class)}>
        {is_stale and <div className="absolute -right-1 -top-1 size-2 rounded-full bg-amber-400"></div> or None}
        <span className="font-medium">{gnode.label}</span>
        {gnode.node_type == "Subscription" and gnode.monthly_cost_usd > 0 and
            <span className="text-xs opacity-70">${gnode.monthly_cost_usd}/mo</span>
        or None}
        {gnode.idle_days > 0 and
            <span className="text-xs opacity-70">idle {gnode.idle_days}d</span>
        or None}
        {gnode.stale and not (gnode.idle_days > 0) and
            <span className="text-xs opacity-70">stale</span>
        or None}
    </div>;
}

def:pub RecommendationCard(rec: Recommendation, status: str, approving: bool, on_approve: any) -> JsxElement {
    is_approved: bool = status == "approved";
    type_labels: dict = {
        "supabase_pause": "Supabase Pause",
        "openai_rightsize": "Model Right-sizing",
        "unused_subscription": "Unused Subscription"
    };
    type_label: str = type_labels.get(rec.rec_type, rec.rec_type);

    return <Card className={cn("transition-colors", is_approved and "border-primary/40 bg-primary/5" or "")}>
        <CardHeader>
            <div className="flex items-start justify-between gap-4">
                <div className="flex flex-col gap-1">
                    <div className="flex items-center gap-2">
                        <Badge variant="outline" className="text-xs">{type_label}</Badge>
                        {rec.executable and
                            <Badge variant="secondary" className="text-xs">Executable</Badge>
                        or
                            <Badge variant="outline" className="text-xs text-muted-foreground">Advisory</Badge>
                        }
                        {is_approved and
                            <Badge className="text-xs">
                                <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mr-1 size-3" />
                                Approved
                            </Badge>
                        or None}
                    </div>
                    <CardTitle className="text-base">{rec.title}</CardTitle>
                </div>
                <div className="shrink-0 text-right">
                    <p className="text-2xl font-semibold tabular-nums text-primary">${rec.monthly_savings_usd}</p>
                    <p className="text-xs text-muted-foreground">per month</p>
                </div>
            </div>
        </CardHeader>
        <CardContent>
            <div className="flex flex-col gap-3">
                <div>
                    <p className="mb-2 text-xs font-medium text-muted-foreground">Safety checks</p>
                    <div className="flex flex-col gap-1">
                        {for check in rec.safety_checks {
                            <div key={check} className="flex items-start gap-2">
                                <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mt-0.5 size-3.5 shrink-0 text-primary" />
                                <span className="text-sm text-muted-foreground">{check}</span>
                            </div>
                        }}
                    </div>
                </div>
                {rec.note != "" and
                    <div className="flex items-start gap-2 rounded-md bg-muted pl-3 pr-3 pt-2 pb-2">
                        <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="mt-0.5 size-3.5 shrink-0 text-muted-foreground" />
                        <span className="text-xs text-muted-foreground">{rec.note}</span>
                    </div>
                or None}
            </div>
        </CardContent>
        {rec.executable and not is_approved and
            <CardFooter>
                <Button
                    onClick={on_approve}
                    disabled={approving}
                    className="w-full"
                >
                    {approving and <Spinner className="mr-2 size-4" /> or None}
                    {approving and "Executing..." or "Approve and Execute"}
                    {not approving and <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="ml-2 size-4" /> or None}
                </Button>
            </CardFooter>
        or None}
        {is_approved and
            <CardFooter>
                <div className="flex w-full items-center justify-center gap-2 rounded-md bg-primary/10 pl-4 pr-4 pt-3 pb-3">
                    <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="size-4 text-primary" />
                    <span className="text-sm font-medium text-primary">Executed — savings applied</span>
                </div>
            </CardFooter>
        or None}
    </Card>;
}
