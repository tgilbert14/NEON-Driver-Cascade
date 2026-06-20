/* =========================================================================
   cascade.js — lean client layer for the NEON Driver Cascade.

   Only what THIS app actually uses:
     1. dismissible "ⓘ" info popovers (outside-click + Esc),
     2. a plotly re-fit when a tab becomes visible (hidden-init sizing fix),
     3. a debounced viewport-width signal so charts can de-clutter on phones.

   Replaces the inherited small-mammal app.js, whose count-up / confetti /
   loading-overlay / guided-tour / card-export were all dead here — and whose
   body-wide MutationObserver fired a counter sweep on EVERY plotly render
   looking for zero `.count-up` elements (an active per-render perf drain).
   ========================================================================= */

// ---- dismiss any open bslib/Bootstrap info popover (outside-click + Esc) ----
function cascadeClosePopovers() {
  document.querySelectorAll(".popover").forEach(function (pop) {
    var trig = pop.id ? document.querySelector('[aria-describedby="' + pop.id + '"]') : null;
    if (trig && window.bootstrap && bootstrap.Popover) {
      var inst = bootstrap.Popover.getInstance(trig);
      if (inst) { inst.hide(); return; }
    }
    pop.remove(); // fallback: just remove the floating popover
  });
}
document.addEventListener("click", function (e) {
  if (e.target.closest(".popover") || e.target.closest(".info-dot") ||
      e.target.closest("bslib-popover")) return;            // inside/trigger -> leave it
  if (document.querySelector(".popover")) cascadeClosePopovers();
});
document.addEventListener("keydown", function (e) {
  if (e.key === "Escape") cascadeClosePopovers();
});

// ---- re-fit plotly the moment its tab becomes visible (hidden-init blank fix) ----
document.addEventListener("shown.bs.tab", function () {
  setTimeout(function () { try { window.dispatchEvent(new Event("resize")); } catch (e) {} }, 60);
});

// ---- debounced viewport-width signal (lets the ladder drop its legend on phones) ----
(function () {
  function sendW() { if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue("vw", window.innerWidth); }
  if (window.jQuery) jQuery(document).on("shiny:connected", sendW);
  document.addEventListener("shiny:connected", sendW);     // belt-and-suspenders
  window.addEventListener("resize", function () {
    clearTimeout(window.__vwt); window.__vwt = setTimeout(sendW, 200);
  });
})();

// ---- premium DDL polish: pointer-tracked holographic sheen + scroll-reveal --------
// The hero verdict card is the showpiece — an iridescent sheen + glare follow the
// cursor (--mx/--my). No body-wide observer: we re-bind only when the heroStats
// output re-renders (Shiny fires shiny:value on it). Reduced-motion users opt out.
(function () {
  var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function track(e) {
    var el = e.currentTarget, r = el.getBoundingClientRect();
    el.style.setProperty("--mx", ((e.clientX - r.left) / r.width * 100).toFixed(1) + "%");
    el.style.setProperty("--my", ((e.clientY - r.top) / r.height * 100).toFixed(1) + "%");
  }
  function reset(e) { e.currentTarget.style.setProperty("--mx", "50%"); e.currentTarget.style.setProperty("--my", "50%"); }
  function bindHolo() {
    if (reduce) return;
    document.querySelectorAll(".hero-verdict:not([data-holo])").forEach(function (el) {
      el.setAttribute("data-holo", "1");
      el.addEventListener("pointermove", track);
      el.addEventListener("pointerleave", reset);
    });
  }

  // Scroll-reveal: fade cards up as they enter the viewport (one-shot, gated on no-reduce).
  var io = (!reduce && "IntersectionObserver" in window) ? new IntersectionObserver(function (entries) {
    entries.forEach(function (en) { if (en.isIntersecting) { en.target.classList.add("is-visible"); io.unobserve(en.target); } });
  }, { threshold: 0.08, rootMargin: "0px 0px -40px 0px" }) : null;
  function bindReveal() {
    if (!io) return;
    document.querySelectorAll(".main-tabs-wrap .card:not([data-reveal])").forEach(function (el) {
      el.setAttribute("data-reveal", "1"); el.classList.add("reveal-card"); io.observe(el);
    });
  }
  function pass() { bindHolo(); bindReveal(); }

  // Shiny fires shiny:connected / shiny:value as jQuery events — native addEventListener
  // misses them, so bind via jQuery (with a native fallback for shown.bs.tab, a real DOM event).
  if (window.jQuery) {
    jQuery(document).on("shiny:connected", function () { setTimeout(pass, 60); });
    jQuery(document).on("shiny:value", function (e) {
      if (e.target && e.target.id === "heroStats") setTimeout(bindHolo, 30);
    });
  }
  // a new tab's cards mount on first show — re-scan then (cheap, scoped, no persistent observer)
  document.addEventListener("shown.bs.tab", function () { setTimeout(pass, 80); });
  // self-clearing early poll: binds as soon as the hero renders after connect, then stops
  var tries = 0, iv = setInterval(function () {
    pass(); if (++tries > 9 || document.querySelector(".hero-verdict[data-holo]")) clearInterval(iv);
  }, 350);
})();
