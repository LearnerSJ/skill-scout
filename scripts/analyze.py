#!/usr/bin/env python3
"""Analyze usage log → suggest installable skills from skills.sh.

Outputs JSON to stdout for Claude to read. Claude then presents to user.
"""
import json
import math
import os
import re
import sys
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOG = ROOT / "data" / "usage.jsonl"
INSTALLED_DIRS = [
    Path.home() / ".claude" / "skills",
    Path.home() / ".agents" / "skills",
]

STOPWORDS = {
    "the","a","an","is","are","be","was","were","been","being","to","of","in","on",
    "for","and","or","with","at","by","from","as","into","about","but","if","then",
    "i","you","my","me","we","us","they","them","he","she","it","its","our","your",
    "this","that","these","those","do","does","did","done","doing","can","could",
    "should","would","will","shall","may","might","must","how","what","why","when",
    "where","who","which","not","no","yes","so","up","out","over","just",
    "use","using","used","have","has","had","get","got","run","running","make","made",
    "npx","skills","add","skill","claude","please","help","need","want","like","want",
    "thanks","thank","ok","okay","sure","cool","nice","good","great","fine","work",
    "works","working","here","there","now","later","also","too","very","really",
    # skill-scout's own command + subcommands — self-referential, not workflow signal
    "skill-scout","scout","scan","status","daily","manual","install","clear","mode",
}

def installed_skills() -> set[str]:
    found = set()
    for d in INSTALLED_DIRS:
        if d.exists():
            for child in d.iterdir():
                if child.is_dir():
                    found.add(child.name.lower())
    return found

# A logged "prompt" starting with one of these tags is harness-injected (task
# notifications, system reminders, command stdout) — it carries no user intent
# and is dropped entirely so its boilerplate doesn't pollute keyword scoring.
NOISE_PREFIXES = (
    "<task-notification",
    "<system-reminder",
    "<local-command-stdout",
    "<local-command-stderr",
    "<command-stdout",
    "<command-stderr",
)

# Slash-command invocations log the full injected skill-body markdown (headings
# like "status", "summary", "output", "mode", ...). That body is pure noise, so
# we keep only the command name + args and discard everything else.
_CMD_NAME_RE = re.compile(r"<command-name>(.*?)</command-name>", re.DOTALL)
_CMD_ARGS_RE = re.compile(r"<command-args>(.*?)</command-args>", re.DOTALL)
# Inline tag blocks / stray tags appended to an otherwise-real prompt.
_TAG_BLOCK_RE = re.compile(r"<([a-zA-Z][\w-]*)\b[^>]*>.*?</\1>", re.DOTALL)
_STRAY_TAG_RE = re.compile(r"</?[a-zA-Z][\w-]*\b[^>]*>")


def _clean_prompt(p: str) -> str:
    """Reduce a logged prompt to user intent only.

    Returns "" for records that should be skipped (harness noise / empty).
    """
    s = (p or "").strip()
    if not s:
        return ""
    if s.lower().startswith(NOISE_PREFIXES):
        return ""
    low = s.lower()
    # Slash command: keep only the command name + args, drop the injected body.
    if "<command-name>" in low or "<command-message>" in low:
        parts = []
        for rx in (_CMD_NAME_RE, _CMD_ARGS_RE):
            m = rx.search(s)
            if m and m.group(1).strip():
                parts.append(m.group(1).strip())
        return " ".join(parts)
    # Real prompt: strip embedded tag blocks (e.g. appended system reminders).
    s = _TAG_BLOCK_RE.sub(" ", s)
    s = _STRAY_TAG_RE.sub(" ", s)
    return s.strip()


def read_prompts(limit: int = 200) -> list[str]:
    if not LOG.exists():
        return []
    lines = LOG.read_text(encoding="utf-8", errors="ignore").splitlines()[-limit:]
    out = []
    for ln in lines:
        try:
            rec = json.loads(ln)
        except Exception:
            continue
        cleaned = _clean_prompt(rec.get("payload", {}).get("prompt") or "")
        if cleaned:
            out.append(cleaned)
    return out

def _tokenize(text: str) -> list[str]:
    return [w for w in re.findall(r"[a-zA-Z][a-zA-Z0-9_-]{2,}", text.lower())
            if w not in STOPWORDS]

