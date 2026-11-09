---
version: 1.0.0
name: Study Hall
description: A warm, classroom-inspired presentation system — white canvas, soft pastel corner wash, highlighter marks, pinned sticky notes, and handwritten Caveat annotations.
colors:
  white: "#FFFFFF"
  ink: "#1F1F1F"
  muted: "#6B6B6B"
  highlighter_yellow: "#FFF3A3"
  blush_pink: "#FFD6E8"
  study_blue: "#D6ECFF"
  mint: "#D9F2E6"
  description: "White base with a soft pastel corner wash and highlighter pastels — friendly, sunny, and never heavy."
typography:
  display: Archivo
  body: Nunito
  accent: Caveat
  style: "Heavy grotesk heads with a rounded sans body and handwritten Caveat accents"
  sizes:
    display_xl: 132px
    display_l: 104px
    heading: 74–82px
    subheading: 34–40px
    body: 30px
    label: 22–24px
    caption: 24px
spacing:
  unit: 24px
  slide_padding: "150px 80px 64px"
  grid_gap: 18–26px
  card_radius: 22–34px
  shadow: "0 16px 36px rgba(31,31,31,0.09)"
slides:
  - 01 Cover / title
  - 02 Agenda / table of contents
  - 03 Section divider
  - 04 Key points / bullets
  - 05 Two-column (text + visual)
  - 06 Stat grid (four big numbers)
  - 07 Process / steps
  - 08 Timeline
  - 09 Comparison table (A vs B)
  - 10 Pull quote
  - 11 Image / figure placeholder
  - 12 Team / people
  - 13 Closing / CTA
---

# Study Hall

A presentation system that feels like a good classroom: tidy enough to trust, warm enough to relax into. Every slide starts on white, gets a quiet pastel wash in the corners, and then earns its personality from marker strokes, pinned sticky notes, and a little handwriting.

## The background — a pastel wash, not notebook paper

This is the defining rule of the template. The canvas is **clean white** with four large, soft radial gradients that bleed in from the corners:

- blush pink, top-left
- study blue, top-right
- highlighter yellow, bottom-left
- mint, bottom-right

There are **no ruled-paper horizontal lines, no red notebook margin, and no side tabs**. The pastel wash is atmospheric, not literal stationery. It should read as light and airy, barely there in the center of the slide so type stays crisp.

## Typography

| Role | Family | Weight | Size |
|---|---|---|---|
| Cover display | Archivo | 900 | 132px |
| Section display | Archivo | 900 | 104px |
| Slide heading | Archivo | 800 | 74–82px |
| Card heading | Archivo | 800 | 34–40px |
| Body | Nunito | 600–700 | 30px |
| Eyebrow / kicker | Nunito | 800 | 28px, uppercase, tracked |
| Chrome / labels | Nunito / Archivo | 700–800 | 22–24px |
| Handwriting | Caveat | 600 | 32–46px |

Rules:

- Headlines are Archivo, tight-tracked (`-0.02em` to `-0.035em`) and heavy. Let two words carry a line; break with intention.
- Reading copy is Nunito at **30px minimum**, line-height 1.4–1.5. Never go smaller for body text.
- Caveat is for asides, notes, and arrows only — never for headings or running copy.
- One highlighter stroke per idea. Mark a key word, not a whole sentence.

## Color

| Token | Hex | Use |
|---|---|---|
| White | `#FFFFFF` | Slide base, cards, pills |
| Ink | `#1F1F1F` | All primary text, hard accents |
| Muted | `#6B6B6B` | Secondary copy, chrome, labels |
| Highlighter | `#FFF3A3` | Marker strokes, yellow sticky notes |
| Blush | `#FFD6E8` | Warmth, cover, dividers |
| Study blue | `#D6ECFF` | Focus, calm, secondary cards |
| Mint | `#D9F2E6` | Progress, success, "after" columns |

Use pastels as **fields**, ink as the type color. Do not put light text on pastel. Do not introduce additional hues — the four pastels plus ink and white are the whole palette.

## Layout rules

- Fixed 1920×1080 canvas inside `<deck-stage>`.
- Top chrome on every slide at `top: 40px`, `left/right: 80px`: brand "STUDY HALL" + section name on the left, page number "NN / 13" in a white pill on the right.
- Content area: `inset: 150px 80px 64px`. Keep all content inside it.
- Use generous gaps (18–26px) and rounded cards (22–34px radius). Nothing sharp.
- Body copy is 30px, headings 34px+. If a slide overflows, restructure the slide — do not hand-shrink type.
- Align to the content edges; do not center everything. Only the pull quote is centered.
- Cards are white or a single pastel fill. Avoid stacking more than two card styles on one slide.

