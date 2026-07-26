"""HTTP connector functions for SUBway.
Steven's implementation — imported by Noriaki's walkers.
Signatures agreed up front; fixture fallback fires when DEMO_MODE=true
or the relevant token is missing, so the app always works offline.
"""

import os;
import json;
import time;
import base64;
import urllib.request;

def _demo_mode() -> bool {
    return os.environ.get("DEMO_MODE", "false").lower() == "true";
}

def _get_json(url: str, token: str, accept: str = "application/json") -> any {
    req: any = urllib.request.Request(url);
    req.add_header("Authorization", f"Bearer {token}");
    req.add_header("Accept", accept);
    resp: any = urllib.request.urlopen(req);
    return json.loads(resp.read().decode());
}

def _post_json(url: str, token: str) -> any {
    req: any = urllib.request.Request(url, data=b"{}", method="POST");
    req.add_header("Authorization", f"Bearer {token}");
    req.add_header("Content-Type", "application/json");
    resp: any = urllib.request.urlopen(req);
    body: str = resp.read().decode();
    if body {
        return json.loads(body);
    }
    return {"status_code": resp.status};
}

def list_repos() -> list {
    """Repos of the demo account, with pushed_at for the staleness rule."""
    token: str = os.environ.get("GITHUB_TOKEN", "");
    user: str = os.environ.get("GITHUB_USERNAME", "syang0624");
    if _demo_mode() or not token {
        return _fixture_repos();
    }
    try {
        repos: any = _get_json(f"https://api.github.com/users/{user}/repos?per_page=100", token, "application/vnd.github+json");
        result: list = [];
        for r in (repos as list) {
            rd: dict = r as dict;
            result.append({
                "name": rd.get("name", ""),
                "full_name": rd.get("full_name", ""),
                "default_branch": rd.get("default_branch", "main"),
                "pushed_at": rd.get("pushed_at", "")
            });
        }
        return result;
    } except Exception {
        return _fixture_repos();
    }
}

def fetch_manifests(repo: str) -> dict {
    """Shallow scan: manifest files plus parsed deps and env var names."""
    token: str = os.environ.get("GITHUB_TOKEN", "");
    if _demo_mode() or not token {
        return _fixture_manifests(repo);
    }
    try {
        contents: any = _get_json(f"https://api.github.com/repos/{repo}/contents", token, "application/vnd.github+json");
        manifest_files: list = [];
        for item in (contents as list) {
            fname: str = (item as dict).get("name", "");
            if fname in ["package.json", "requirements.txt", ".env.example", "Pipfile"] {
                manifest_files.append(fname);
            }
        }
        deps: list = [];
        env_vars: list = [];
        if "package.json" in manifest_files {
            pkg_text: str = _fetch_file(repo, "package.json", token);
            if pkg_text {
                pkg: dict = json.loads(pkg_text) as dict;
                for dep_name in (pkg.get("dependencies", {}) as dict).keys() {
                    deps.append(dep_name);
                }
            }
        }
        if "requirements.txt" in manifest_files {
            req_text: str = _fetch_file(repo, "requirements.txt", token);
            for line in req_text.split("\n") {
                clean: str = line.strip();
                if clean and not clean.startswith("#") {
                    deps.append(clean.split("==")[0].split(">=")[0].strip());
                }
            }
        }
        if ".env.example" in manifest_files {
            env_text: str = _fetch_file(repo, ".env.example", token);
            for line in env_text.split("\n") {
                clean: str = line.strip();
                if clean and not clean.startswith("#") and "=" in clean {
                    env_vars.append(clean.split("=")[0].strip());
                }
            }
        }
        return {"repo": repo, "manifest_files": manifest_files, "deps": deps, "env_vars": env_vars};
    } except Exception as e {
        return {"repo": repo, "manifest_files": [], "deps": [], "env_vars": [], "error": str(e)};
    }
}

def _fetch_file(repo: str, path: str, token: str) -> str {
    try {
        data: any = _get_json(f"https://api.github.com/repos/{repo}/contents/{path}", token, "application/vnd.github+json");
        content: str = (data as dict).get("content", "");
        if content {
            return base64.b64decode(content).decode();
        }
        return "";
    } except Exception {
        return "";
    }
}

