# Content Cleanup Implementation Plan (Batch 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close beads blog-lph (gate hardening), blog-uf5 (demote in-body `# ` h1 headings), blog-0ra (rel=noopener on remaining raw-HTML `target="_blank"` links).

**Architecture:** TDD via the gate: Task 1 hardens check-site.sh and adds two new sweeping assertions that go red against current content; Tasks 2–3 fix the content and turn them green (Task 3 also flips the noopener WARN to FAIL). Branch: `content-cleanup`.

**Tech Stack:** Hugo v0.157, bash, python3 for fence-aware markdown edits.

## Global Constraints

- Content edits must be surgical: only the exact lines named per task change; no reflowing, no whitespace churn elsewhere in posts.
- CRITICAL: `^# ` lines inside fenced code blocks (``` or ~~~) are shell comments, NOT headings — they must NOT be touched. All markdown heading edits must be fence-aware.
- Build command: `hugo --logLevel warn -d /tmp/theme-check-public` (exit 0, zero warnings).
- Commits: no Co-Authored-By trailer. Branch `content-cleanup`.

---

### Task 1: Harden check-site.sh + new red assertions

**Files:**
- Modify: `scripts/check-site.sh`

- [ ] **Step 1:** Immediately after the `SAMPLES=` line, add:

```bash
[ -n "$POST" ] || err "no post page found under $PUB/2* — sample set incomplete"
[ -n "$CAT" ]  || err "no category term page found — sample set incomplete"
```

- [ ] **Step 2:** At the end of the `# 9. SEO head assertions` block, add:

```bash
# 10. Whole-corpus content assertions
multi_h1=0
while IFS= read -r f; do
  n=$(grep -o '<h1' "$f" | wc -l | tr -d ' ')
  [ "$n" -gt 1 ] && { echo "  multi-h1 ($n): $f"; multi_h1=1; }
done < <(find "$PUB" -path "$PUB/2*" -name index.html)
[ "$multi_h1" -eq 0 ] || err "post pages with more than one <h1> (in-body headings)"
```

- [ ] **Step 3:** Run the gate against a fresh build. Expected: FAIL with exactly the 4 known multi-h1 posts listed (sidekiq-vs-resque, tor-network, and two others); everything else passes. Record output.

- [ ] **Step 4:** Commit: `git add scripts/check-site.sh && git commit -m "Harden gate: fail on missing samples, sweep all posts for multi-h1"`

---

### Task 2: Demote in-body `# ` headings (fence-aware)

**Files:**
- Modify: every file matched by fence-aware detection under `content/post/`

- [ ] **Step 1:** Write `/tmp/demote-h1.py`:

```python
#!/usr/bin/env python3
"""Demote '# ' headings to '## ' in markdown bodies, skipping fenced code blocks and front matter."""
import sys, re

for path in sys.argv[1:]:
    with open(path) as fh:
        lines = fh.readlines()
    out, in_fence, fence_ch, in_fm, changed = [], False, "", False, 0
    for i, line in enumerate(lines):
        if i == 0 and line.strip() == "---":
            in_fm = True
            out.append(line); continue
        if in_fm:
            if line.strip() == "---":
                in_fm = False
            out.append(line); continue
        m = re.match(r"^(```|~~~)", line)
        if m:
            if not in_fence:
                in_fence, fence_ch = True, m.group(1)
            elif line.startswith(fence_ch):
                in_fence = False
            out.append(line); continue
        if not in_fence and re.match(r"^# \S", line):
            out.append("#" + line); changed += 1
        else:
            out.append(line)
    if changed:
        with open(path, "w") as fh:
            fh.writelines(out)
        print(f"{path}: {changed} headings demoted")
```

- [ ] **Step 2:** Run it over all posts: `python3 /tmp/demote-h1.py content/post/*.markdown content/post/*.md`. Record the per-file counts.
- [ ] **Step 3:** Spot-verify safety: `git diff --stat content/post` — then for each changed file, `git diff <file>` and confirm every changed line is `-# X` → `+## X` and NONE of the changed lines sit inside a code fence (read the surrounding hunk context).
- [ ] **Step 4:** Build + gate: the multi-h1 assertion must now pass; the 4 known posts render exactly one `<h1>`.
- [ ] **Step 5:** Commit: `git add content/post && git commit -m "Demote in-body h1 headings to h2 in legacy posts"`

---

### Task 3: rel=noopener on raw-HTML target=_blank links; tighten gate

**Files:**
- Modify: content files containing raw `<a ... target="_blank">` without `rel`
- Modify: `scripts/check-site.sh` (WARN → FAIL)

- [ ] **Step 1:** Find them: `grep -rlE '<a [^>]*target="_blank"' content/ | sort`. For each file, edit every `<a ... target="_blank" ...>` that lacks `rel=` to add `rel="noopener noreferrer"` immediately after the `target="_blank"` attribute. Links that already have a `rel` attribute: add the two values into the existing rel instead of a second attribute.
- [ ] **Step 2:** Build; confirm `grep -rhoE '<a [^>]*target="_blank"[^>]*>' --include='*.html' /tmp/theme-check-public | grep -cv noopener` prints `0`.
- [ ] **Step 3:** In `scripts/check-site.sh` section 7, replace the WARN with a FAIL:

```bash
bad=$(grep -rhoE '<a [^>]*target="_blank"[^>]*>' --include='*.html' "$PUB" | grep -cv noopener)
[ "$bad" -eq 0 ] || err "$bad target=\"_blank\" links without rel=noopener"
```

- [ ] **Step 4:** Full gate → `OK: all site checks passed`.
- [ ] **Step 5:** Commit: `git add content scripts/check-site.sh && git commit -m "Add rel=noopener to raw-HTML target=_blank links; make gate assertion strict"`

---

### Task 4 (controller): beads, final review, merge

- [ ] `bd close blog-lph blog-uf5 blog-0ra --reason "Fixed by content-cleanup branch"`
- [ ] Final whole-branch review; finishing options; deploy per user choice.
