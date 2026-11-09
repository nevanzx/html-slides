---
version: 1.0.0
name: Porcelain
description: >-
  A refined, airy editorial system for brand and product storytelling. A
  crisp white canvas, one ink, four pastel color-block fills, Fraunces
  display serifs, Manrope body text, hairline rules, and a calm fade-and-rise
  transition. Designed to feel premium at any density without relying on
  heavy borders or loud contrast.
colors:
  white: "#FFFFFF — the canvas; every slide begins here"
  ink: "#161616 — all type, rules, and primary ornament"
  muted: "#6B6B6B — secondary copy, labels, captions"
  blush: "#F6D5DC — emphasis fill; the warmest pastel"
  mint: "#D6EFDD — confirmation and section fills; the coolest pastel"
  butter: "#FFF1C9 — attention and highlight fills"
  periwinkle: "#DCE4FF — context and composition fills"
  hairline: "rgba(22,22,22,.12) — 1px rules, dividers, table lines"
  description: "Crisp white base, ink text, four pastel fills, hairline rules — pastels are fills only, never type colors."
typography:
  display: Fraunces (ital, opsz, wght axes; 300–700; italic for accent words)
  body: Manrope (400/500/600/700)
  style: high-contrast serif paired with a clean geometric sans
  sizes:
    display: 132–136px on the 1920×1080 canvas
    h1_cover: 136px / 0.97 line-height / -0.026em
    h2: 58–76px / 1.02 line-height / -0.016em
    h3: 34–38px / 1.1 line-height
    body: 30px / 1.55 line-height
    label: 13–14px uppercase / 0.22–0.26em tracking
    stat: 104px Fraunces / 0.95 line-height
spacing:
  canvas: 1920×1080 authored pixels
  margin_x: 72px
  chrome_top: 48px
  body_top: 130px
  body_bottom: 64px
  gap: 24px (cards) / 72px (columns)
  radius: 22–32px (cards 24–28px)
slide_inventory:
  - { n: 1, type: cover, label: "01 Cover", note: "Serif headline, subtitle, meta rule, pastel swatch composition" }
  - { n: 2, type: agenda, label: "02 Agenda", note: "Five hairline-ruled contents rows with page references" }
  - { n: 3, type: section_divider, label: "03 Section · The Palette", note: "Split layout, giant numeral, mint panel with palette chips" }
  - { n: 4, type: key_points, label: "04 Principles", note: "2×2 bullet grid over hairline rules" }
  - { n: 5, type: two_column, label: "05 The System", note: "Text left, periwinkle color-role card right" }
  - { n: 6, type: stat_grid, label: "06 Measures", note: "Four tall pastel cards, 104px Fraunces numerals" }
  - { n: 7, type: process, label: "07 Process", note: "Four numbered columns divided by hairlines" }
  - { n: 8, type: timeline, label: "08 Timeline", note: "Five milestones on a single hairline with year labels" }
  - { n: 9, type: comparison_table, label: "09 Comparison", note: "Butter header row; conventional vs. playbook" }
  - { n: 10, type: pull_quote, label: "10 Pull Quote", note: "64px italic serif quote plus blush dot-grid panel" }
  - { n: 11, type: figure, label: "11 Figure", note: "Large gradient figure placeholder with white frame and legend" }
  - { n: 12, type: team, label: "12 People", note: "Four bordered profile cards with pastel monogram avatars" }
  - { n: 13, type: closing_cta, label: "13 Closing", note: "Serif closing line, dark pill CTA, periwinkle monogram panel" }
---

# Porcelain

Porcelain is a white-canvas editorial system for decks that need to feel **composed** rather than loud. It pairs a high-contrast serif (Fraunces) with a clean geometric sans (Manrope), then lets four pastel fills do the work that heavy borders and dark panels usually do. The result is soft, but never vague: hierarchy comes from scale, spacing, and color-block grouping, so the page reads instantly while staying calm.

## The system at a glance

