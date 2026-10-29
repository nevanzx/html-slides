---
name: html-slides
description: Use when the user wants slides, a deck, or a presentation delivered as a browser HTML file with full template artwork (or names a template from beautiful-html-templates), or when the user asks to "make slides/presentation" without specifying PowerPoint vs HTML — in that case ask whether docx-to-ppt (editable PowerPoint) or html-slides (browser HTML) should handle it before starting.
---

# HTML Slides

## Overview

Build presentation decks by **fully adapting the zarazhangrui/beautiful-html-templates library**: clone the chosen template, replace placeholder content with real content, and deliver a standalone HTML file that looks exactly like the template — fonts, palette, every decorative element. The deliverable is HTML presented in a browser; never a .pptx.

## Step 0 — Routing (mandatory)

If the user asks for "slides", "a deck", or "a presentation" without specifying the format, STOP and ask: "PowerPoint deck (docx-to-ppt) or HTML slides (html-slides)?" Proceed only after the answer. Do not infer from past projects.

## Workflow

**Step 1 — Ask occasion and mood.** Exactly two questions: "What's the occasion?" (founder pitch, research synthesis, classroom kickoff...) and "What mood/vibe?" (confident & punchy, warm & playful, dark & moody...). Wait for answers; taste wins over inference.

**Step 2 — Pick 3 candidates.** Clone the repo once and reuse it:
```bash
git clone --depth 1 https://github.com/zarazhangrui/beautiful-html-templates
```
Read `index.json`. Match occasion + mood against each template's `mood`, `tone`, `best_for`, `avoid_for`, `formality`, `density`, `scheme`. Pick three genuinely different candidates (e.g. one editorial, one warmer, one wildcard). Read each candidate's `template.html`.

**Step 3 — Build title-slide previews.** For each candidate: take only its first slide, replace placeholder content with the user's real topic/title/subtitle/date, save as a standalone HTML in `previews/01-<slug>.html` (sibling assets like `deck-stage.js` must be reachable — a preview may reference the cloned template folder).

**Step 4 — Open previews and wait for the pick.** On Windows use `Start-Process` (or `Invoke-Item`), never `open`. Send the three paths; wait for the user's choice.

**Step 5 — Build the full deck in the chosen template.** REQUIRED: follow the repo's own `AGENTS.md` §3–§5 (it is in the clone). Preserve fonts, palette, layout grid, slide-level CSS classes, decorative elements, and the navigation runtime. Replace all placeholder content. Need more slides? Duplicate the most appropriate existing layout and update page-number labels (`NN / TT`). Missing layout? Design it with the template's own design system — same fonts, colors, decor vocabulary, spacing rhythm, component grammar, chrome.

**Step 6 — Auto font-size fit pass.** The template renders a fixed 1920×1080 stage that the browser scales uniformly (it may letterbox or pillarbox; content never reflows). After building every slide:
1. Check each slide for overflow — content clipped, text running past cards/columns, elements colliding with decor or the page-number chrome.
2. Fix overflow WITHOUT restructuring the design: step font sizes down within the template's type scale (keep relative hierarchy, e.g. 32→28→24 px), tighten line-height or card padding, or shorten copy. Never move the stage scale itself.
3. Re-space on the smallest display you expect (13-inch laptop) and confirm nothing clips on the largest (4K) — the uniform scale should handle both once the stage is clean at 1920×1080.
4. If a slide still overflows, split it into two slides instead of shrinking further.

**USER RULE (persistent, overrides the ~14px default in point 4 of the original Step 6):** every deck built for this user must keep a **30px minimum font size for every text element** at the 1920×1080 stage — body copy, bullets, table cells, mono labels/tags/captions/source lines, chart axis text, timeline labels, page numbers, everything. Headings scale above it (34px+) so hierarchy survives. If content overflows at the floor, fix it by shortening copy, tightening padding/spacing, or splitting the slide — never step below 30px. Verify the floor with headless screenshots (e.g. `chrome.exe --headless --screenshot`) on the densest slides before delivering.

**Step 7 — Deliver.** Open the final deck in the browser, send the absolute file path on its own line, plus one line on which template was picked and why, and any caveats (e.g. slides designed from scratch per §5).

## Content mapping

For lesson/document content, organize per-slide substance the same way a presenter needs it: one idea per slide, headlines presentation-ready, notes that don't belong on the slide stay out. If the user supplies a rich source and you need slide-by-slide derivation, the docx-to-ppt skill's Steps 1–3 describe content extraction; do NOT use its slidespec file.

## Common Mistakes

- Skipping Step 0 — silently producing a .pptx when the user wanted HTML (or vice versa)
- Substituting fonts ("Inter is similar enough") — the typography IS the design system
- Recoloring or stripping decoration (grain, ribbons, stamps) to "simplify" — they are the identity
- Mixing components from two templates — each template is a closed visual system
- Letting content overflow the 1920×1080 stage instead of running Step 6
- Letting any text element drop below the user's 30px floor — trim copy or split the slide instead
- Using macOS `open` on Windows
- Mashing two templates' slides together instead of extending one
