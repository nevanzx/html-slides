---
version: 1.0
name: Sugar Grid
description: A Swiss-pop slide system built on a pure white canvas with a faint 64px grid, ink-black structure, four flat pastel fills, and Archivo Black headlines. Candy-pink highlight bars, sticker pills, checkerboard accents, arches, circles, and quarter-rounds give every layout graphic punch while the grid keeps it disciplined.
colors:
  bg: "#FFFFFF"
  ink: "#111111"
  muted: "#6B6B6B"
  pink: "#FFD1E3"
  sky: "#CDE7FF"
  lime: "#E4F5C1"
  tangerine: "#FFE0C2"
  description: "White canvas and ink structure; candy pink for attention, sky for explanation, lime for confirmation, tangerine for direction. Pastels are flat fills only — never gradients or shadows."
typography:
  display:
    family: "Archivo"
    weights: "600–900 (900 for display)"
    sizes: "150px cover, 128px section, 76px slide headline, 40px card title"
    transform: "uppercase, letter-spacing -0.03em"
  body:
    family: "Space Grotesk"
    weights: "400–700"
    sizes: "36px lead, 30px body, 30px labels and chrome"
  style: "Heavy grotesk display over a technical geometric sans; all caps for headlines, sentence case for body; 2px ink rules separate bands."
spacing:
  canvas: "1920 × 1080"
  base-unit: "64px"
  chrome-height: "92px"
  slide-padding: "52px 64px 56px (below a 92px chrome bar)"
  grid-gap: "18–26px cards, 44–64px between major columns"
  heading-offset: "38px below the slide header"
layouts:
  - { n: "01", name: "Cover", type: "title", notes: "Three-line Archivo 900 display with pastel highlight, three sticker tags, bordered shape-set figure at right." }
  - { n: "02", name: "Agenda", type: "table of contents", notes: "2×3 bordered items, color-blocked numerals, headline plus note in the header band." }
  - { n: "03", name: "Section Divider", type: "divider", notes: "Full pink field, 128px heading, white card with a four-row contents list and ghost numeral." }
  - { n: "04", name: "Key Points", type: "bullets", notes: "Four numbered rules on 2px top rules, pastel numeral blocks, decorative specimen panel at right." }
  - { n: "05", name: "Two Column", type: "text + visual", notes: "Token list at left, 2×2 swatch wall at right; each color has a name, hex, and job." }
  - { n: "06", name: "Stat Grid", type: "3–4 stats", notes: "Four pastel cards, 150px numerals, label + one-line explanation, white circle marker." }
  - { n: "07", name: "Process", type: "steps", notes: "Four step cards with pastel top bands, connector arrows, and week pills." }
  - { n: "08", name: "Timeline", type: "milestones", notes: "Five columns on a single ink axis, dots on the line, cards alternating above and below." }
  - { n: "09", name: "Comparison", type: "A vs B table", notes: "Three-column matrix with ink header, pink and sky column tints, judgment pills in the last row." }
  - { n: "10", name: "Pull Quote", type: "quote", notes: "68px Archivo quote with a sky highlight and 190px pink quote mark; sky circle, lime arch, checker at right." }
  - { n: "11", name: "Figure", type: "image placeholder", notes: "Bordered geometry specimen with four shapes and a checker, caption below, three-item key at right." }
  - { n: "12", name: "Team", type: "people", notes: "Four person cards, 150px pastel avatar circles, name, role, one-liner, and skill tags." }
  - { n: "13", name: "Closing", type: "CTA", notes: "Two-line display with pink highlight, dark pill CTA and contact link, bordered shape-set art at right." }
---

## Overview

Sugar Grid is a **Swiss-pop presentation system**: Swiss discipline in the grid, pop energy in the color. Every slide is authored on a fixed **1920 × 1080** canvas with a **92px chrome bar** across the top. The canvas is pure white with a **faint 64px grid** printed across it. Ink-black structure — 2px rules, solid blocks of type, hard-edged cards — does the organizing. Four flat pastels do the shouting.

The system exists to make a brand deck feel like a designed object rather than a filled-in template. It is graphic and confident, but the grid and the 2px rule keep it from becoming loud for its own sake.

**Key characteristics**

- White `#FFFFFF` canvas with faint 64px grid lines at ~5% ink.
- Heavy **Archivo 900** uppercase headlines with negative tracking; **Space Grotesk** for everything else at 30px+.
- Four pastel fills — pink, sky, lime, tangerine — used as flat blocks, highlight bars, and cards. No gradients, no shadows.
- 2px ink rules as the only border weight in the system.
- Geometric decoration: circles, arches, quarter-rounds, and a checkerboard accent.
- Sticker pills (2px outline, fully rounded) for tags, dates, and CTA labels.
- Hard Swiss transitions: a pastel block wipe on entry and a small content rise.

## Layout rules

