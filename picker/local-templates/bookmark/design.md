---
version: 1.0
name: Bookmark
description: A studious, tactile notebook system on a white 1920x1080 page. A faint 32px dot grid, pastel bookmark tabs, page-edge shadows, and a notebook page-flip transition make structured content feel warm and hand-kept rather than corporate. Bricolage Grotesque carries display headlines, DM Sans keeps body copy clean, and Caveat supplies one human margin note per page.
colors:
  white: "#FFFFFF"
  ink: "#1F1F1F"
  muted: "#6B6B6B"
  dot-grid: "rgba(31,31,31,0.10)"
  rule: "rgba(31,31,31,0.13)"
  rule-soft: "rgba(31,31,31,0.08)"
  pink: "#FFD6E8"
  blue: "#D6ECFF"
  yellow: "#FFF3A3"
  mint: "#D9F2E6"
  lilac: "#E7D9FF"
  description: "White paper with a faint ink dot grid, dark ink type, and five pastel bookmark tabs used as section navigation."
typography:
  display:
    family: "Bricolage Grotesque"
    weights: "600-800"
    sizes:
      cover: "148px"
      page-title: "72-84px"
      section-divider: "230px"
      stat-number: "128px"
      card-title: "34-38px"
  body:
    family: "DM Sans"
    weights: "400-700"
    sizes:
      body-copy: "30-34px"
      captions-and-meta: "28-30px"
      chrome-labels: "24-28px"
  style:
    family: "Caveat"
    weights: "500-700"
    sizes: "40-56px"
spacing:
  canvas: "1920 x 1080"
  body-frame: "left 90px / right 160px / top 150px / bottom 90px"
  top-chrome: "36px from top, 16px padding below the rule"
  dot-grid: "32px tile"
  card-gap: "24px"
  column-gap: "70-90px"
  card-padding: "30-54px"
  page-tab-stack: "5 tabs, 10px gap, centered vertically on the right edge"
slides:
  - {n: 1, label: "Cover", layout: "title cover", section: "Start"}
  - {n: 2, label: "Agenda", layout: "agenda / table of contents", section: "Start"}
  - {n: 3, label: "Ideas", layout: "section divider", section: "Ideas"}
  - {n: 4, label: "Key Points", layout: "key points / bullets", section: "Ideas"}
  - {n: 5, label: "Two Columns", layout: "two-column text + visual", section: "Ideas"}
  - {n: 6, label: "Proof", layout: "four-number stat grid", section: "Proof"}
  - {n: 7, label: "Process", layout: "four-step process", section: "Proof"}
  - {n: 8, label: "Timeline", layout: "five-milestone timeline", section: "Proof"}
  - {n: 9, label: "Comparison", layout: "A vs B comparison table", section: "Proof"}
  - {n: 10, label: "Story", layout: "pull quote", section: "Story"}
  - {n: 11, label: "Figure", layout: "image / figure placeholder", section: "Story"}
  - {n: 12, label: "Team", layout: "four-person team grid", section: "Story"}
  - {n: 13, label: "Close", layout: "closing / call to action", section: "Close"}
bookmark-sections:
  - {label: "Start", slides: "0-1", color: "pink #FFD6E8", target: 0}
  - {label: "Ideas", slides: "2-4", color: "blue #D6ECFF", target: 2}
  - {label: "Proof", slides: "5-8", color: "yellow #FFF3A3", target: 5}
  - {label: "Story", slides: "9-11", color: "mint #D9F2E6", target: 9}
  - {label: "Close", slides: "12-12", color: "lilac #E7D9FF", target: 12}
---

# Bookmark

Bookmark is a notebook, not a poster. The page stays white and lightly dotted; structure comes from pastel tabs, crisp chrome, and confident grotesque type. Every slide is a sheet of paper in the same bound book, so the deck can hold dense material without losing its calm.

## The system at a glance

- **Canvas:** fixed 1920x1080, authored in px, scaled by `deck-stage`.
- **Paper:** pure white with a 32px dot-grid tile of `rgba(31,31,31,0.10)` at roughly 1.35px dots. No grain, no gradients across the main field.
- **Ink:** `#1F1F1F` for primary text, `#6B6B6B` for secondary copy.
- **Pastels:** the five tabs are the only saturated colours. They are used as large quiet fields, never as text colour on white.
- **Chrome:** every slide carries `BOOKMARK` plus its section name on the left, and `NN / 13` on the right, separated from the body by a hairline rule.
- **Tactility:** page-edge shadow down the right and bottom, a soft curl gradient on the left edge, and a page-shadow sweep during the flip.

## Typography

| Role | Family | Weight | Size / notes |
| --- | --- | --- | --- |
| Cover title | Bricolage Grotesque | 800 | 148px, line-height .90, tracking -.038em |
| Page title | Bricolage Grotesque | 800 | 72-84px, line-height .95, tracking -.03em |
| Section divider | Bricolage Grotesque | 800 | 230px, line-height .82 |
| Stat number | Bricolage Grotesque | 800 | 128px |
| Card / step title | Bricolage Grotesque | 700 | 34-38px |
| Body copy | DM Sans | 400-600 | 30-34px, line-height 1.35-1.55 |
| Meta / labels | DM Sans | 600-700 | 24-28px, uppercase, tracking .12-.18em |
| Margin notes | Caveat | 500-700 | 40-56px, used once per page at most |

Keep body copy at 30px or larger on the 1920x1080 canvas and headings at 34px or larger. The inline autofit runtime handles genuine overflow mechanically; do not pre-shrink type to make a layout "safe".

## Layout rules

