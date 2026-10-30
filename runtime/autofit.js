/*! autofit.js — html-slides mechanical font-fit runtime
 *
 * Embedded inline in every deck built by the html-slides skill. Its job:
 * guarantee that no slide's text overflows the fixed design canvas, no
 * matter the resolution or monitor size, WITHOUT any AI auditing.
 *
 * How it works (fully deterministic):
 *  1. Finds the deck's slide elements — direct light-DOM children of
 *     <deck-stage>, or the children of a `.slides-container` for scroll
 *     decks. Hidden slides are still measurable (visibility:hidden keeps
 *     layout), so ALL slides are fitted at load, not just the visible one.
 *  2. Relaxes nested text-clipping containers once (a fixed-height card
 *     with `overflow:hidden` that clips its own flowing text grows to fit)
 *     — font shrinking alone cannot beat pinned px margins inside a
 *     fixed box.
 *  3. Measures each slide in design-canvas coordinates — ancestor
 *     transforms (the stage's uniform scale) do not affect
 *     scroll/client metrics, so this is resolution-independent.
 *  4. For any slide whose content exceeds its box, scales ALL text on
 *     that slide (font-size + px line-heights) down uniformly — hierarchy
 *     preserved — toward the measured overflow factor, re-measuring after
 *     each pass until it fits, bottoms out at MIN_SCALE, or hits
 *     MAX_ITER. Fixed px margins make small under-shrinks converge rather
 *     than overshoot.
 *
 * Idempotent, dependency-free, safe to include once per page.
 */
(() => {
  if (window.__deckAutofit) return;
  window.__deckAutofit = true;

  const TOL = 1;         // px tolerance on both axes
  const MIN_SCALE = 0.4; // never shrink text below 40% of authored size
  const MAX_ITER = 12;   // per-slide convergence passes

  /** Slides already fitted — guards against accidental double-runs. */
  const processed = new WeakSet();

  const slideRoots = () => {
    const stage = document.querySelector('deck-stage');
    if (stage) {
      return Array.from(stage.children)
        .filter((el) => !/^(SCRIPT|STYLE|TEMPLATE)$/.test(el.tagName));
    }
    const container = document.querySelector('.slides-container');
    if (container) {
      return Array.from(container.children)
        .filter((el) => !/^(SCRIPT|STYLE|TEMPLATE)$/.test(el.tagName));
    }
    return [];
  };

  /** Snapshot authored font metrics of every descendant (+ the slide root)
   *  once, so repeated passes scale from the ORIGINAL values, not from the
   *  previously shrunk ones (prevents compounding drift). */
  const snapshot = (slide) => {
    const els = [slide].concat(Array.from(slide.querySelectorAll('*')));
    const sizes = [];
    const lineHeights = [];
    els.forEach((el) => {
      const cs = getComputedStyle(el);
      const fs = parseFloat(cs.fontSize);
      if (fs > 0) sizes.push([el, fs]);
      if (cs.lineHeight.endsWith('px')) lineHeights.push([el, parseFloat(cs.lineHeight)]);
    });
    return { sizes, lineHeights, k: 1 };
  };

  const applyScale = (snap, k) => {
    for (const [el, fs] of snap.sizes) el.style.fontSize = (fs * k) + 'px';
    for (const [el, lh] of snap.lineHeights) el.style.lineHeight = (lh * k) + 'px';
    snap.k = k;
  };

  /** A hidden-overflow (or max-height) container that clips its own
   *  flowing text is a layout defect in itself: reveal it instead of
   *  fighting it with infinite font shrink. Decorative clamps (image
   *  masks, grain overlays) hold no text and are left untouched. */
  const relaxClippedText = (slide) => {
    for (const el of slide.querySelectorAll('*')) {
      const cs = getComputedStyle(el);
      const clipped =
        /(hidden|clip)/.test(cs.overflowY) || /(hidden|clip)/.test(cs.overflowX);
      const maxPinned = cs.maxHeight !== 'none';
      if (!clipped && !maxPinned) continue;
      const limit = maxPinned ? parseFloat(cs.maxHeight) || 0 : el.clientHeight;
      if (el.scrollHeight > limit + TOL && el.textContent.trim()) {
        if (clipped) el.style.overflow = 'visible';
        if (maxPinned) el.style.maxHeight = 'none';
        const fixedPxHeight = /\d+(\.\d+)?px/.test(cs.height) &&
          parseFloat(cs.height) < el.scrollHeight;
        if (fixedPxHeight) el.style.height = 'auto';
      }
    }
  };

  const slideOverflowFactor = (slide) => Math.max(
    slide.scrollWidth / (slide.clientWidth || 1),
    slide.scrollHeight / (slide.clientHeight || 1)
  );

  /** Fit one slide. Returns the applied scale factor, or null if nothing
   *  was changed (it already fit, or there was nothing measurable).
   *  Failures are isolated: one bad slide must never abort the deck. */
  const fitSlide = (slide) => {
    if (processed.has(slide)) return null;
    try {
      relaxClippedText(slide);
      if (slideOverflowFactor(slide) <= 1.0001) return null; // slide fits
      const snap = snapshot(slide);
      if (!snap.sizes.length) return null;
      let k = 1;
      for (let i = 0; i < MAX_ITER && k > MIN_SCALE; i++) {
        const over = slideOverflowFactor(slide);
        if (over <= 1.0001) break;
        // Move toward the measured need, but never more than ~12% per pass.
        k = Math.max(MIN_SCALE, k * Math.max(1 / over, 0.88) * 0.995);
        applyScale(snap, k);
      }
      processed.add(slide);
      return k < 1 ? k : null;
    } catch (err) {
      console.warn('[autofit] could not fit a slide:', err);
      return null;
    }
  };

  const run = () => {
    const scaled = [];
    for (const slide of slideRoots()) {
      const k = fitSlide(slide);
      if (k != null) scaled.push(k.toFixed(2));
    }
    if (scaled.length) {
      console.info('[autofit] text scaled to fit on slides at factors:', scaled.join(', '));
    }
  };

  const start = () => {
    if (document.readyState === 'loading') {
      addEventListener('DOMContentLoaded', start);
      return;
    }
    // Webfonts change text metrics — measure once they are ready (or if
    // they stall/reject, measure anyway). No frame-waiting: rAF can be
    // starved under some headless/virtual-time environments.
    const fontsReady = document.fonts && document.fonts.ready
      ? document.fonts.ready
      : Promise.resolve();
    fontsReady.then(run, run);
  };

  start();
})();