- **Chrome is fixed.** Every slide carries the same top bar: left = a 22px checker, `SUGAR GRID`, a `/`, and the section name; right = a pastel dot and `NN / 13`. The bar has a white background and a 2px ink bottom rule. Never remove it, never restyle it per slide.
- **Everything below the chrome.** Content lives in `.main`, inset 64px on both sides, starting 52px below the chrome bar. Bottom padding is 56px so the deck-stage overlay never sits on text.
- **64px base.** Gaps and margins should read as multiples of the grid unit. Column gaps of 48–64px, card gaps of 18–26px.
- **Header band.** Content slides open with a `.kicker` (30px Archivo 800, 0.14em tracking, with a 56×10px ink bar), a `.h2` at 76px, and an optional 30px note capped at ~520px on the right.
- **One dominant headline per slide.** Display type is allowed to dominate — 128–150px on covers and dividers, 68–76px inside content. Everything else steps down to 30–40px.
- **Cards are hard-edged.** 2px ink border, white or one pastel fill, no radius, no shadow. Padding 28–32px.
- **Use the full width.** The system is dense by design; a half-filled slide reads as unfinished. Fill the frame edge to edge with content or deliberate geometry.

## Decoration vocabulary

- **Grid lines.** A fixed `::before` layer on every slide: two 1px linear gradients at 64px spacing, ink at 5.5% alpha. It sits behind all content and never moves.
- **Circle.** Solid pastel disc, or an outlined ink circle with white fill. Used for avatars, stat marks, and large background anchors.
- **Arch.** `border-radius: 999px 999px 0 0` — a pastel half-round rising from an edge. Used to frame a column without closing it.
- **Quarter-round.** `border-radius: 0 100% 0 0` (or mirrored) — a hard pastel corner that pushes the eye forward.
- **Checkerboard.** `repeating-conic-gradient(ink 0 25%, #fff 0 50%)` at 36px (or 11px in the chrome). Always 2px ink border. Used as a small accent block, never as a full background.
- **Highlight bar.** Inline span behind a keyword, `box-decoration-break: clone`, 0.08em horizontal padding. Pink for emphasis, sky/lime/tangerine for variety. One highlight per headline.
- **Sticker pill.** 2px ink outline, `border-radius: 999px`, 10px/22px padding, Archivo 800 at 30px uppercase. May be white or any pastel; may be rotated ±3–4° when floating over art.
- **2px rule.** Every band divider, card border, table line, and axis. No 1px hairlines in composition (only the faint 64px grid is lighter).

## Typography

- **Display:** Archivo, weight 900, uppercase, letter-spacing −0.02 to −0.035em, line-height 0.86–0.95. Cover 150px, section 128px, slide headline 76px, card title 40px.
- **Body:** Space Grotesk, weight 400–500, sentence case, 30px minimum, line-height 1.35–1.48. Lead paragraphs 36px.
- **Labels:** Archivo 800 at 30px in uppercase with 0.02–0.14em tracking. The chrome, kickers, pills, and table headers all use this voice.
- **Never below 30px.** Body, captions, labels, and page numbers are all at least 30px on the 1920px canvas.

## Animation spec

- **Pastel wipe (entry, ~450ms).** A full-slide `::after` block in the slide's `--wipe` color scales from `scaleX(0)` to `scaleX(1)` with `transform-origin: left`, then immediately flips to `transform-origin: right` and collapses to `scaleX(0)`. Easing: `cubic-bezier(.7, 0, .2, 1)`. The whole move is one hard, graphic sweep.
- **Content rise (~560ms, 100ms delay).** `.main` translates from `translateY(18px)` and fades from 0 to 1 on the same easing, so content settles just after the wipe clears.
- **Snappy, no bounce.** No spring, no overshoot, no long fades. The deck should feel confident, not playful in its timing.
- **Reduced motion.** Under `prefers-reduced-motion: reduce`, both the wipe and the rise are disabled.
- **One navigation runtime.** `deck-stage.js` owns keyboard nav, scaling, hash restore, and the slide counter. There is no second keyboard handler in the deck.

## Do / Don't

**Do**

- Keep the top chrome identical on all 13 slides.
- Use one pastel as the headline highlight and leave the rest of the page white.
- Pair flat pastel fills with 2px ink borders and hard corners.
- Let Archivo 900 carry the hierarchy — one big line, then quiet support.
- Fill the slide with real content; the system is built for density.
- Keep every text element at 30px or larger.

**Don't**

- Don't add gradients, drop shadows, blur, or glass effects.
- Don't use pastels as text colors on white — they fail contrast. Pastels are backgrounds.
- Don't mix in a third typeface, a rounded card radius, or a new accent color.
- Don't use more than two pastels in one visual cluster without an ink rule between them.
- Don't center-align a whole slide; the system is left-aligned and grid-driven.
- Don't add a second keyboard handler or override deck-stage's overlay behavior.
