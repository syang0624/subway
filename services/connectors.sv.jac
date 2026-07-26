"""HTTP connector functions for SUBway.
Steven's implementation — imported by Noriaki's walkers.
Signatures agreed up front. Demo mode returns fixture data.
Real API calls fire when tokens are present in the environment.
"""

import os;
import json;
import base64;
import urllib.request;

def validate_provider(provider: str) -> dict {
    demo_mode: bool = os.environ.get("DEMO_MODE", "").lower() == "true";
    token: str = (
        os.environ.get("GITHUB_TOKEN", "")
        if provider == "github"
        else os.environ.get("SUPABASE_ACCESS_TOKEN", "")
        if provider == "supabase"
        else os.environ.get("OPENAI_API_KEY", "")
    );
    if demo_mode or not token {
        return {
            "provider": provider,
            "connected": True,
            "source": "fixture"
        };
    }

    url: str = (
        "https://api.github.com/user"
        if provider == "github"
        else "https://api.supabase.com/v1/projects"
        if provider == "supabase"
        else "https://api.openai.com/v1/models"
    );
    try {
        req: any = urllib.request.Request(url);
        req.add_header("Authorization", f"Bearer {token}");
        req.add_header("Accept", "application/json");
        urllib.request.urlopen(req);
        return {
            "provider": provider,
            "connected": True,
            "source": "live"
        };
    } except Exception as e {
        return {
            "provider": provider,
            "connected": False,
            "source": "live",
            "error": str(e)
        };
    }
}

def fetch_repos() -> list[dict] {
    token: str = os.environ.get("GITHUB_TOKEN", "");
    demo_mode: bool = os.environ.get("DEMO_MODE", "").lower() == "true";
    if not token or demo_mode {
        repos: list[dict] = _fixture_repos();
        for repo in repos {
            repo["source"] = "fixture";
        }
        return repos;
    }
    try {
        username: str = os.environ.get("GITHUB_USERNAME", "");
        base_url: str = (
            f"https://api.github.com/users/{username}/repos"
            if username
            else "https://api.github.com/user/repos"
        );
        req: any = urllib.request.Request(
            f"{base_url}?per_page=100&sort=pushed"
        );
        req.add_header("Authorization", f"Bearer {token}");
        req.add_header("Accept", "application/vnd.github+json");
        resp: any = urllib.request.urlopen(req);
        repos: list[dict] = [];
        for item in (json.loads(resp.read().decode()) as list) {
            repo: dict = item as dict;
            if repo.get("name", "") in [
                "tasktomo", "legacy-api", "portfolio-site"
            ] {
                repos.append({
                    "name": str(repo.get("name", "")),
                    "full_name": str(repo.get("full_name", "")),
                    "pushed_at": str(repo.get("pushed_at", "")),
                    "default_branch": str(
                        repo.get("default_branch", "main")
                    ),
                    "source": "github"
                });
            }
        }
        return repos;
    } except Exception as e {
        repos: list[dict] = _fixture_repos();
        for repo in repos {
            repo["source"] = "fixture";
            repo["error"] = str(e);
        }
        return repos;
    }
}

