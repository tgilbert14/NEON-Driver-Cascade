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
