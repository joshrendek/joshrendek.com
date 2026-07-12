# Terminal Theme Redesign — rendek-dark

**Date:** 2026-07-11
**Status:** Approved (visual direction chosen from 3 samples; sample artifact: claude.ai/code/artifact/7873384e-47fb-4213-8864-62c4b276ced3, direction B)

## Overview

Redesign the `rendek-dark` Hugo theme as a single-column, editor/terminal-styled blog while keeping the existing Tokyo Night–derived palette. Drop the Foundation CSS framework, remove the sidebar, and absorb all template-level a11y/SEO beads in the rebuild. Templates + CSS only; content-level fixes (alt text, meta descriptions, category cleanup) are tracked as separate beads.

## Goals

- Distinctive terminal/editor identity that matches the palette's editor-colorscheme origins.
- Single readable column; comfortable long-form reading (sans-serif body, ~72ch measure).
- Remove Foundation (5,798 lines) in favor of one hand-written stylesheet (~250 lines).
- Fix, by construction, the template-level beads: blog-ekf, blog-7l8, blog-deo, blog-11k, blog-0ef, blog-yr9, blog-0ra, blog-syu (homepage summaries).

## Non-goals

- Content sweeps: alt text (blog-6f2), per-page meta descriptions (blog-n1d), category front matter (blog-s71) — separate beads.
- head.html SEO additions (canonical, robots.txt, og:image, titles — blog-ya1, blog-0n0, blog-naf, blog-2r5) may land alongside but are specified in their beads, not here.
- Light theme. The site is deliberately dark-only.

## Design tokens (CSS custom properties)

```css
:root {
  --bg:         #191a2a;  /* page ground (darker than before; was shadow color) */
  --surface:    #212337;  /* code blocks, status-bar file segment on hover rows */
  --panel:      #2f334d;  /* gutter borders, rules, status bar segments */
  --panel-edge: #3b4066;  /* 1px borders */
  --ink:        #c8d3f5;  /* body text */
  --ink-dim:    #828bb8;  /* dates, secondary text */
  --lav:        #b4c2f0;  /* site title */
  --green:      #c3e88d;  /* links, post titles, braces, cursor, prompt accents */
  --green-dim:  #a9c979;  /* link hover */
  --blue:       #388ED6;  /* status bar position segment */
  --blue-soft:  #82aaff;  /* tag links, secondary accents */
  --red:        #E84A4A;  /* the <3 */
  --mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, monospace;
  --sans: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
}
```

Note: page ground becomes `#191a2a` with `#212337` as raised surface (inverted from current usage) per the chosen sample. If it feels too dark in practice, swap the two — both are in-palette.

## Typography

- **Mono** (system stack): all "chrome" — masthead, nav, dates, tags, footer, status bar, list-page headings, pagination.
- **Sans** (system stack): post/summary body text, line-height 1.65.
- Post titles: mono, green, 700; hover = inverted (green background, dark text).
- Dates: mono, dim, prefixed `// ` via CSS `::before` (e.g. `// May 4, 2024 · 6 min`).
- Root font-size 16–17px; drop the current `font-size: 1.5em` body hack.

## Layout

Single centered column, `max-width: 72ch` for text blocks (code blocks may extend to ~90ch). No grid framework. Vertical rhythm via flex/grid `gap`.

Page skeleton (all templates):

```
<a class="skip" href="#main">Skip to content</a>
<header>            masthead + nav
<main id="main">    page content
<footer>            real links + decorative status bar
```

## Components

### Masthead (header.html)
- `{ Josh Rendek }` — braces green, name lavender, followed by a blinking block cursor (`aria-hidden="true"`, `animation: blink`; disabled under `prefers-reduced-motion`).
- Site title is an `<h1>` ONLY on the homepage; `<p class="site-title">` (same styling) on all other pages so each page has exactly one h1.
- Tagline: `<3 Go & Kubernetes · honeypots · homelab · leadership` (heart in red).

### Nav
- `<nav aria-label="Main">`, items rendered as `./home`, `./projects`, … (`./` via CSS `::before`, lowercase via CSS `text-transform`).
- Dashed top/bottom rules (`border: 1px dashed var(--panel-edge)`).
- Menu source stays `config.toml [[menu.main]]`; remove the dead `/docs/` entry (blog-eiz).
- External links (GitHub, Resume) get `rel="noopener noreferrer"` (blog-0ra).

