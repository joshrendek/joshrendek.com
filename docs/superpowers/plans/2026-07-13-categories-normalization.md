# Categories Normalization Implementation Plan (blog-s71)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close bead blog-s71 — replace space/comma-joined category strings in post front matter with YAML lists drawn from a canonical set, eliminating junk taxonomy slugs like /categories/ruby-performance-jruby-ruby-mri-jvm/.

**Architecture:** Gate-first: Task 1 adds an allowed-category-slugs assertion (red against current junk terms), Task 2 rewrites the 31 affected `categories:` lines per the exact mapping table below, Task 3 wraps. Branch: `categories-cleanup`.

## Global Constraints

- Canonical category set (the ONLY allowed slugs): `go ruby scala kubernetes helm security linux emacs rants homelab`.
- Front matter is YAML between `---` fences. New format: single-line flow list, e.g. `categories: [go, security]`.
- Only the `categories:` line of each listed file may change — nothing else in any post.
- Old junk term URLs (e.g. /categories/go-golang-security/) will 404 after this; ACCEPTED — no aliases (near-zero traffic pages).
- Build: `hugo --logLevel warn -d /tmp/theme-check-public` exit 0, zero warnings.
- Commits: no Co-Authored-By trailer. Branch `categories-cleanup`.

## The mapping table (exact, exhaustive — every current `categories:` value)

| Current line (exact) | New line |
|---|---|
| `categories: null` (8 files) | DELETE the line entirely |
| `categories: ruby` (5) | `categories: [ruby]` |
| `categories: golang` (5) | `categories: [go]` |
| `categories: scala` (2) | `categories: [scala]` |
| `categories: rants` (2) | `categories: [rants]` |
| `categories: go golang` (2) | `categories: [go]` |
| `categories: uptime` | `categories: [homelab]` |
| `categories: security linux ubuntu` | `categories: [security, linux]` |
| `categories: security linux` | `categories: [security, linux]` |
| `categories: ruby refactoring` | `categories: [ruby]` |
| `categories: ruby performance jruby ruby mri jvm` | `categories: [ruby]` |
| `categories: ruby jruby testing` | `categories: [ruby]` |
| `categories: ruby jekyll` | `categories: [ruby]` |
| `categories: kubernetes` | `categories: [kubernetes]` |
| `categories: golang, elasticsearch` | `categories: [go]` |
| `categories: go golang security` | `categories: [go, security]` |
| `categories: chef ruby` | `categories: [ruby]` |
| `categories: [emacs]` | unchanged (already canonical) |
| `categories: ['kubernetes']` | `categories: [kubernetes]` |
| `categories: ['kubernetes', 'helm']` | `categories: [kubernetes, helm]` |
| `categories: ['kubernetes', 'helm', 'minikube']` | `categories: [kubernetes, helm]` (minikube dropped) |

---

### Task 1: Gate assertion (red)

**Files:** Modify `scripts/check-site.sh`

- [ ] **Step 1:** At the end of the `# 10. Whole-corpus content assertions` block, add:

```bash
allowed_cats=" go ruby scala kubernetes helm security linux emacs rants homelab "
if [ -d "$PUB/categories" ]; then
  for d in "$PUB"/categories/*/; do
    slug=$(basename "$d")
    case "$allowed_cats" in
      *" $slug "*) : ;;
      *) err "non-canonical category slug: $slug" ;;
    esac
  done
fi
```

- [ ] **Step 2:** Build + gate. Expected: FAILs listing every junk slug (chef-ruby, go-golang, go-golang-security, golang, golang-elasticsearch, minikube, ruby-jekyll, ruby-jruby-testing, ruby-performance-jruby-ruby-mri-jvm, ruby-refactoring, security-linux, security-linux-ubuntu, uptime — record the actual list). Exit 1.
- [ ] **Step 3:** Commit: `git add scripts/check-site.sh && git commit -m "Gate: only canonical category slugs allowed (red baseline)"`

---

### Task 2: Rewrite front matter per mapping

**Files:** Modify every content/post file whose `categories:` line appears in the mapping table.

- [ ] **Step 1:** For each mapping row, find the files (`grep -l '^categories: <value>$' content/post/*`) and apply the exact replacement (or line deletion for `null`). Use exact-line matching — do not regex-touch anything else.
- [ ] **Step 2:** `git diff content/post` — verify every hunk is a single `categories:` line change (or deletion) matching the table. Count changed files = 31 (8 deletions + 23 rewrites; the `[emacs]` file is untouched).
- [ ] **Step 3:** Build + gate → `OK: all site checks passed`. List `ls /tmp/theme-check-public/categories/` — must be exactly (plus index.html/index.xml): emacs, go, helm, homelab, kubernetes, linux, rants, ruby, scala, security.
- [ ] **Step 4:** Spot-check counts: /categories/go/ page lists ≥ 8 posts; /categories/ruby/ ≥ 10; /categories/security/ ≥ 3.
- [ ] **Step 5:** Commit: `git add content/post && git commit -m "Normalize categories front matter to canonical list"`

---

### Task 3 (controller): bead, review, merge

- [ ] `bd close blog-s71 --reason "Fixed by categories-cleanup branch"`; final review; finishing options.
