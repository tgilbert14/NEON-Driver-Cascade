/* =========================================================================
   cascade.js — small progressive-enhancement layer for the Response Atlas.

   Native HTML remains the baseline. This file adds focus-safe popovers and
   onboarding, delegated Shiny actions, keyboard activation for generated
   controls, responsive Plotly reflow, and scoped visual polish.
   ========================================================================= */

function cascadeReducedMotion() {
  return !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
}

// ---- "change site": open Overview, scroll to and focus the picker -----------
function cascadeChangeSite() {
  var overview = document.querySelector('a.nav-link[data-value="overview"]');
  if (overview) { try { overview.click(); } catch (e) {} }
  setTimeout(function () {
    var panel = document.getElementById("sitePanel");
    if (panel && panel.scrollIntoView) {
      try {
        panel.scrollIntoView({ behavior: cascadeReducedMotion() ? "auto" : "smooth", block: "center" });
      } catch (e) { panel.scrollIntoView(); }
    }
    var select = document.querySelector("#sitePanel .selectize-input, #site");
    if (select && select.focus) { try { select.focus(); } catch (e) {} }
  }, 120);
}

// ---- focus-safe bslib/Bootstrap popovers -------------------------------------
var cascadeLastPopoverTrigger = null;

function cascadeClosePopovers(restoreFocus) {
  var found = false;
  document.querySelectorAll(".popover").forEach(function (popover) {
    found = true;
    var trigger = popover.id ? document.querySelector('[aria-describedby="' + popover.id + '"]') : null;
    if (trigger) cascadeLastPopoverTrigger = trigger;
    if (trigger && window.bootstrap && window.bootstrap.Popover) {
      var instance = window.bootstrap.Popover.getInstance(trigger);
      if (instance) { instance.hide(); return; }
    }
    popover.remove();
    if (trigger) {
      trigger.removeAttribute("aria-describedby");
      trigger.setAttribute("aria-expanded", "false");
    }
  });
  if (found && restoreFocus && cascadeLastPopoverTrigger && cascadeLastPopoverTrigger.focus) {
    setTimeout(function () { try { cascadeLastPopoverTrigger.focus(); } catch (e) {} }, 0);
  }
  return found;
}

// Programmatic panel changes must not strand keyboard focus inside a panel that
// just became hidden. The server names either the active tab or a concrete ID.
function cascadeRegisterFocusHandler() {
  if (!window.Shiny || !window.Shiny.addCustomMessageHandler ||
      window.cascadeFocusHandlerRegistered) return;
  window.cascadeFocusHandlerRegistered = true;
  window.Shiny.addCustomMessageHandler("cascade-focus", function (message) {
    window.setTimeout(function () {
      var target = null;
      if (message && message.id) target = document.getElementById(message.id);
      if (!target && message && message.tab) {
        var candidates = document.querySelectorAll(".nav-link[data-value], [role='tab'][data-value]");
        for (var i = 0; i < candidates.length; i += 1) {
          if (candidates[i].getAttribute("data-value") === message.tab) {
            target = candidates[i]; break;
          }
        }
      }
      if (!target) return;
      if (target.matches("select.shiny-bound-input") && target.offsetParent === null) {
        var wrapper = target.closest(".form-group");
        target = wrapper && wrapper.querySelector(".selectize-input, select:not([aria-hidden='true'])") || target;
      }
      if (!target.hasAttribute("tabindex") && !/^(A|BUTTON|INPUT|SELECT|TEXTAREA)$/.test(target.tagName))
        target.setAttribute("tabindex", "-1");
      try { target.focus({ preventScroll: false }); } catch (e) { target.focus(); }
    }, message && message.delay ? message.delay : 140);
  });
}

document.addEventListener("shiny:connected", cascadeRegisterFocusHandler);
if (window.jQuery) window.jQuery(document).on("shiny:connected", cascadeRegisterFocusHandler);
window.setTimeout(cascadeRegisterFocusHandler, 800);
document.addEventListener("click", function (event) {
  var infoTrigger = event.target.closest(".info-dot, .concept-i");
  if (infoTrigger) {
    cascadeLastPopoverTrigger = infoTrigger;
    return;
  }
  if (event.target.closest(".popover") || event.target.closest("bslib-popover")) return;
  if (document.querySelector(".popover")) cascadeClosePopovers(false);
});

// ---- delegated app actions: no per-link inline JavaScript required -----------
function cascadeDispatchAction(element) {
  if (!element) return false;
  var action = element.getAttribute("data-cascade-action");
  if (action === "change-site") {
    cascadeChangeSite();
    return true;
  }
  if (!window.Shiny || !window.Shiny.setInputValue) return false;
  var inputName = null;
  var value = null;
  if (action === "select-site") {
    inputName = "goSite"; value = element.getAttribute("data-site");
  } else if (action === "goto-tab") {
    inputName = "gotoTab"; value = element.getAttribute("data-tab");
  } else if (action === "inspect-qc") {
    inputName = "qcInspect"; value = element.getAttribute("data-key");
  } else if (action === "inspect-score") {
    inputName = "sbCell"; value = element.getAttribute("data-value");
  }
  if (!inputName || value == null || value === "") return false;
  window.Shiny.setInputValue(inputName, value, { priority: "event" });
  return true;
}