### Post list (index.html, summary.html)
- Homepage uses `{{ .Render "summary" }}` — no more full content (blog-syu).
- Each entry: `<article>` with 2px left gutter border (`--panel`, green on `:hover`/`:focus-within`), date line, `<h2>` title, sans summary, `read more →` link with accessible text (`aria-label` includes post title), tag row `tags: golang, kubernetes`.

### Post page (single.html)
- Post title is the page's only `<h1>` (mono, green, not a self-link).
- Date/reading-time line under title; body in sans; tags + Disqus in `postfooter`.
- Code blocks: keep pygments classes; restyle — `--surface` background (page ground is now darker), 1px `--panel-edge` border, 6px radius, `overflow-x: auto`. Fix current negative-margin hack (`margin-left: -30px`).
- Tables: dark palette — header `--panel`, borders `--panel-edge`, hover row `--surface`; removes white-background contrast failure (blog-0ef). Delete invalid `#22`/`#11` color values.
- Blockquote: `--surface` background, 3px green left border (replaces `#ccc`).

### List/archive/terms pages (list.html, _index.html, terms.html, archive/single.html)
- Rewritten from scratch (fixes blog-ekf missing-brace bug by replacement).
- Year groups: `<h2>` mono year headings; entries as `// date  title` rows.
- Terms page: term links as `tagname (count)` in a simple mono list.

### Footer (footer.html)
- Real links first: RSS · GitHub · Email · copyright — plain mono links, no `<center>`.
- Below: decorative vim status bar, `aria-hidden="true"`, three segments:
  `NORMAL` (green bg) | `~/blog/<section>.md` (panel bg) | position (blue bg).
- On paginated pages the position segment shows real `page N/M` (from `.Paginator`); elsewhere `☰ 100%`.

### Pagination (paginator-menu.html)
- `<nav aria-label="Pagination">` with `← newer` / `older →` text links (blog-yr9). No `<center>`, no `<<`/`>>`.

### Removed
- `sidebar.html` (deleted). Projects/Other Blogs content merges into `content/projects.md`; "Recent Posts" box dropped.
- `foundation.min.css` removed from head; `colors.css` + `layout.css` replaced by single `theme.css`. `pygments2.css` stays.
- `social-links.html` (unused header variant) deleted if nothing references it.
- `<center>`, `<nobr>`, inline `style=` attributes gone from all templates.

## Baseline a11y requirements (all templates)

- `<html lang="en">` (blog-7l8).
- Skip link as first focusable element, visible on focus (blog-11k).
- Landmarks: `<header>`, `<nav>`, `<main>`, `<footer>` on every page (blog-11k).
- Exactly one `<h1>` per page; no skipped heading levels (blog-deo).
- Visible `:focus-visible` outline (green, 2px) on all interactive elements.
- All `target="_blank"` links get `rel="noopener noreferrer"` (blog-0ra).
- Decorative elements (cursor, status bar, `./` and `//` prefixes) are CSS-generated or `aria-hidden` so screen readers never announce them.
- Color contrast: `--ink` on `--bg` = 12.9:1; `--ink-dim` on `--bg` ≥ 4.6:1; `--green` on `--bg` ≥ 9:1 — all pass WCAG AA. Status bar `NORMAL` segment: dark text on green (passes).

## Test plan

Automated, wired into `publish.sh` (or a new `make check`) so it runs before every deploy:

1. **Build gate:** `hugo --logLevel warn` must exit 0 with no warnings.
2. **Output assertions** (`scripts/check-site.sh` against `public/`):
   - No file contains `{ partial` (brace-bug regression guard).
   - `grep -q '<html lang="en">'` on homepage, a post, a category page, 404.
   - Exactly one `<h1` per sampled page (homepage, post, archive, category).
   - Every page has `<main` and `<nav`; homepage h1 contains "Josh Rendek".
   - No `<center>`, `<nobr>`, or `foundation.min.css` references in output.
   - Every `target="_blank"` line also contains `noopener`.
   - Homepage `index.html` < 40 KB (summary regression guard; currently 88 KB).
3. **Link check:** `htmltest` (or `lychee --offline`) over `public/` for internal 404s — catches the `/docs/` class of bug.

## Rollout

1. New CSS + rewritten templates on a branch; verify with test plan + visual pass via `hugo server`.
2. Delete dead files (sidebar, docs layouts already deleted, foundation).
3. Merge; deploy via existing `publish.sh` flow.