## Decoration vocabulary

Use these, and only these, to build personality:

- **Marker stroke** — a yellow linear-gradient band behind a key term. It wipes in from left to right on slide entry.
- **Sticky note** — rounded square in highlighter yellow or mint, with a small red pin at the top center and a slight rotation (`-2.6deg` to `+2.2deg`). Notes pop in.
- **Handwritten aside** — Caveat text in ink, optionally next to a hand-drawn arrow.
- **Hand-drawn arrow** — a single thin SVG stroke with a rough curve and an open arrowhead.
- **Soft cards** — white rounded rectangles with a wide, low-opacity shadow. Never use hard borders or drop shadows with visible offsets.
- **Pastel chips / pills** — uppercase Nunito labels on a pastel background for tags and week markers.
- **Pastel orb accents** — large, very soft circles used only inside the divider card and figure tiles.

Do not add ruled lines, spiral binding, tape strips, or clip-art. The classroom feel comes from warmth and handwriting, not from stationery props.

## Animation spec

The template uses `deck-stage` for navigation, scaling, hash restore, and the slide counter overlay. Do not add a second keyboard handler.

- **Slide transition:** the active slide fades in and scales from `0.98` to `1` over `500ms` with `cubic-bezier(0.22, 0.61, 0.36, 1)`.
- **Sticky-note pop:** notes animate `notePop` over `620ms` with a tiny rotation and a soft overshoot. Stagger notes with `--d` (for example `0.12s`, `0.22s`).
- **Marker wipe:** the yellow highlight grows to full width over `700ms` after a `150ms` delay.
- The motion is warm and gentle, not bouncy. No looping animation, no parallax, no flying elements.

## Do

- Keep the center of the slide light and legible.
- Use one marker stroke and one sticky note per idea.
- Let Caveat annotations feel like margin notes from a friendly teacher.
- Alternate pastel card fills to separate ideas.
- Keep the top chrome identical on every slide.
- Author type at 30px body / 34px+ headings and let the inline autofit runtime handle edge cases.

## Don't

- Don't draw ruled notebook lines, a red margin, or side tabs — the background is a pastel wash.
- Don't use Caveat for body copy or headings.
- Don't use hard black borders, sharp corners, or harsh shadows.
- Don't add colors outside the seven-token palette.
- Don't put more than one headline on a slide.
- Don't hand-shrink fonts to fix overflow; split or restructure the slide.
- Don't add another navigation runtime or a second slide counter.

## Slide inventory

1. **Cover / title** — split layout: kicker, oversized Archivo title with a marker word, subtitle, date pill, and a pinned swatch-board visual.
2. **Agenda / table of contents** — two-column grid of six numbered stops with pastel index tiles and a mint sticky note.
3. **Section divider** — oversized unit number in a white card with pastel orbs, plus a large heading and topic chips.
4. **Key points / bullets** — five numbered rule cards in a 2×3 grid, with a mint sticky note as the sixth cell.
5. **Two-column (text + visual)** — color story on the left, 2×2 palette board on the right.
6. **Stat grid** — four pastel stat cards with oversized Archivo numerals and short captions.
7. **Process / steps** — four step cards in a row with pastel number tiles, arrows, and a handwritten duration.
8. **Timeline** — five milestones alternating above and below a pastel gradient line.
9. **Comparison table** — A vs B grid with an ink "old system" header and a mint "Study Hall" header.
10. **Pull quote** — centered quote with a pink Caveat quotation mark, marker phrase, avatar attribution, and two corner notes.
11. **Image / figure placeholder** — three-tile moodboard placeholder with labels, soft orbs, and a handwritten aside.
12. **Team / people** — four people cards with pastel initial avatars, names, roles, and one-line bios.
13. **Closing / CTA** — big closing headline with marker, two CTA pills, contact line, and a three-step takeaway board with a sticky note.

## Runtime

- `template.html` loads `deck-stage.js` from the same folder.
- The full `autofit.js` runtime is inlined immediately before `</body>`.
- Key behavior the template relies on: `#N` hash restore (1-indexed), arrow/space navigation, and the built-in bottom-center counter.
