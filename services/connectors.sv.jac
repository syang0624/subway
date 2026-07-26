"""HTTP connector functions for SUBway.
Steven's implementation — imported by Noriaki's walkers.
Signatures agreed up front. Demo mode returns fixture data.
Real API calls fire when tokens are present in the environment.
"""

import os;
import json;
import urllib.request;

def fetch_manifests(repo: str) -> dict {
    token: str = os.environ.get("GITHUB_TOKEN", "");
    if not token {
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
        for item in (contents as list) {
            name: str = (item as dict).get("name", "");
            if name in ["package.json", "requirements.txt", ".env.example", "Pipfile"] {
                manifest_files.append(name);
            }
        }
        return {"repo": repo, "manifest_files": manifest_files};
    } except Exception as e {
        return {"repo": repo, "manifest_files": [], "error": str(e)};
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
        result: any = json.loads(resp.read().decode());
        return result as dict;
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
        return result as dict;
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