function cascadeDispatchShinyInput(element) {
  if (!element || !window.Shiny || !window.Shiny.setInputValue) return false;
  var inputName = element.getAttribute("data-shiny-input");
  var value = element.getAttribute("data-shiny-value");
  if (!inputName || value == null || value === "") return false;
  window.Shiny.setInputValue(inputName, value, { priority: "event" });
  return true;
}

document.addEventListener("click", function (event) {
  var action = event.target.closest("[data-cascade-action], [data-shiny-input]");
  if (!action) return;
  var dispatched = action.hasAttribute("data-cascade-action")
    ? cascadeDispatchAction(action)
    : cascadeDispatchShinyInput(action);
  if (dispatched) event.preventDefault();
});

document.addEventListener("keydown", function (event) {
  if (event.key === "Escape" && cascadeClosePopovers(true)) {
    event.preventDefault();
    return;
  }
  if (event.repeat || (event.key !== "Enter" && event.key !== " ")) return;
  if (event.target.closest("button, a[href], input, select, textarea, summary")) return;
  // Only app-owned non-native controls need this fallback. Bootstrap/bslib
  // popover triggers already implement Enter/Space; re-clicking every generic
  // role=button would bubble into a second toggle and immediately close them.
  var buttonLike = event.target.closest(
    '[role="button"][data-cascade-action], [role="button"][data-shiny-input]'
  );
  if (!buttonLike) return;
  event.preventDefault();
  buttonLike.click();
});

// ---- generated-output accessibility ------------------------------------------
function cascadeCaptionFor(table) {
  if (table.classList.contains("driver-tbl")) return "Current build-locked driver pairings and their data verdicts";
  if (table.classList.contains("sig-tbl")) return "Signals measured at the selected site";
  if (table.classList.contains("sb-table")) return "Site by current-pairing direction scoreboard";
  return "NEON Response Atlas data table";
}

function cascadeEnhanceTable(table) {
  if (!table || table.hasAttribute("data-a11y-table")) return;
  table.setAttribute("data-a11y-table", "true");
  if (!table.querySelector("caption")) {
    var caption = table.createCaption();
    caption.className = "visually-hidden";
    caption.textContent = cascadeCaptionFor(table);
  }
  table.querySelectorAll("thead th").forEach(function (header) { header.setAttribute("scope", "col"); });
  if (!table.closest(".table-scroll, .table-region, .qc-cap-scroll, .sb-scroll")) {
    var wrapper = document.createElement("div");
    wrapper.className = "table-scroll";
    wrapper.setAttribute("role", "region");
    wrapper.setAttribute("tabindex", "0");
    wrapper.setAttribute("aria-label", cascadeCaptionFor(table));
    table.parentNode.insertBefore(wrapper, table);
    wrapper.appendChild(table);
  }
}

function cascadeEnhanceScoreCell(cell) {
  if (!cell || cell.querySelector(".sb-cell-button")) return;
  var label = cell.getAttribute("title") || ("Open detail for " + cell.textContent.trim());
  var button = document.createElement("button");
  button.type = "button";
  button.className = "sb-cell-button";
  button.setAttribute("aria-label", label);
  button.textContent = cell.textContent.trim() || "Open";
  cell.textContent = "";
  cell.removeAttribute("role");
  cell.removeAttribute("tabindex");
  cell.appendChild(button);
}

function cascadeEnhanceDom(root) {
  var scope = root && root.querySelectorAll ? root : document;
  scope.querySelectorAll("table.inspect-tbl, table.sb-table").forEach(cascadeEnhanceTable);
  scope.querySelectorAll(".sb-cell.sb-clk").forEach(cascadeEnhanceScoreCell);
  scope.querySelectorAll('[role="button"]:not(button):not(a)').forEach(function (control) {
    if (!control.hasAttribute("tabindex")) control.setAttribute("tabindex", "0");
  });
  scope.querySelectorAll(".qc-cap-scroll, .sb-scroll").forEach(function (region) {
    if (!region.hasAttribute("tabindex")) region.setAttribute("tabindex", "0");
    if (!region.hasAttribute("role")) region.setAttribute("role", "region");
  });
}

// ---- Plotly hidden-tab reflow + viewport signal -------------------------------
document.addEventListener("shown.bs.tab", function () {
  setTimeout(function () {
    cascadeEnhanceDom(document);
    try { window.dispatchEvent(new Event("resize")); } catch (e) {}
  }, 60);
});

