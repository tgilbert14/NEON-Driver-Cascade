/* =========================================================================
   cascade.js: small progressive-enhancement layer for the NEON Cross-Product Response Atlas.

   Native HTML remains the baseline. This file adds focus-safe popovers,
   delegated Shiny actions, keyboard activation for generated controls,
   responsive Plotly reflow, and scoped visual polish.
   ========================================================================= */

function cascadeReducedMotion() {
  return !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
}

// ---- "change site": open This site, scroll to and focus the picker ----------
// Leaving another tab re-renders the hero from compact to full, which moves the
// picker; so the scroll waits for that heroStats render (800 ms fallback).
function cascadeChangeSite() {
  var done = false;
  function go() {
    if (done) return;
    done = true;
    var panel = document.getElementById("sitePanel");
    if (panel && panel.scrollIntoView) {
      try {
        panel.scrollIntoView({ behavior: cascadeReducedMotion() ? "auto" : "smooth", block: "start" });
      } catch (e) { panel.scrollIntoView(); }
    }
    var s = document.getElementById("site");
    if (s && s.selectize) { try { s.selectize.focus(); } catch (e) {} }
    else {
      var select = document.querySelector("#sitePanel .selectize-input input, #site");
      if (select && select.focus) { try { select.focus(); } catch (e) {} }
    }
  }
  var siteTab = document.querySelector('a.nav-link[data-value="site"]');
  var onSite = siteTab && siteTab.classList.contains("active");
  if (onSite) { go(); return; }
  if (window.jQuery) {
    var handler = function (e) {
      if (e && e.name === "heroStats") {
        window.jQuery(document).off("shiny:value", handler);
        setTimeout(function () { window.requestAnimationFrame(go); }, 30);
      }
    };
    window.jQuery(document).on("shiny:value", handler);
    setTimeout(function () { window.jQuery(document).off("shiny:value", handler); go(); }, 800);
  } else {
    setTimeout(go, 400);
  }
  if (siteTab) { try { siteTab.click(); } catch (e) {} }
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
  if (event.key === "Escape" && window.cascadePinEscape && window.cascadePinEscape(event)) {
    event.preventDefault();
    return;
  }
  if (event.key !== "Enter" && event.key !== " ") return;
  // QC flags (the Small Mammal pattern): Enter or Space on a .qc-flag-click
  // clicks it once; a held key does not repeat the toggle.
  var qcFlag = event.target.closest && event.target.closest(".qc-flag-click");
  if (qcFlag) {
    event.preventDefault();
    if (!event.repeat) qcFlag.click();
    return;
  }
  if (event.repeat) return;
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
  if (table.classList.contains("pairings-tbl")) return "Pairings at this site";
  if (table.classList.contains("more-tbl")) return "More numbers for the selected pairing";
  if (table.classList.contains("sig-tbl")) return "Signals measured at the selected site";
  if (table.classList.contains("sb-table")) return "Every site, every pairing";
  return "NEON Cross-Product Response Atlas data table";
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
  var text = cell.textContent.trim();
  var title = cell.getAttribute("title") || "Open detail";
  // Label-in-name: the accessible name starts with the visible cell text.
  var label = text ? text + ", " + title : title;
  var button = document.createElement("button");
  button.type = "button";
  button.className = "sb-cell-button";
  button.setAttribute("aria-label", label);
  if (text) {
    button.textContent = text;
  } else {
    // A blank cell means not testable: keep it blank on screen, named for readers.
    var hidden = document.createElement("span");
    hidden.className = "visually-hidden";
    hidden.textContent = "not testable";
    button.appendChild(hidden);
  }
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
document.addEventListener("shown.bs.tab", function (event) {
  // On a narrow, horizontally scrolling tab strip keep the active tab in view.
  var tab = event && event.target;
  if (tab && tab.closest && tab.closest(".main-tabs-wrap") && tab.scrollIntoView) {
    try { tab.scrollIntoView({ block: "nearest", inline: "nearest", behavior: cascadeReducedMotion() ? "auto" : "smooth" }); } catch (e) {}
  }
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

// ---- hero "more" toggle: the verdict is clamped to four lines on phones ------
function cascadeHeroMoreSync() {
  document.querySelectorAll(".hero-verdict .hero-more").forEach(function (btn) {
    var text = document.getElementById(btn.getAttribute("aria-controls"));
    if (!text) return;
    var open = btn.getAttribute("aria-expanded") === "true";
    // Hide the toggle when the clamped text already fits.
    var clipped = text.scrollHeight > text.clientHeight + 2;
    btn.hidden = !open && !clipped;
  });
}
document.addEventListener("click", function (event) {
  var btn = event.target.closest && event.target.closest(".hero-more");
  if (!btn) return;
  var text = document.getElementById(btn.getAttribute("aria-controls"));
  var open = btn.getAttribute("aria-expanded") !== "true";
  btn.setAttribute("aria-expanded", open ? "true" : "false");
  btn.textContent = open ? "less" : "more";
  if (text) text.classList.toggle("is-open", open);
});
if (window.jQuery) {
  window.jQuery(document).on("shiny:value", function (e) {
    if (e && e.name === "heroStats") setTimeout(cascadeHeroMoreSync, 40);
  });
}
window.addEventListener("resize", function () {
  clearTimeout(window.__cascadeHeroTimer);
  window.__cascadeHeroTimer = setTimeout(cascadeHeroMoreSync, 150);
});

// ---- pin cards: a pinned site-year card on the One pairing scatter and the
// timeline. Pattern ported from NEON-Mosquito-Pulse www/pincards.js@780d4c7:
// the card HTML comes from the server (one per point, keyed by the point's
// customdata), the leader line is anchored in DATA coordinates so it follows
// the point through resize, and the plotly_click listener is re-bound on every
// render because a Plotly re-render purges the div's listeners.
(function () {
  "use strict";
  var NS = "http://www.w3.org/2000/svg";
  var lastPin = null;

  function boxFor(gd) {
    var box = gd.parentNode;
    if (box && !box.classList.contains("cascade-pinnable")) box.classList.add("cascade-pinnable");
    return box;
  }
  function axisKey(id, letter) {   // "x" -> "xaxis", "y2" -> "yaxis2"
    var n = String(id || letter).replace(/^[xy]/, "");
    return letter + "axis" + n;
  }
  function anchorPx(gd, box, pin) {
    var fl = gd && gd._fullLayout;
    if (!fl) return null;
    var xa = fl[axisKey(pin.__xid, "x")], ya = fl[axisKey(pin.__yid, "y")];
    if (!xa || !ya || typeof xa.l2p !== "function") return null;
    var g = gd.getBoundingClientRect(), b = box.getBoundingClientRect();
    return { x: xa.l2p(pin.__dx) + xa._offset + (g.left - b.left),
             y: ya.l2p(pin.__dy) + ya._offset + (g.top - b.top) };
  }
  function layer(box) {
    var s = box.querySelector(":scope > svg.cascade-pin-lines");
    if (!s) {
      s = document.createElementNS(NS, "svg");
      s.setAttribute("class", "cascade-pin-lines");
      s.setAttribute("aria-hidden", "true");
      box.appendChild(s);
    }
    return s;
  }
  function place(gd, box, pin) {
    var a = anchorPx(gd, box, pin);
    if (!a) return;
    pin.__line.setAttribute("x1", a.x); pin.__line.setAttribute("y1", a.y);
    pin.__dot.setAttribute("cx", a.x); pin.__dot.setAttribute("cy", a.y);
    var r = pin.getBoundingClientRect(), b = box.getBoundingClientRect();
    pin.__line.setAttribute("x2", r.left - b.left + r.width / 2);
    pin.__line.setAttribute("y2", r.top - b.top + r.height / 2);
  }
  function removePin(pin, restore) {
    if (!pin) return;
    if (pin.__line) pin.__line.remove();
    if (pin.__dot) pin.__dot.remove();
    var box = pin.__box;
    pin.remove();
    if (lastPin === pin) lastPin = null;
    if (restore) {
      var target = document.getElementById("scatterYearPick") || (box && box.querySelector(".js-plotly-plot"));
      if (target && target.focus) { try { target.focus(); } catch (e) {} }
    }
  }
  function clearBox(box) {
    box.querySelectorAll(".cascade-pin").forEach(function (p) { removePin(p, false); });
  }
  function openPin(gd, key, xid, yid, focus) {
    var cards = gd.__cascadeCards || {};
    var card = cards[key];
    if (!card || !card.html) return null;
    var box = boxFor(gd);
    var dup = Array.prototype.find.call(box.querySelectorAll(".cascade-pin"), function (p) { return p.__key === key; });
    if (dup) {
      dup.classList.remove("cascade-pulse"); void dup.offsetWidth; dup.classList.add("cascade-pulse");
      if (focus) dup.focus();
      return dup;
    }
    var pin = document.createElement("div");
    pin.className = "cascade-pin";
    pin.setAttribute("role", "group");
    pin.setAttribute("tabindex", "0");
    var title = (card.html.match(/<div class='pin-title'>([^<]*)<\/div>/) || [])[1] || key;
    pin.setAttribute("aria-label", "Pinned card: " + title.replace(/&amp;/g, "&") + ". Escape closes it.");
    pin.innerHTML = "<button type='button' class='cascade-pin-close' aria-label='Close pinned card'>&times;</button>" + card.html;
    pin.__box = box; pin.__key = key; pin.__dx = card.x; pin.__dy = card.y; pin.__xid = xid; pin.__yid = yid;
    pin.__gd = gd;
    box.appendChild(pin);
    var a = anchorPx(gd, box, pin);
    var bw = box.clientWidth, bh = box.clientHeight, pw = pin.offsetWidth, ph = pin.offsetHeight;
    var ax = a ? a.x : bw / 2, ay = a ? a.y : bh / 2;
    var left = ax + 18 + pw > bw - 4 ? ax - 18 - pw : ax + 18;
    pin.style.left = Math.max(4, Math.min(left, bw - pw - 4)) + "px";
    pin.style.top = Math.max(4, Math.min(ay - ph / 2, bh - ph - 4)) + "px";
    var svg = layer(box);
    var ln = document.createElementNS(NS, "line");
    ln.setAttribute("class", "cascade-pin-line");
    var dot = document.createElementNS(NS, "circle");
    dot.setAttribute("class", "cascade-pin-dot"); dot.setAttribute("r", "4.5");
    svg.appendChild(ln); svg.appendChild(dot);
    pin.__line = ln; pin.__dot = dot;
    place(gd, box, pin);
    pin.querySelector(".cascade-pin-close").addEventListener("click", function () { removePin(pin, true); });
    pin.addEventListener("focusin", function () { lastPin = pin; });
    // drag to move, kept inside the chart box
    pin.addEventListener("pointerdown", function (ev) {
      if (ev.target.closest("button, a")) return;
      ev.preventDefault();
      try { pin.setPointerCapture(ev.pointerId); } catch (e) {}
      var sx = ev.clientX - pin.offsetLeft, sy = ev.clientY - pin.offsetTop;
      function mv(em) {
        pin.style.left = Math.max(4, Math.min(em.clientX - sx, box.clientWidth - 40)) + "px";
        pin.style.top = Math.max(4, Math.min(em.clientY - sy, box.clientHeight - 28)) + "px";
        place(pin.__gd, box, pin);
      }
      function up() {
        pin.removeEventListener("pointermove", mv);
        pin.removeEventListener("pointerup", up); pin.removeEventListener("pointercancel", up);
      }
      pin.addEventListener("pointermove", mv);
      pin.addEventListener("pointerup", up); pin.addEventListener("pointercancel", up);
    });
    lastPin = pin;
    if (focus) { try { pin.focus({ preventScroll: true }); } catch (e) { pin.focus(); } }
    return pin;
  }
  function repositionAll(gd) {
    var box = gd.parentNode; if (!box) return;
    box.querySelectorAll(".cascade-pin").forEach(function (p) { p.__gd = gd; place(gd, box, p); });
  }

  // Called from each chart's onRender (every render).
  window.cascadePinBind = function (gd, data, kind) {
    if (!gd || typeof gd.on !== "function") return;
    var box = boxFor(gd);
    var sig = (data && data.sig) || "";
    if (gd.__cascadeSig !== undefined && gd.__cascadeSig !== sig) clearBox(box);
    gd.__cascadeSig = sig;
    gd.__cascadeCards = (data && data.cards) || {};
    gd.__cascadeKind = kind;
    if (gd.__cascadePinClick && gd.removeListener) { try { gd.removeListener("plotly_click", gd.__cascadePinClick); } catch (e) {} }
    gd.__cascadePinClick = function (d) {
      if (!d || !d.points || !d.points.length) return;
      var pt = d.points[0];
      if (pt.customdata == null) return;   // the fit line carries no card
      openPin(gd, String(pt.customdata), pt.xaxis && pt.xaxis._id, pt.yaxis && pt.yaxis._id, false);
    };
    gd.on("plotly_click", gd.__cascadePinClick);
    if (gd.__cascadePinRelayout && gd.removeListener) { try { gd.removeListener("plotly_relayout", gd.__cascadePinRelayout); } catch (e) {} }
    gd.__cascadePinRelayout = function () { repositionAll(gd); };
    gd.on("plotly_relayout", gd.__cascadePinRelayout);
    if (!box.__cascadeRO && window.ResizeObserver) {
      box.__cascadeRO = new ResizeObserver(function () {
        var g = box.querySelector(".js-plotly-plot"); if (g) repositionAll(g);
      });
      box.__cascadeRO.observe(box);
    }
    setTimeout(function () { repositionAll(gd); }, 0);
  };

  // Keyboard path: the One pairing year picker pins that year's card.
  document.addEventListener("change", function (e) {
    if (!e.target || e.target.id !== "scatterYearPick" || !e.target.value) return;
    var gd = document.getElementById("linkScatter");
    if (gd) openPin(gd, String(e.target.value), "x", "y", false);
  });

  // Escape closes the pin holding focus, else the newest pin.
  window.cascadePinEscape = function (event) {
    if (document.querySelector(".modal.show")) return false;
    var inPin = event.target.closest && event.target.closest(".cascade-pin");
    var pin = inPin || (lastPin && document.body.contains(lastPin) ? lastPin : null);
    if (!pin) {
      var all = document.querySelectorAll(".cascade-pin");
      pin = all.length ? all[all.length - 1] : null;
    }
    if (!pin) return false;
    removePin(pin, !!inPin);
    return true;
  };
})();