def list_supabase_projects() -> list {
    token: str = os.environ.get("SUPABASE_ACCESS_TOKEN", "");
    if _demo_mode() or not token {
        return _fixture_supabase_projects();
    }
    try {
        return _get_json("https://api.supabase.com/v1/projects", token) as list;
    } except Exception {
        return _fixture_supabase_projects();
    }
}

def pause_project(ref: str) -> dict {
    """The one real execution of the demo. Demo mode simulates success."""
    token: str = os.environ.get("SUPABASE_ACCESS_TOKEN", "");
    if _demo_mode() or not token {
        return {"status": "paused", "ref": ref, "demo_mode": True};
    }
    try {
        result: any = _post_json(f"https://api.supabase.com/v1/projects/{ref}/pause", token);
        return {"status": "paused", "ref": ref, "response": result};
    } except Exception as e {
        return {"status": "error", "ref": ref, "error": str(e)};
    }
}

def restore_project(ref: str) -> dict {
    """Undo for rehearsals and post-demo cleanup."""
    token: str = os.environ.get("SUPABASE_ACCESS_TOKEN", "");
    if _demo_mode() or not token {
        return {"status": "restoring", "ref": ref, "demo_mode": True};
    }
    try {
        result: any = _post_json(f"https://api.supabase.com/v1/projects/{ref}/restore", token);
        return {"status": "restoring", "ref": ref, "response": result};
    } except Exception as e {
        return {"status": "error", "ref": ref, "error": str(e)};
    }
}

def get_project_status(ref: str) -> dict {
    token: str = os.environ.get("SUPABASE_ACCESS_TOKEN", "");
    if _demo_mode() or not token {
        return _fixture_project_status(ref);
    }
    try {
        return _get_json(f"https://api.supabase.com/v1/projects/{ref}", token) as dict;
    } except Exception as e {
        return {"error": str(e), "ref": ref, "status": "unknown"};
    }
}

def get_openai_usage() -> dict {
    """Org-level costs for the last 30 days. Needs an admin key (sk-admin-...)."""
    key: str = os.environ.get("OPENAI_ADMIN_KEY", "");
    if _demo_mode() or not key {
        return _fixture_openai_usage();
    }
    try {
        start: int = int(time.time()) - (30 * 86400);
        return _get_json(f"https://api.openai.com/v1/organization/costs?start_time={start}&limit=31", key) as dict;
    } except Exception {
        return _fixture_openai_usage();
    }
}

def _fixture_repos() -> list {
    return [
        {"name": "tasktomo", "full_name": "syang0624/tasktomo", "default_branch": "main", "pushed_at": "2026-07-24T18:12:00Z"},
        {"name": "legacy-api", "full_name": "syang0624/legacy-api", "default_branch": "main", "pushed_at": "2026-04-28T09:30:00Z"},
        {"name": "portfolio-site", "full_name": "syang0624/portfolio-site", "default_branch": "main", "pushed_at": "2026-07-10T21:45:00Z"}
    ];
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
    return fixtures.get(repo, {"repo": repo, "manifest_files": [], "deps": [], "env_vars": []});
}

def _fixture_supabase_projects() -> list {
    return [
        {
            "id": "tasktomo-db-ref0",
            "name": "tasktomo-db",
            "status": "ACTIVE_HEALTHY",
            "last_activity_at": "2026-07-25T14:00:00Z",
            "cpu_utilization_pct": 34,
            "db_size_mb": 412,
            "plan": "pro",
            "monthly_cost_usd": 25
        },
        {
            "id": "legacy-api-db-ref0",
            "name": "legacy-api-db",
            "status": "ACTIVE_HEALTHY",
            "last_activity_at": "2026-06-09T08:15:00Z",
            "cpu_utilization_pct": 2,
            "db_size_mb": 87,
            "plan": "pro",
            "monthly_cost_usd": 25
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
            {"model": "gpt-4o", "cost_usd": 102, "requests": 3140, "used_by": ["tasktomo"]},
            {"model": "gpt-4o-mini", "cost_usd": 16, "requests": 18900, "used_by": ["portfolio-site"]}
        ]
    };
}