1. **One body frame.** Content sits inside `left:90px; right:160px; top:150px; bottom:90px`. The larger right margin keeps text clear of the fixed bookmark tabs.
2. **Chrome is constant.** Top rule at 36px, section label left, page counter right. Never let content cross the chrome rule.
3. **Headers lead.** Every content slide starts with an eyebrow (section + topic) and one display headline. Supporting copy sits beneath or to the right, never above the headline.
4. **One idea per page.** The layouts in this deck are deliberately distinct: cover, agenda, divider, bullets, two-column, stat grid, process, timeline, comparison, quote, figure, team, close.
5. **Pastel fields are blocks.** Use pastel as a card fill, panel, or tab. Avoid pastel body text and avoid more than two pastel fields competing on one slide.
6. **Rounded but not bubbly.** Panels use 18-28px radii. Buttons and pills use full rounds. Rules stay square and hairline-thin.
7. **Tactile edges.** Keep the left page-curl gradient and the right/bottom edge shadow visible; they are the "paper" cue that ties the system together.

## Dot-grid background

```css
background-color: #FFFFFF;
background-image: radial-gradient(circle, rgba(31,31,31,.10) 1.35px, transparent 1.45px);
background-size: 32px 32px;
background-position: 16px 16px;
```

The grid is a guide, not a texture. Keep it faint enough that 30px body text reads cleanly at presentation distance. Pastel panels sit on top of the grid and may hide it entirely; that contrast is intentional.

## Bookmark navigation

Five fixed tabs sit outside `<deck-stage>`, stacked vertically on the right edge and centered in the viewport:

| Tab | Colour | Deck-stage index | Active range |
| --- | --- | --- | --- |
| Start | `#FFD6E8` | 0 | 0-1 |
| Ideas | `#D6ECFF` | 2 | 2-4 |
| Proof | `#FFF3A3` | 5 | 5-8 |
| Story | `#D9F2E6` | 9 | 9-11 |
| Close | `#E7D9FF` | 12 | 12-12 |

- Tabs are vertical (`writing-mode: vertical-rl`), with rounded left corners, a soft shadow, and a 12px `translateX` offset so they peek in from the page edge.
- The active tab slides flush to the edge, grows from 58px to 72px wide, and gains a deeper shadow.
- Each tab calls `document.querySelector('deck-stage').goTo(i)`.
- A `slidechange` listener reads `event.detail.index` and applies the active state by range.
- The stack is `position: fixed`, `z-index: 2147482500`, above the deck but below deck-stage's own bottom overlay. The nav container is `pointer-events: none`; the buttons re-enable pointer events.
- Keep the stack vertically centered so it never covers the bottom-center deck overlay or the top-right page counter.

## Page-flip animation

```css
@keyframes pageFlipIn {
  0%   { opacity: .3; transform: perspective(2400px) rotateY(-18deg); }
  55%  { opacity: .88; }
  100% { opacity: 1;  transform: perspective(2400px) rotateY(0deg); }
}
```

- Duration: 700ms.
- Easing: `cubic-bezier(.2,.8,.2,1)`.
- Transform origin: `left center`, so the page hinges on the binding edge.
- The active slide is the only element animated; deck-stage toggles `data-deck-active`.
- A `::after` layer sweeps a soft ink gradient from left to right during the same 700ms to suggest the shadow of a turning page.
- Respect `prefers-reduced-motion`: remove the flip and the sweep entirely.

The motion should feel like a page settling, not a card trick. No bounce, no rotation past zero, no scale. One flip per navigation.

## Component grammar

- **Cover:** oversized display title, one supporting line, a meta row, and a hanging rack of five pastel ribbons.
- **Agenda:** two columns of numbered rows, each with a pastel numeral chip.
- **Section divider:** giant section word on the left, a solid pastel panel with a numbered contents list on the right.
- **Bullets:** display headline, one list of five ruled rows with pastel dots, and a mint margin-note panel.
- **Two-column:** copy and checklist on the left, a stack of five slightly rotated colour swatches on the right.
- **Stat grid:** four full-height pastel cards, each with a tag, a huge number, a label, and one sentence.
- **Process:** four equal step cards on a shared hairline rail, each with a numbered circle and a deliverable line.
- **Timeline:** a horizontal rail with five dots, cards alternating above and below.
- **Comparison:** a three-column table with a muted "before" column and a pastel-blue "after" column.
- **Quote:** one large mint panel, an oversized white quote mark, and a Caveat attribution.
- **Figure:** a framed dot-grid canvas with five pastel bars and a labelled placeholder tag, plus notes in the right column.
- **Team:** four cards with pastel initials avatars and a short line each.
- **Close:** huge closing headline, a dark pill CTA, and a white action card with three numbered moves.

## Do

- Keep the canvas white and the dot grid faint.
- Let one pastel tab own the page's section colour.
- Use ink for all reading text and pastel for fields, chips, and tabs.
- Keep the chrome identical on all 13 slides.
- Author body copy at 30px or larger and let the inline autofit runtime handle real overflow.
- Leave the right gutter clear for the bookmark tabs.
- Keep one handwritten Caveat note per page at most.

## Don't

- Don't tint the whole page; pastel is a block, not a wash.
- Don't use more than two pastel fields on a single slide.
- Don't replace Bricolage Grotesque, DM Sans, or Caveat with lookalikes.
- Don't add a second keyboard handler or a second slide counter; deck-stage owns navigation and the counter overlay.
- Don't place content under the fixed right-edge tabs.
- Don't let the page-flip become a spin, bounce, or scale animation.
- Don't hand-shrink fonts to fix a layout; restructure or split the slide.
