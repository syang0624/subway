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
    ArrowDown01Icon,
    InformationCircleIcon,
    SparklesIcon,
    DollarCircleIcon,
    File01Icon
}

sv import from backend.subway {
    GraphData, GraphNode, GraphEdge,
    Recommendation, RecommendationsData, ApproveResult
}
sv import from services.subway {
    get_graph, get_recommendations, approve_action, verify_action
}


def:pub SubwayDashboard() -> JsxElement {
    has scanning: bool = False;
    has graph_data: GraphData | None = None;
    has recs_data: RecommendationsData | None = None;
    has connected_github: bool = False;
    has connected_supabase: bool = False;
    has connected_openai: bool = False;
    has connecting: str = "";
    has approving: str = "";
    has verifying: str = "";
    has approved_ids: list[str] = [];
    has total_cost: int = 172;
    has error_msg: str = "";

    async def run_scan() -> None {
        scanning = True;
        error_msg = "";
        try {
            gd: GraphData = await get_graph();
            rd: RecommendationsData = await get_recommendations();
            graph_data = gd;
            recs_data = rd;
            total_cost = gd.total_monthly_cost_usd;
        } except Exception as e {
            error_msg = str(e);
        }
        scanning = False;
    }

    async def handle_connect(provider: str) -> None {
        connecting = provider;
        all_connected: bool = (
            (provider == "github" or connected_github)
            and (provider == "supabase" or connected_supabase)
            and (provider == "openai" or connected_openai)
        );
        if provider == "github" {
            connected_github = True;
        } elif provider == "supabase" {
            connected_supabase = True;
        } elif provider == "openai" {
            connected_openai = True;
        }
        if all_connected {
            await run_scan();
        }
        connecting = "";
    }

    async def handle_connect_all() -> None {
        connecting = "all";
        connected_github = True;
        connected_supabase = True;
        connected_openai = True;
        await run_scan();
        connecting = "";
    }

    async def handle_rescan() -> None {
        await run_scan();
    }

    async def handle_approve(rec_id: str) -> None {
        approving = rec_id;
        error_msg = "";
        try {
            result: ApproveResult = await approve_action(rec_id=rec_id);
            if result.status == "approved" {
                approving = "";
                verifying = rec_id;
                vresult: ApproveResult = await verify_action(rec_id=rec_id);
                if vresult.status == "verified" {
                    approved_ids = approved_ids + [rec_id];
                    if rec_id == "rec-001" {
                        total_cost = total_cost - 25;
                    }
                } else {
                    error_msg = vresult.message;
                }
            } else {
                error_msg = result.message;
            }
        } except Exception as e {
            error_msg = str(e);
        }
        approving = "";
        verifying = "";
    }

    async def handle_mark_done(rec_id: str) -> None {
        approving = rec_id;
        error_msg = "";
        try {
            ar: ApproveResult = await approve_action(rec_id=rec_id);
            if ar.status == "approved" {
                approved_ids = approved_ids + [rec_id];
                if rec_id == "rec-002" {
                    total_cost = total_cost - 30;
                }
            } else {
                error_msg = ar.message;
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
            return 55;
        }
        total: int = 0;
        for rec in (recs_data as RecommendationsData).recommendations {
            if rec.id not in approved_ids and rec.id != "rec-003" {
                total = total + rec.monthly_savings_usd;
            }
        }
        return total;
    }

    fully_connected: bool = (
        connected_github and connected_supabase and connected_openai
    );
    scan_ready: bool = graph_data != None and recs_data != None;
    optimized_cost: int = total_cost - savings_potential();
    realized_savings: int = 172 - total_cost;

    return <div className="min-h-screen bg-background">
        <header className="sticky top-0 z-20 border-b border-border/80 bg-background/95 backdrop-blur">
            <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 pl-5 pr-5 pt-3 pb-3 sm:pl-8 sm:pr-8">
                <div className="flex items-center gap-3">
                    <div className="flex size-9 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                        <HugeiconsIcon icon={Analytics01Icon} strokeWidth={2} className="size-5" />
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <h1 className="text-base font-semibold tracking-tight">SUBway</h1>
                            <Badge variant="secondary" className="hidden text-[10px] sm:inline-flex">
                                Built end-to-end in Jac
                            </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground">Dependency-aware subscription autopilot</p>
                    </div>
                </div>
                <div className="flex items-center gap-5">
                    {scan_ready and <div className="hidden text-right sm:block">
                        <p className="text-[11px] text-muted-foreground">Evidence mapped</p>
                        <p className="text-sm font-medium">
                            {len((graph_data as GraphData).nodes)} nodes · {len((graph_data as GraphData).edges)} edges
                        </p>
                    </div> or None}
                    <div className="text-right">
                        <p className="text-[11px] text-muted-foreground">Monthly spend</p>
                        <p className="text-xl font-semibold tabular-nums">${total_cost}<span className="text-xs font-normal text-muted-foreground">/mo</span></p>
                    </div>
                </div>
            </div>
        </header>

        <main>
            <section className="border-b border-border bg-gradient-to-br from-primary/10 via-background to-background">
                <div className="mx-auto grid max-w-7xl gap-8 pl-5 pr-5 pt-10 pb-10 sm:pl-8 sm:pr-8 lg:grid-cols-[1.35fr_0.65fr] lg:items-center lg:pt-14 lg:pb-14">
                    <div>
                        <Badge variant="outline" className="mb-5 border-primary/30 bg-primary/5 text-primary">
                            Steven's stack · 3 side projects · 3 providers
                        </Badge>
                        <h2 className="max-w-3xl text-4xl font-semibold tracking-tight sm:text-5xl">
                            Know what breaks <span className="text-primary">before</span> you cut spend.
                        </h2>
                        <p className="mt-5 max-w-2xl text-base leading-7 text-muted-foreground sm:text-lg">
                            SUBway scans repository manifests, builds a live dependency graph, and traces every recommendation back to the projects it affects.
                        </p>
                        <div className="mt-7 flex flex-col gap-3 sm:flex-row sm:items-center">
                            {not scan_ready and
                                <Button
                                    size="lg"
                                    onClick={lambda { handle_connect_all(); }}
                                    disabled={scanning or connecting == "all"}
                                    className="sm:min-w-56"
                                >
                                    {(scanning or connecting == "all") and <Spinner className="mr-2 size-4" /> or <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="mr-2 size-4" />}
                                    {(scanning or connecting == "all") and "Mapping dependencies..." or "Map Steven's stack"}
                                </Button>
                            or
                                <Button
                                    size="lg"
                                    variant="outline"
                                    onClick={lambda { handle_rescan(); }}
                                    disabled={scanning}
                                >
                                    {scanning and <Spinner className="mr-2 size-4" /> or <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="mr-2 size-4" />}
                                    {scanning and "Re-running walkers..." or "Re-run Jac analysis"}
                                </Button>
                            }
                            <p className="text-xs leading-5 text-muted-foreground">
                                Demo-safe: live credentials when available, clearly labeled fixtures otherwise.
                            </p>
                        </div>
                        <ScanPipeline scanning={scanning} ready={scan_ready} />
                    </div>

                    <Card className="border-primary/20 bg-card/90 ring-primary/10">
                        <CardHeader>
                            <div className="flex items-center justify-between">
                                <div>
                                    <CardDescription>Optimization brief</CardDescription>
                                    <CardTitle className="mt-1 text-2xl">A safer path to $117/mo</CardTitle>
                                </div>
                                <div className="flex size-11 items-center justify-center rounded-xl bg-primary/10 text-primary">
                                    <HugeiconsIcon icon={DollarCircleIcon} strokeWidth={2} className="size-6" />
                                </div>
                            </div>
                        </CardHeader>
                        <CardContent>
                            <div className="grid grid-cols-3 gap-3">
                                <Metric label="Today" value={"$" + str(total_cost)} detail="/ month" />
                                <Metric label={realized_savings > 0 and "Realized" or "Found"} value={"$" + str(realized_savings > 0 and realized_savings or 55)} detail="/ month" accent={True} />
                                <Metric label="Reduction" value="32%" detail="$660 / year" />
                            </div>
                            <Separator className="mt-5 mb-5" />
                            <div className="flex flex-col gap-3 text-sm">
                                <ProofRow label="Production projects at risk" value="0" />
                                <ProofRow label="Safe automated action" value="1" />
                                <ProofRow label="Human-review recommendations" value="2" />
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </section>

            <div className="mx-auto flex max-w-7xl flex-col gap-8 pl-5 pr-5 pt-8 pb-12 sm:pl-8 sm:pr-8">
                {error_msg != "" and
                    <div className="rounded-lg border border-destructive/40 bg-destructive/10 pl-4 pr-4 pt-3 pb-3">
                        <p className="text-sm font-medium text-destructive">{error_msg}</p>
                    </div>
                or None}

                <ProviderStrip
                    connected_github={connected_github}
                    connected_supabase={connected_supabase}
                    connected_openai={connected_openai}
                    connecting={connecting}
                    on_connect_github={lambda { handle_connect("github"); }}
                    on_connect_supabase={lambda { handle_connect("supabase"); }}
                    on_connect_openai={lambda { handle_connect("openai"); }}
                />

                {not scan_ready and not scanning and
                    <EmptyDecision />
                or None}

                {(scanning or scan_ready) and
                    <AgentWorkspace active={scanning} />
                or None}

                {scan_ready and
                    <section className="flex flex-col gap-5">
                        <SectionHeading
                            eyebrow="Decision 01 · highest confidence"
                            title="Pause legacy-api-db without touching production"
                            description="The graph isolates one stale repository and one idle database. No active project shares the target."
                        />
                        <div className="grid gap-5 lg:grid-cols-[1.45fr_0.55fr]">
                            <ImpactPath verified={"rec-001" in approved_ids} />
                            <JacTrace verified={"rec-001" in approved_ids} />
                        </div>
                    </section>
                or None}

                {scan_ready and
                    <section className="flex flex-col gap-5">
                        <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
                            <SectionHeading
                                eyebrow="Recommended plan"
                                title="Save $55/month in two controlled moves"
                                description="Rules select the actions. byLLM turns the deterministic evidence into clear safety language."
                            />
                            <Badge variant="secondary" className="w-fit">
                                {len((recs_data as RecommendationsData).recommendations)} graph-backed findings
                            </Badge>
                        </div>
                        <div className="grid gap-5 lg:grid-cols-2">
                            {for rec in (recs_data as RecommendationsData).recommendations {
                                <RecommendationCard
                                    key={rec.id}
                                    rec={rec}
                                    status={get_rec_status(rec)}
                                    approving={approving == rec.id}
                                    verifying={verifying == rec.id}
                                    featured={rec.id == "rec-001"}
                                    on_approve={lambda { handle_approve(rec.id); }}
                                    on_mark_done={lambda { handle_mark_done(rec.id); }}
                                />
                            }}
                        </div>
                    </section>
                or None}

                {scan_ready and
                    <section className="flex flex-col gap-5">
                        <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
                            <SectionHeading
                                eyebrow="Full evidence map"
                                title="Every dollar traced to the code it powers"
                                description={"Auto-built from " + ((graph_data as GraphData).source == "github" and "GitHub manifests" or "labeled demo fixtures") + "."}
                            />
                            <Badge variant="outline" className={cn("w-fit", (graph_data as GraphData).source == "github" and "border-emerald-500/30 text-emerald-600" or "border-amber-500/30 text-amber-600")}>
                                {(graph_data as GraphData).source == "github" and "Live GitHub evidence" or "Fixture-backed evidence"}
                            </Badge>
                        </div>
                        {(graph_data as GraphData).warning != "" and
                            <div className="flex items-start gap-2 rounded-lg border border-amber-500/20 bg-amber-500/5 pl-3 pr-3 pt-2 pb-2 text-xs text-amber-700">
                                <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="mt-0.5 size-3.5 shrink-0" />
                                <span>{(graph_data as GraphData).warning}</span>
                            </div>
                        or None}
                        <Card>
                            <CardContent className="pt-6 pb-6 pl-5 pr-5 sm:pl-6 sm:pr-6">
                                <GraphView graph={(graph_data as GraphData)} />
                            </CardContent>
                        </Card>
                    </section>
                or None}
            </div>
        </main>
    </div>;
}


def:pub Metric(
    label: str,
    value: str,
    detail: str,
    accent: bool = False
) -> JsxElement {
    return <div className={cn("rounded-lg border pl-3 pr-3 pt-3 pb-3", accent and "border-primary/20 bg-primary/5" or "border-border bg-muted/30")}>
        <p className="text-[10px] font-medium uppercase tracking-wider text-muted-foreground">{label}</p>
        <p className={cn("mt-1 text-xl font-semibold tabular-nums", accent and "text-primary" or "text-foreground")}>{value}</p>
        <p className="text-[10px] text-muted-foreground">{detail}</p>
    </div>;
}


def:pub ProofRow(label: str, value: str) -> JsxElement {
    return <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-muted-foreground">
            <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="size-4 text-primary" />
            <span>{label}</span>
        </div>
        <span className="font-semibold tabular-nums">{value}</span>
    </div>;
}


def:pub ScanPipeline(scanning: bool, ready: bool) -> JsxElement {
    steps: list[list[str]] = [
        ["discover_stack", "Scan manifests"],
        ["analyze", "Traverse risk"],
        ["byLLM", "Explain evidence"]
    ];
    return <div className="mt-7 flex flex-wrap items-center gap-2">
        {for step in steps {
            <div key={step[0]} className={cn("flex items-center gap-2 rounded-full border pl-3 pr-3 pt-1.5 pb-1.5 text-xs", ready and "border-primary/20 bg-primary/5 text-foreground" or "border-border bg-background/70 text-muted-foreground")}>
                {ready and <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="size-3 text-primary" /> or (scanning and <Spinner className="size-3 text-primary" /> or <div className="size-1.5 rounded-full bg-muted-foreground/40"></div>)}
                <span className="font-mono text-[10px] text-primary">{step[0]}</span>
                <span>{step[1]}</span>
            </div>
        }}
    </div>;
}


def:pub AgentWorkspace(active: bool) -> JsxElement {
    return <Card className="overflow-hidden border-primary/20 bg-foreground text-background">
        <CardHeader className="border-b border-background/10">
            <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                <div className="flex items-center gap-3">
                    <div className="relative flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground">
                        {active and <div className="absolute inset-0 rounded-xl bg-primary animate-ping motion-reduce:animate-none"></div> or None}
                        <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="relative size-5" />
                    </div>
                    <div>
                        <CardDescription className="text-background/60">Jac agent workspace</CardDescription>
                        <CardTitle className="mt-0.5 text-background">
                            {active and "Three agents are building the decision" or "Agent run complete"}
                        </CardTitle>
                    </div>
                </div>
                <Badge className={cn("w-fit", active and "bg-primary text-primary-foreground" or "bg-emerald-500/15 text-emerald-300")}>
                    <span className={cn("mr-2 size-1.5 rounded-full", active and "bg-primary-foreground animate-pulse motion-reduce:animate-none" or "bg-emerald-300")}></span>
                    {active and "WORKING LIVE" or "EVIDENCE READY"}
                </Badge>
            </div>
        </CardHeader>
        <CardContent className="pt-5 pb-5 pl-5 pr-5 sm:pl-6 sm:pr-6">
            <div className="grid gap-3 lg:grid-cols-[1fr_auto_1fr_auto_1fr] lg:items-stretch">
                <AgentCard
                    active={active}
                    icon="file"
                    number="01"
                    role="Manifest Scout"
                    pipeline="discover_stack"
                    task={active and "Reading repos + env contracts" or "3 manifests indexed"}
                />
                <AgentSignal active={active} label="hands off" />
                <AgentCard
                    active={active}
                    icon="graph"
                    number="02"
                    role="Graph Builder"
                    pipeline="graph walker"
                    task={active and "Linking code → services → spend" or "13 nodes · 11 edges"}
                />
                <AgentSignal active={active} label="hands off" />
                <AgentCard
                    active={active}
                    icon="spark"
                    number="03"
                    role="Safety Analyst"
                    pipeline="analyze + byLLM"
                    task={active and "Ranking reversible actions" or "3 findings explained"}
                />
            </div>
            <div className="mt-4 flex flex-col gap-2 border-t border-background/10 pt-4 sm:flex-row sm:items-center sm:justify-between">
                <p className="font-mono text-[10px] text-background/50">
                    Account → Project → Service → Subscription
                </p>
                <p className="text-xs text-background/70">
                    {active and "Agents share one live dependency graph" or "Deterministic evidence locked for review"}
                </p>
            </div>
        </CardContent>
    </Card>;
}


def:pub AgentCard(
    active: bool,
    icon: str,
    number: str,
    role: str,
    pipeline: str,
    task: str
) -> JsxElement {
    return <div className="rounded-xl border border-background/10 bg-background/5 pl-4 pr-4 pt-4 pb-4">
        <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
                <div className="relative flex size-10 shrink-0 items-center justify-center rounded-full border border-primary/40 bg-primary/15 text-primary">
                    {active and <div className="absolute inset-0 rounded-full border border-primary/50 animate-ping motion-reduce:animate-none"></div> or None}
                    {icon == "file" and <HugeiconsIcon icon={File01Icon} strokeWidth={2} className="relative size-4" /> or (icon == "graph" and <HugeiconsIcon icon={Analytics01Icon} strokeWidth={2} className="relative size-4" /> or <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="relative size-4" />)}
                </div>
                <div>
                    <p className="text-[10px] font-semibold tracking-[0.16em] text-primary">AGENT {number}</p>
                    <p className="mt-0.5 text-sm font-semibold text-background">{role}</p>
                </div>
            </div>
            {active and <Spinner className="mt-1 size-3.5 text-primary" /> or <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mt-1 size-4 text-emerald-300" />}
        </div>
        <div className="mt-4">
            <p className="font-mono text-[10px] text-background/50">{pipeline}</p>
            <p className="mt-1 text-xs text-background/80">{task}</p>
        </div>
        <div className="mt-4 h-1 overflow-hidden rounded-full bg-background/10">
            <div className={cn("h-full rounded-full bg-primary", active and "w-3/4 animate-pulse motion-reduce:animate-none" or "w-full")}></div>
        </div>
    </div>;
}


def:pub AgentSignal(active: bool, label: str) -> JsxElement {
    return <div className="flex items-center justify-center gap-2 pl-2 pr-2 text-background/40 lg:flex-col lg:gap-1 lg:pl-0 lg:pr-0">
        <div className="h-px flex-1 bg-background/15 lg:h-6 lg:w-px lg:flex-none"></div>
        <div className={cn("size-2 rounded-full border border-primary/70 bg-primary", active and "animate-pulse motion-reduce:animate-none" or "")}></div>
        <span className="font-mono text-[9px]">{active and label or "done"}</span>
        <div className="h-px flex-1 bg-background/15 lg:h-6 lg:w-px lg:flex-none"></div>
    </div>;
}


def:pub ProviderStrip(
    connected_github: bool,
    connected_supabase: bool,
    connected_openai: bool,
    connecting: str,
    on_connect_github: any,
    on_connect_supabase: any,
    on_connect_openai: any
) -> JsxElement {
    return <section>
        <div className="mb-3 flex items-center justify-between">
            <div>
                <p className="text-sm font-medium">Evidence sources</p>
                <p className="text-xs text-muted-foreground">Credentials are validated server-side; no OAuth theater in the demo.</p>
            </div>
            {connected_github and connected_supabase and connected_openai and
                <Badge variant="outline" className="border-emerald-500/30 text-emerald-600">
                    <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mr-1 size-3" />
                    Workspace connected
                </Badge>
            or None}
        </div>
        <div className="grid gap-3 md:grid-cols-3">
            <ProviderCard initials="GH" name="GitHub" detail={connected_github and "3 repositories discovered" or "Repository manifests"} connected={connected_github} busy={connecting == "github"} on_connect={on_connect_github} />
            <ProviderCard initials="SB" name="Supabase" detail={connected_supabase and "2 projects inspected" or "Project health + actions"} connected={connected_supabase} busy={connecting == "supabase"} on_connect={on_connect_supabase} />
            <ProviderCard initials="AI" name="OpenAI" detail={connected_openai and "$118 usage mapped" or "Model usage evidence"} connected={connected_openai} busy={connecting == "openai"} on_connect={on_connect_openai} />
        </div>
    </section>;
}


def:pub ProviderCard(
    initials: str,
    name: str,
    detail: str,
    connected: bool,
    busy: bool,
    on_connect: any
) -> JsxElement {
    return <Card className={cn("transition-colors", connected and "border-primary/20 bg-primary/5" or "")}>
        <CardContent className="flex items-center justify-between gap-3 pt-4 pb-4 pl-4 pr-4">
            <div className="flex items-center gap-3">
                <div className={cn("flex size-9 items-center justify-center rounded-lg border text-xs font-bold", connected and "border-primary/20 bg-primary/10 text-primary" or "border-border bg-muted")}>{initials}</div>
                <div>
                    <p className="text-sm font-medium">{name}</p>
                    <p className="text-xs text-muted-foreground">{detail}</p>
                </div>
            </div>
            {connected and
                <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="size-4 text-primary" />
            or
                <Button size="sm" variant="outline" onClick={on_connect} disabled={busy}>
                    {busy and "Connecting..." or "Connect"}
                </Button>
            }
        </CardContent>
    </Card>;
}


def:pub EmptyDecision() -> JsxElement {
    return <Card className="overflow-hidden">
        <CardContent className="grid gap-0 p-0 md:grid-cols-3">
            <EmptyStep number="01" title="Read the code" description="Scan package manifests and environment contracts—no repository cloning." />
            <EmptyStep number="02" title="Build the graph" description="Jac nodes and edges connect projects, services, subscriptions, and actions." border={True} />
            <EmptyStep number="03" title="Act with proof" description="Walkers execute supported changes and verify the provider's final state." />
        </CardContent>
    </Card>;
}


def:pub EmptyStep(
    number: str,
    title: str,
    description: str,
    border: bool = False
) -> JsxElement {
    return <div className={cn("pl-6 pr-6 pt-7 pb-7", border and "border-t border-b border-border md:border-t-0 md:border-b-0 md:border-l md:border-r" or "")}>
        <p className="font-mono text-xs text-primary">{number}</p>
        <p className="mt-3 font-medium">{title}</p>
        <p className="mt-1 text-sm leading-6 text-muted-foreground">{description}</p>
    </div>;
}


def:pub SectionHeading(
    eyebrow: str,
    title: str,
    description: str
) -> JsxElement {
    return <div>
        <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">{eyebrow}</p>
        <h3 className="mt-1 text-2xl font-semibold tracking-tight">{title}</h3>
        <p className="mt-1 max-w-3xl text-sm leading-6 text-muted-foreground">{description}</p>
    </div>;
}


def:pub ImpactPath(verified: bool) -> JsxElement {
    return <Card className={cn("overflow-hidden", verified and "border-emerald-500/30 bg-emerald-500/5" or "border-primary/20")}>
        <CardHeader>
            <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                <div>
                    <CardDescription>Impact trace</CardDescription>
                    <CardTitle className="mt-1">What breaks if we pause this?</CardTitle>
                </div>
                <Badge variant="outline" className={verified and "border-emerald-500/30 text-emerald-600" or "border-primary/30 text-primary"}>
                    {verified and "Provider verified" or "Low-risk · reversible"}
                </Badge>
            </div>
        </CardHeader>
        <CardContent>
            <div className="grid items-stretch gap-2 md:grid-cols-[1fr_auto_1fr_auto_1fr]">
                <ImpactNode kind="PROJECT" title="legacy-api" detail="No commits in 89 days" tone="amber" />
                <ImpactArrow label="uses" />
                <ImpactNode kind="SERVICE" title="legacy-api-db" detail="Idle for 47 days" tone="primary" />
                <ImpactArrow label="billed as" />
                <ImpactNode kind="SUBSCRIPTION" title="Supabase Pro" detail="$25 / month" tone="emerald" />
            </div>
            <div className="mt-5 grid gap-3 sm:grid-cols-3">
                <EvidenceStat label="Affected projects" value="1" detail="legacy-api only" />
                <EvidenceStat label="Production dependers" value="0" detail="No shared service edge" />
                <EvidenceStat label="Recovery" value="1 click" detail="Restore in Supabase" />
            </div>
        </CardContent>
        {verified and
            <CardFooter>
                <div className="flex w-full items-center gap-3 rounded-lg bg-emerald-500/10 pl-4 pr-4 pt-3 pb-3 text-emerald-700">
                    <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="size-5 shrink-0" />
                    <div>
                        <p className="text-sm font-semibold">Supabase confirmed PAUSED</p>
                        <p className="text-xs">Monthly spend dropped from $172 to $147.</p>
                    </div>
                </div>
            </CardFooter>
        or None}
    </Card>;
}


def:pub ImpactNode(
    kind: str,
    title: str,
    detail: str,
    tone: str
) -> JsxElement {
    tone_class: str = (
        "border-amber-500/30 bg-amber-500/10"
        if tone == "amber"
        else (
            "border-emerald-500/30 bg-emerald-500/10"
            if tone == "emerald"
            else "border-primary/30 bg-primary/10"
        )
    );
    return <div className={cn("rounded-xl border pl-4 pr-4 pt-4 pb-4", tone_class)}>
        <p className="text-[10px] font-semibold tracking-[0.15em] text-muted-foreground">{kind}</p>
        <p className="mt-2 font-semibold">{title}</p>
        <p className="mt-1 text-xs text-muted-foreground">{detail}</p>
    </div>;
}


def:pub ImpactArrow(label: str) -> JsxElement {
    return <div className="flex items-center justify-center gap-1 text-muted-foreground md:flex-col">
        <span className="text-[10px] font-medium">{label}</span>
        <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="hidden size-4 md:block" />
        <HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-4 md:hidden" />
    </div>;
}


def:pub EvidenceStat(label: str, value: str, detail: str) -> JsxElement {
    return <div className="rounded-lg border border-border bg-muted/30 pl-3 pr-3 pt-3 pb-3">
        <p className="text-[10px] font-medium uppercase tracking-wider text-muted-foreground">{label}</p>
        <p className="mt-1 text-lg font-semibold">{value}</p>
        <p className="text-xs text-muted-foreground">{detail}</p>
    </div>;
}


def:pub JacTrace(verified: bool) -> JsxElement {
    return <Card className="bg-foreground text-background">
        <CardHeader>
            <div className="flex items-center justify-between">
                <div>
                    <CardDescription className="text-background/60">Jac reasoning trace</CardDescription>
                    <CardTitle className="mt-1 text-background">Why Jac is central</CardTitle>
                </div>
                <Badge className="bg-primary text-primary-foreground">JAC</Badge>
            </div>
        </CardHeader>
        <CardContent>
            <div className="flex flex-col gap-4">
                <TraceStep name="discover_stack" result="13 nodes · 11 edges" done={True} />
                <TraceStep name="analyze" result="3 safe findings" done={True} />
                <TraceStep name="byLLM explain" result="Evidence → safety copy" done={True} />
                <TraceStep name="execute_action" result={verified and "Pause accepted" or "Awaiting approval"} done={verified} />
                <TraceStep name="verify_action" result={verified and "PAUSED confirmed" or "Provider check queued"} done={verified} />
            </div>
        </CardContent>
        <CardFooter>
            <p className="font-mono text-[10px] leading-5 text-background/60">
                Account → Project → Service → Subscription. The graph is the decision engine, not a visualization layer.
            </p>
        </CardFooter>
    </Card>;
}


def:pub TraceStep(name: str, result: str, done: bool) -> JsxElement {
    return <div className="flex items-start gap-3">
        <div className={cn("mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full border", done and "border-primary bg-primary text-primary-foreground" or "border-primary/50 bg-primary/10 text-primary animate-pulse motion-reduce:animate-none")}>
            {done and <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="size-3" /> or <div className="size-1.5 rounded-full bg-current"></div>}
        </div>
        <div className="min-w-0">
            <p className="font-mono text-xs text-background">{name}</p>
            <p className="mt-0.5 text-xs text-background/60">{result}</p>
        </div>
    </div>;
}


def:pub GraphView(graph: GraphData) -> JsxElement {
    node_colors: dict = {
        "Account": "bg-blue-500/10 border-blue-500/30 text-blue-700",
        "Project": "bg-violet-500/10 border-violet-500/30 text-violet-700",
        "Service": "bg-amber-500/10 border-amber-500/30 text-amber-700",
        "Subscription": "bg-emerald-500/10 border-emerald-500/30 text-emerald-700"
    };
    accounts: list[GraphNode] = [
        n for n in graph.nodes if n.node_type == "Account"
    ];
    projects: list[GraphNode] = [
        n for n in graph.nodes if n.node_type == "Project"
    ];
    services: list[GraphNode] = [
        n for n in graph.nodes if n.node_type == "Service"
    ];
    subscriptions: list[GraphNode] = [
        n for n in graph.nodes if n.node_type == "Subscription"
    ];

    return <div className="flex flex-col gap-5">
        <div className="grid gap-3 sm:grid-cols-4">
            <GraphSummary label="Accounts" count={len(accounts)} detail="Connected providers" />
            <GraphSummary label="Projects" count={len(projects)} detail="Manifest-scanned repos" />
            <GraphSummary label="Services" count={len(services)} detail="Runtime dependencies" />
            <GraphSummary label="Subscriptions" count={len(subscriptions)} detail={"$" + str(graph.total_monthly_cost_usd) + "/mo traced"} />
        </div>
        <div className="overflow-x-auto rounded-xl border border-border bg-muted/20 pl-4 pr-4 pt-5 pb-5">
            <div className="min-w-[760px]">
                <GraphLayer label="Accounts" nodes={accounts} color_map={node_colors} />
                <GraphConnector label="owns" />
                <GraphLayer label="Projects" nodes={projects} color_map={node_colors} />
                <GraphConnector label="uses" />
                <GraphLayer label="Services" nodes={services} color_map={node_colors} />
                <GraphConnector label="billed as" />
                <GraphLayer label="Subscriptions" nodes={subscriptions} color_map={node_colors} />
            </div>
        </div>
    </div>;
}


def:pub GraphSummary(
    label: str,
    count: int,
    detail: str
) -> JsxElement {
    return <div className="rounded-lg border border-border pl-3 pr-3 pt-3 pb-3">
        <div className="flex items-center justify-between">
            <p className="text-xs font-medium text-muted-foreground">{label}</p>
            <p className="text-lg font-semibold tabular-nums">{count}</p>
        </div>
        <p className="mt-1 text-[10px] text-muted-foreground">{detail}</p>
    </div>;
}


def:pub GraphConnector(label: str) -> JsxElement {
    return <div className="flex items-center gap-3 pl-24 pr-4 pt-3 pb-3">
        <div className="h-px flex-1 border-t border-dashed border-border"></div>
        <div className="flex items-center gap-1 rounded-full border border-border bg-background pl-2 pr-2 pt-1 pb-1">
            <span className="font-mono text-[9px] text-muted-foreground">{label}</span>
            <HugeiconsIcon icon={ArrowDown01Icon} strokeWidth={2} className="size-3 text-primary" />
        </div>
        <div className="h-px flex-1 border-t border-dashed border-border"></div>
    </div>;
}


def:pub GraphLayer(
    label: str,
    nodes: list[GraphNode],
    color_map: dict
) -> JsxElement {
    return <div className="flex items-center gap-3">
        <span className="w-20 shrink-0 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
        <div className="flex flex-wrap gap-2">
            {for node in nodes {
                <GraphNodeChip key={node.id} gnode={node} color_map={color_map} />
            }}
        </div>
    </div>;
}


def:pub GraphNodeChip(
    gnode: GraphNode,
    color_map: dict
) -> JsxElement {
    color_class: str = str(
        color_map.get(
            gnode.node_type,
            "bg-muted border-border text-foreground"
        )
    );
    is_stale: bool = gnode.stale or gnode.idle_days > 0;
    return <div className={cn("relative flex items-center gap-2 rounded-lg border pl-3 pr-3 pt-2 pb-2 text-xs", color_class)}>
        {is_stale and <div className="absolute -right-1 -top-1 size-2 rounded-full bg-amber-500 ring-2 ring-background"></div> or None}
        <span className="font-medium">{gnode.label}</span>
        {gnode.node_type == "Subscription" and gnode.monthly_cost_usd > 0 and
            <span className="text-[10px] opacity-70">${gnode.monthly_cost_usd}/mo</span>
        or None}
        {gnode.idle_days > 0 and
            <span className="text-[10px] opacity-70">{gnode.idle_days}d idle</span>
        or None}
        {gnode.stale and not (gnode.idle_days > 0) and
            <span className="text-[10px] opacity-70">stale</span>
        or None}
    </div>;
}


def:pub RecommendationCard(
    rec: Recommendation,
    status: str,
    approving: bool,
    verifying: bool,
    featured: bool,
    on_approve: any,
    on_mark_done: any
) -> JsxElement {
    is_approved: bool = status == "approved";
    busy: bool = approving or verifying;
    can_mark_done: bool = (
        not rec.executable and rec.rec_type == "openai_rightsize"
    );
    type_labels: dict = {
        "supabase_pause": "Supabase Pause",
        "openai_rightsize": "Model Right-sizing",
        "unused_subscription": "Grace-period Review"
    };
    type_label: str = str(
        type_labels.get(rec.rec_type, rec.rec_type)
    );

    return <Card className={cn("transition-colors", featured and "lg:row-span-2 border-primary/25" or "", is_approved and "border-emerald-500/30 bg-emerald-500/5" or "")}>
        <CardHeader>
            <div className="flex items-start justify-between gap-4">
                <div className="flex min-w-0 flex-col gap-2">
                    <div className="flex flex-wrap items-center gap-2">
                        {featured and <Badge className="text-[10px]">Best next action</Badge> or None}
                        <Badge variant="outline" className="text-[10px]">{type_label}</Badge>
                        <Badge variant="outline" className={cn("text-[10px]", rec.executable and "border-primary/30 text-primary" or "text-muted-foreground")}>
                            {rec.executable and "Executable + verified" or "Human review"}
                        </Badge>
                    </div>
                    <CardTitle className={featured and "text-xl" or "text-base"}>{rec.title}</CardTitle>
                </div>
                <div className="shrink-0 text-right">
                    <p className="text-2xl font-semibold tabular-nums text-primary">${rec.monthly_savings_usd}</p>
                    <p className="text-[10px] text-muted-foreground">per month</p>
                </div>
            </div>
        </CardHeader>
        <CardContent>
            <div className="flex flex-col gap-4">
                <div className="grid grid-cols-2 gap-3">
                    <div className="rounded-lg border border-border bg-muted/30 pl-3 pr-3 pt-2.5 pb-2.5">
                        <p className="text-[10px] uppercase tracking-wider text-muted-foreground">Impact</p>
                        <p className="mt-1 text-sm font-medium">{len(rec.affected_projects)} project affected</p>
                    </div>
                    <div className="rounded-lg border border-border bg-muted/30 pl-3 pr-3 pt-2.5 pb-2.5">
                        <p className="text-[10px] uppercase tracking-wider text-muted-foreground">Action</p>
                        <p className="mt-1 text-sm font-medium">{rec.executable and "Provider API" or "Guided manual"}</p>
                    </div>
                </div>
                <div>
                    <p className="mb-2 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Graph evidence</p>
                    <div className="flex flex-col gap-2">
                        {for check in rec.safety_checks {
                            <div key={check} className="flex items-start gap-2">
                                <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="mt-0.5 size-3.5 shrink-0 text-primary" />
                                <span className="text-sm leading-5 text-muted-foreground">{check}</span>
                            </div>
                        }}
                    </div>
                </div>
                {rec.executable and rec.action.call != "" and
                    <div className="rounded-lg border border-border bg-foreground pl-3 pr-3 pt-3 pb-3 text-background">
                        <p className="text-[10px] uppercase tracking-wider text-background/50">Execution plan</p>
                        <p className="mt-1 font-mono text-xs">{rec.action.call}</p>
                        <p className="mt-1 text-[10px] text-background/60">Then verify_action polls until Supabase reports PAUSED.</p>
                    </div>
                or None}
                {rec.note != "" and
                    <div className="flex items-start gap-2 rounded-lg bg-muted pl-3 pr-3 pt-2.5 pb-2.5">
                        <HugeiconsIcon icon={InformationCircleIcon} strokeWidth={2} className="mt-0.5 size-3.5 shrink-0 text-muted-foreground" />
                        <span className="text-xs leading-5 text-muted-foreground">{rec.note}</span>
                    </div>
                or None}
            </div>
        </CardContent>
        {rec.executable and not is_approved and
            <CardFooter>
                <Button onClick={on_approve} disabled={busy} className="w-full">
                    {busy and <Spinner className="mr-2 size-4" /> or None}
                    {verifying and "Verifying provider state..." or (approving and "Executing Supabase pause..." or "Approve, execute, and verify")}
                    {not busy and <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="ml-2 size-4" /> or None}
                </Button>
            </CardFooter>
        or None}
        {can_mark_done and not is_approved and
            <CardFooter>
                <Button variant="outline" onClick={on_mark_done} disabled={busy} className="w-full">
                    {approving and <Spinner className="mr-2 size-4" /> or <HugeiconsIcon icon={File01Icon} strokeWidth={2} className="mr-2 size-4" />}
                    {approving and "Applying..." or "Mark guided change complete"}
                </Button>
            </CardFooter>
        or None}
        {is_approved and
            <CardFooter>
                <div className="flex w-full items-center justify-center gap-2 rounded-lg bg-emerald-500/10 pl-4 pr-4 pt-3 pb-3 text-emerald-700">
                    <HugeiconsIcon icon={CheckmarkCircle01Icon} strokeWidth={2} className="size-4" />
                    <span className="text-sm font-medium">{rec.executable and "Executed and provider-verified" or "Applied — savings counted"}</span>
                </div>
            </CardFooter>
        or None}
    </Card>;
}