- **Canvas:** pure white `#FFFFFF` at a fixed 1920×1080. Nothing floats outside the 72px side margins.
- **Ink:** `#161616` for all text, rules, and ornament. Secondary copy is `#6B6B6B`.
- **Pastels:** blush `#F6D5DC`, mint `#D6EFDD`, butter `#FFF1C9`, periwinkle `#DCE4FF`. They are fills only — never type colors, never gradients across text.
- **Hairlines:** 1px `rgba(22,22,22,.12)` divide rows, columns, and table lines. They are the only hard edges in the system.
- **Radii:** 22–32px on cards and panels; 999px on pills and chips.
- **Shadows:** one soft, far-off shadow (`0 30px 70px -40px rgba(22,22,22,.32)`) to lift cards off the white without making them heavy.
- **Chrome:** every slide carries the same top bar — `PORCELAIN` + section name on the left, `NN / 13` on the right — separated from the body by a hairline.

## Type rules

| Role | Face | Size / spec |
|---|---|---|
| Cover display | Fraunces 400 | 136px, line-height .97, tracking −.026em |
| Slide headline | Fraunces 400 | 58–76px, line-height 1.02 |
| Card headline | Fraunces 400 | 34–38px |
| Body | Manrope 400 | 30px, line-height 1.55 |
| Eyebrow / label | Manrope 600 | 13–14px, uppercase, tracking .22–.26em |
| Stat numeral | Fraunces 400 | 104px, line-height .95 |

Italic Fraunces is reserved for the single emotional word in a headline (`Playbook`, `whisper`, `breathe`). Never set a whole paragraph in italics, and never use Fraunces for body copy.

## Layout rules

1. **One idea per slide.** Each slide has one headline, one supporting paragraph at most, and one dominant visual or numeric idea.
2. **Grid first.** Slides are composed on a 12-column mental grid with a 72px gutter. Two-column layouts split 1fr / fixed-width (560–720px); card grids use equal columns with 24px gaps.
3. **Anchor to the edges.** The chrome and body share the same left/right inset (72px). Content never crowds the canvas edge.
4. **Vertical rhythm.** `top: 130px` for the body area; a slide's headline sits within the first 250px, with supporting content below.
5. **Numbers get room.** Stat cards are tall (≈556px) so the numeral can sit low with air above it.
6. **Tables stay light.** No vertical rules. Use a butter header row, hairline row separators, and bold ink for the preferred column.

## Decoration vocabulary

- **Pastel color-block cards** with 22–32px radii and the soft shadow. These are the primary visual event.
- **Dot grids:** `radial-gradient(rgba(22,22,22,.15) 1.5px, transparent 1.6px)` at 24–26px spacing, used only inside pastel panels and on the closing/quote panels. Never behind body text.
- **Palette chips / swatch rows:** rounded rectangles or circles showing the four pastels, usually with one white chip to show the page color.
- **Hairline rules:** top chrome, agenda rows, table rows, column dividers, and small connect-the-thought lines under headings.
- **Oversized numerals:** Fraunces italic `02` or `P.` at 260–300px as a compositional anchor on dividers and closing slides.
- **Monogram avatars:** pastel circles with two-letter initials in italic Fraunces for team slides.

## Animation spec

- **Slide transition:** inactive slides are `opacity: 0; transform: translateY(18px)`; the active slide is `opacity: 1; transform: translateY(0)`. Transition: `600ms cubic-bezier(.22,.61,.36,1)` on opacity and transform.
- **Child reveal:** elements marked `data-rise` start at `opacity: 0; translateY(16px)` and animate to rest with `780ms` on the same easing. Delays step by 90ms via `data-rise="2…5"`.
- **Tone:** calm and premium. No bounce, no scale, no rotation. Motion should be barely noticeable when it ends and missed when it is absent.
- Navigation is handled entirely by `deck-stage.js` — do not add a second keyboard handler.

## Do

- Let one pastel card dominate each composition; let the others support it.
- Keep every paragraph at 30px or larger on the 1920×1080 canvas.
- Use the hairline as the only line weight; let color blocks do the grouping.
- Keep the chrome identical on every slide.
- Use italic Fraunces for exactly one accent word per headline.
- Give the dot grid a job: a panel texture or a closing flourish, not wallpaper.

## Don't

- Don't put text on a pastel fill unless contrast is clearly comfortable; prefer ink on white for long copy.
- Don't use more than two pastels in a single content cluster.
- Don't add thick borders, hard offset shadows, or neo-brutalist blocks.
- Don't set body copy in Fraunces or labels in a third typeface.
- Don't add a second navigation or counter — `deck-stage` already provides both.
- Don't crowd the 72px margins or push text to the canvas edge.