def top_keywords(prompts: list[str], k: int = 10) -> list[tuple[str, int]]:
    """Score = doc-frequency * log(1 + term-frequency). Favors terms that
    recur across many prompts AND appear often — the actual themes of
    someone's workflow, not one-off tokens. Includes bigrams."""
    if not prompts:
        return []

    tf = Counter()           # term -> total occurrences across all prompts
    df = Counter()           # term -> # of prompts containing it
    n_docs = len(prompts)

    for p in prompts:
        toks = _tokenize(p)
        bigrams = [f"{a} {b}" for a, b in zip(toks, toks[1:])]
        terms = toks + bigrams
        tf.update(terms)
        df.update(set(terms))

    # Require DF >= 2 (theme, not one-off) OR very high TF.
    min_df = 2 if n_docs >= 5 else 1

    scored = []
    for term, term_tf in tf.items():
        term_df = df[term]
        if term_df < min_df and term_tf < 3:
            continue
        # Boost bigrams slightly — they're more specific than unigrams.
        bigram_boost = 1.4 if " " in term else 1.0
        score = term_df * math.log(1 + term_tf) * bigram_boost
        scored.append((term, score, term_tf, term_df))

    scored.sort(key=lambda x: -x[1])
    return [(t, tf_) for t, _, tf_, _ in scored[:k]]

def search_marketplace(query: str, limit: int = 5) -> list[dict]:
    """Search GitHub for Claude skill repos matching query. Filters to repos
    that look like actual skills (topic claude-skill / claude-code, or
    'skill' in name + 'claude' in description)."""
    try:
        # Restrict to repos topic-tagged for Claude skills.
        q = f'{query} topic:claude-skill in:name,description'
        url = f"https://api.github.com/search/repositories?q={urllib.parse.quote(q)}&per_page={limit}&sort=stars"
        req = urllib.request.Request(url, headers={
            "User-Agent": "skill-scout/0.1",
            "Accept": "application/vnd.github+json",
        })
        with urllib.request.urlopen(req, timeout=8) as r:
            data = json.loads(r.read().decode("utf-8"))
            items = data.get("items", [])

        # Fallback: no topic-tagged results, broaden to name+desc search and
        # post-filter to repos where 'skill' is in name and 'claude' in desc.
        if not items:
            q2 = f'claude skill {query} in:name,description'
            url2 = f"https://api.github.com/search/repositories?q={urllib.parse.quote(q2)}&per_page=10&sort=stars"
            req2 = urllib.request.Request(url2, headers={
                "User-Agent": "skill-scout/0.1",
                "Accept": "application/vnd.github+json",
            })
            with urllib.request.urlopen(req2, timeout=8) as r:
                raw = json.loads(r.read().decode("utf-8")).get("items", [])
            for it in raw:
                name = (it.get("name") or "").lower()
                desc = (it.get("description") or "").lower()
                if "skill" in name and "claude" in desc:
                    items.append(it)
                if len(items) >= limit:
                    break

        out = []
        for item in items[:limit]:
            out.append({
                "name": item.get("name", ""),
                "repo": item.get("html_url", ""),
                "description": item.get("description") or "",
                "stars": item.get("stargazers_count", 0),
            })
        return out
    except Exception as e:
        return [{"_error": str(e)}]

def main():
    prompts = read_prompts()
    if not prompts:
        print(json.dumps({
            "status": "empty",
            "message": "No usage log yet. Run `/skill-scout install` to enable the hook.",
        }, indent=2))
        return

    keywords = top_keywords(prompts)
    installed = installed_skills()
    suggestions = []
    seen_repos = set()
    errors = []
    for kw, count in keywords[:5]:
        hits = search_marketplace(kw)
        for h in hits:
            if "_error" in h:
                errors.append(h["_error"])
                continue
            repo = h.get("repo", "")
            if not repo or repo in seen_repos:
                continue
            name = h.get("name", "").lower()
            if name in installed:
                continue
            seen_repos.add(repo)
            suggestions.append({
                "skill": name,
                "matched_keyword": kw,
                "keyword_count": count,
                "repo": repo,
                "stars": h.get("stars", 0),
                "description": h.get("description", "")[:200],
            })
    suggestions.sort(key=lambda s: (-s["keyword_count"], -s["stars"]))

    print(json.dumps({
        "status": "ok",
        "prompts_analyzed": len(prompts),
        "top_keywords": keywords,
        "installed_count": len(installed),
        "suggestions": suggestions[:10],
        "errors": errors[:3],
        "note": "Source: GitHub repo search. Unauthenticated rate limit = 10 req/min. Install with: npx skills add <repo>",
    }, indent=2))

if __name__ == "__main__":
    main()