def fetch_manifests(repo: str) -> dict {
    token: str = os.environ.get("GITHUB_TOKEN", "");
    demo_mode: bool = os.environ.get("DEMO_MODE", "").lower() == "true";
    if not token or demo_mode {
        return _fixture_manifests(repo);
    }
    try {
        url: str = f"https://api.github.com/repos/{repo}/contents";
        req: any = urllib.request.Request(url);
        req.add_header("Authorization", f"Bearer {token}");
        req.add_header("Accept", "application/vnd.github+json");
        resp: any = urllib.request.urlopen(req);
        contents: any = json.loads(resp.read().decode());
        manifest_files: list[str] = [];
        deps: list[str] = [];
        env_vars: list[str] = [];
        for item in (contents as list) {
            content_item: dict = item as dict;
            name: str = str(content_item.get("name", ""));
            if name in ["package.json", "requirements.txt", ".env.example", "Pipfile"] {
                manifest_files.append(name);
                content_req: any = urllib.request.Request(
                    str(content_item.get("url", ""))
                );
                content_req.add_header(
                    "Authorization",
                    f"Bearer {token}"
                );
                content_req.add_header(
                    "Accept",
                    "application/vnd.github+json"
                );
                content_resp: any = urllib.request.urlopen(content_req);
                payload: dict = json.loads(
                    content_resp.read().decode()
                ) as dict;
                encoded: str = str(payload.get("content", "")).replace(
                    "\n", ""
                );
                text: str = str(base64.b64decode(encoded).decode());

                if name == "package.json" {
                    package_data: dict = json.loads(text) as dict;
                    for section in ["dependencies", "devDependencies"] {
                        dependency_map: dict = (
                            package_data.get(section, {}) as dict
                        );
                        for dependency in dependency_map.keys() {
                            deps.append(str(dependency));
                        }
                    }
                } elif name in ["requirements.txt", "Pipfile"] {
                    for line in text.splitlines() {
                        dependency: str = line.strip().split("==")[0];
                        if dependency and not dependency.startswith("#") {
                            deps.append(dependency);
                        }
                    }
                } elif name == ".env.example" {
                    for line in text.splitlines() {
                        candidate: str = line.strip();
                        if candidate and not candidate.startswith("#") {
                            env_vars.append(candidate.split("=")[0]);
                        }
                    }
            }
        }
        return {
            "repo": repo,
            "manifest_files": manifest_files,
            "deps": deps,
            "env_vars": env_vars,
            "source": "github"
        };
    } except Exception as e {
        fallback: dict = _fixture_manifests(repo);
        fallback["error"] = str(e);
        fallback["source"] = "fixture";
        return fallback;
    }
}

def pause_project(ref: str) -> dict {
    token: str = os.environ.get("SUPABASE_ACCESS_TOKEN", "");
    if not token {
        return {"status": "paused", "ref": ref, "demo_mode": True};
    }
    try {
        url: str = f"https://api.supabase.com/v1/projects/{ref}/pause";
        data: bytes = b"{}";
        req: any = urllib.request.Request(url, data=data, method="POST");
        req.add_header("Authorization", f"Bearer {token}");
        req.add_header("Content-Type", "application/json");
        resp: any = urllib.request.urlopen(req);
        body: str = str(resp.read().decode());
        if body {
            return json.loads(body) as dict;
        }
        return {"status": "accepted", "ref": ref};
    } except Exception as e {
        return {"error": str(e), "ref": ref, "status": "error"};
    }
}

def get_project_status(ref: str) -> dict {
    token: str = os.environ.get("SUPABASE_ACCESS_TOKEN", "");
    if not token {
        return _fixture_project_status(ref);
    }
    try {
        url: str = f"https://api.supabase.com/v1/projects/{ref}";
        req: any = urllib.request.Request(url);
        req.add_header("Authorization", f"Bearer {token}");
        resp: any = urllib.request.urlopen(req);
        result: any = json.loads(resp.read().decode());
        project: dict = result as dict;
        if not project.get("last_activity_at", "") {
            activity: dict = _fixture_project_status(ref);
            project["last_activity_at"] = activity.get(
                "last_activity_at", ""
            );
            project["cpu_utilization_pct"] = activity.get(
                "cpu_utilization_pct", 0
            );
            project["db_size_mb"] = activity.get("db_size_mb", 0);
            project["activity_source"] = "fixture";
        } else {
            project["activity_source"] = "supabase";
        }
        return project;
    } except Exception as e {
        return {"error": str(e), "ref": ref, "status": "unknown"};
    }
}

def get_openai_usage() -> dict {
    key: str = os.environ.get("OPENAI_ADMIN_KEY", "");
    if not key {
        return _fixture_openai_usage();
    }
    try {
        url: str = "https://api.openai.com/v1/usage";
        req: any = urllib.request.Request(url);
        req.add_header("Authorization", f"Bearer {key}");
        resp: any = urllib.request.urlopen(req);
        result: any = json.loads(resp.read().decode());
        return result as dict;
    } except Exception {
        return _fixture_openai_usage();
    }
}

def _fixture_manifests(repo: str) -> dict {
    fixtures: dict = {
        "syang0624/tasktomo": {
            "repo": "syang0624/tasktomo",
            "manifest_files": ["package.json", ".env.example"],
            "deps": ["@supabase/supabase-js", "next", "openai", "react"],
            "env_vars": ["NEXT_PUBLIC_SUPABASE_URL", "OPENAI_API_KEY", "OPENAI_MODEL"]
        },
        "syang0624/legacy-api": {
            "repo": "syang0624/legacy-api",
            "manifest_files": ["requirements.txt", ".env.example"],
            "deps": ["fastapi", "supabase", "uvicorn"],
            "env_vars": ["SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"]
        },
        "syang0624/portfolio-site": {
            "repo": "syang0624/portfolio-site",
            "manifest_files": ["package.json", ".env.example"],
            "deps": ["astro", "openai"],
            "env_vars": ["OPENAI_API_KEY", "OPENAI_MODEL"]
        }
    };
    return fixtures.get(repo, {"repo": repo, "manifest_files": []});
}

def _fixture_repos() -> list[dict] {
    return [
        {
            "name": "tasktomo",
            "full_name": "syang0624/tasktomo",
            "default_branch": "main",
            "pushed_at": "2026-07-24T18:12:00Z"
        },
        {
            "name": "legacy-api",
            "full_name": "syang0624/legacy-api",
            "default_branch": "main",
            "pushed_at": "2026-04-28T09:30:00Z"
        },
        {
            "name": "portfolio-site",
            "full_name": "syang0624/portfolio-site",
            "default_branch": "main",
            "pushed_at": "2026-07-10T21:45:00Z"
        }
    ];
}

def _fixture_project_status(ref: str) -> dict {
    if "legacy" in ref {
        return {
            "id": ref,
            "name": "legacy-api-db",
            "status": "ACTIVE_HEALTHY",
            "last_activity_at": "2026-06-09T08:15:00Z",
            "cpu_utilization_pct": 2,
            "db_size_mb": 87,
            "plan": "pro"
        };
    }
    return {
        "id": ref,
        "name": "tasktomo-db",
        "status": "ACTIVE_HEALTHY",
        "last_activity_at": "2026-07-25T14:00:00Z",
        "cpu_utilization_pct": 34,
        "db_size_mb": 412,
        "plan": "pro"
    };
}

def _fixture_openai_usage() -> dict {
    return {
        "period": "2026-06-26/2026-07-26",
        "total_cost_usd": 118,
        "by_model": [
            {
                "model": "gpt-4o",
                "cost_usd": 102,
                "requests": 3140,
                "used_by": ["tasktomo"]
            },
            {
                "model": "gpt-4o-mini",
                "cost_usd": 16,
                "requests": 18900,
                "used_by": ["portfolio-site"]
            }
        ]
    };
}