(function () {
  function sendWidth() {
    if (window.Shiny && window.Shiny.setInputValue) {
      window.Shiny.setInputValue("vw", window.innerWidth);
    }
  }
  if (window.jQuery) window.jQuery(document).on("shiny:connected", sendWidth);
  document.addEventListener("shiny:connected", sendWidth);
  window.addEventListener("resize", function () {
    clearTimeout(window.__cascadeViewportTimer);
    window.__cascadeViewportTimer = setTimeout(sendWidth, 200);
  });
})();

// ---- restrained pointer sheen + one-shot card reveal -------------------------
(function () {
  var reduce = cascadeReducedMotion();

  function track(event) {
    var element = event.currentTarget;
    element.__cascadePointer = { x: event.clientX, y: event.clientY };
    if (element.__cascadePointerFrame) return;
    element.__cascadePointerFrame = window.requestAnimationFrame(function () {
      var rect = element.getBoundingClientRect();
      var point = element.__cascadePointer;
      element.style.setProperty("--mx", ((point.x - rect.left) / rect.width * 100).toFixed(1) + "%");
      element.style.setProperty("--my", ((point.y - rect.top) / rect.height * 100).toFixed(1) + "%");
      element.__cascadePointerFrame = null;
    });
  }
  function reset(event) {
    event.currentTarget.style.setProperty("--mx", "50%");
    event.currentTarget.style.setProperty("--my", "50%");
  }
  function bindHolo() {
    if (reduce) return;
    document.querySelectorAll(".hero-band:not(.hero-band-compact) .hero-verdict:not([data-holo])").forEach(function (element) {
      element.setAttribute("data-holo", "true");
      element.addEventListener("pointermove", track);
      element.addEventListener("pointerleave", reset);
    });
  }

  var observer = (!reduce && "IntersectionObserver" in window) ? new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.08, rootMargin: "0px 0px -40px 0px" }) : null;

  function bindReveal() {
    if (!observer) return;
    document.querySelectorAll(".main-tabs-wrap .card:not([data-reveal])").forEach(function (element) {
      element.setAttribute("data-reveal", "true");
      element.classList.add("reveal-card");
      observer.observe(element);
    });
  }
  function enhance() { bindHolo(); bindReveal(); cascadeEnhanceDom(document); }

  if (window.jQuery) {
    window.jQuery(document).on("shiny:connected", function () { setTimeout(enhance, 60); });
    window.jQuery(document).on("shiny:value", function (event) {
      setTimeout(function () {
        cascadeEnhanceDom(event.target || document);
        if (event.target && event.target.id === "heroStats") bindHolo();
      }, 30);
    });
  }
  document.addEventListener("shown.bs.tab", function () { setTimeout(enhance, 80); });
  document.addEventListener("DOMContentLoaded", function () { cascadeEnhanceDom(document); });

  var tries = 0;
  var early = setInterval(function () {
    enhance();
    if (++tries > 9 || document.querySelector(".hero-verdict[data-holo]")) clearInterval(early);
  }, 350);
})();

// ---- first-visit guide: truly hidden/inert before and after use ---------------
(function () {
  var armed = false;

  function setGuideInert(guide, value) {
    if (value) guide.setAttribute("inert", "");
    else guide.removeAttribute("inert");
    try { guide.inert = value; } catch (e) {}
  }

  function showGuide() {
    if (armed) return;
    var guide = document.getElementById("cascadeGuide");
    if (!guide) return;
    var seen = false;
    try { seen = window.localStorage.getItem("cascadeGuideSeen") === "1"; } catch (e) {}
    armed = true;
    if (seen) return;

    var reduce = cascadeReducedMotion();
    var closeButton = guide.querySelector(".cg-close");

    function dismiss() {
      var ownedFocus = guide.contains(document.activeElement);
      try { window.localStorage.setItem("cascadeGuideSeen", "1"); } catch (e) {}
      guide.classList.remove("show", "wave");
      guide.setAttribute("aria-hidden", "true");
      setGuideInert(guide, true);
      if (ownedFocus) {
        var main = document.getElementById("mainContent");
        if (main && main.focus) main.focus();
      }
      setTimeout(function () { if (!guide.classList.contains("show")) guide.hidden = true; }, reduce ? 0 : 550);
    }

    if (closeButton) closeButton.addEventListener("click", dismiss);
    setTimeout(function () {
      guide.hidden = false;
      setGuideInert(guide, false);
      guide.setAttribute("aria-hidden", "false");
      window.requestAnimationFrame(function () {
        guide.classList.add("show");
        if (!reduce) guide.classList.add("wave");
      });
    }, 1200);
  }

  if (window.jQuery) window.jQuery(document).on("shiny:connected", function () { setTimeout(showGuide, 400); });
  document.addEventListener("shiny:connected", function () { setTimeout(showGuide, 400); });
  document.addEventListener("DOMContentLoaded", function () { setTimeout(showGuide, 1600); });
})();
