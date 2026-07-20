#!/usr/bin/env node
/* Boot check for the self-contained pages.
 *
 *   node check_boot.js plot.html [walk.html index.html ...]
 *
 * `node --check` only validates SYNTAX. It happily passes a page whose script throws
 * on the very first run - which is exactly how a "Reconstructing the plot..." overlay
 * ends up frozen forever, because the overlay is only hidden on the last line.
 *
 * This runs the page's authored script for real, against a deliberately dumb DOM and a
 * Proxy-based THREE stub, and reports the first exception with its line. It cannot
 * prove the page LOOKS right - nothing here renders - but it does prove the script
 * reaches its end, which is the difference between a working page and a frozen one.
 *
 * Caught on first use: `var SITENAME` declared 28 lines after the code that read it.
 * Hoisted to undefined, so `SITENAME[site]` threw and the loader never lifted.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

// ---- a stub that tolerates absolutely anything done to it -------------------
function anything(name) {
  const f = function () { return anything(name + '()'); };
  return new Proxy(f, {
    get(_, k) {
      if (k === Symbol.toPrimitive) return () => 0;
      if (k === 'then') return undefined;             // don't look thenable
      if (k === 'length' || k === 'size') return 0;
      if (k === 'toString') return () => name;
      return anything(name + '.' + String(k));
    },
    set() { return true; },
    has() { return true; },
    construct() { return anything('new ' + name); },
    apply() { return anything(name + '()'); },
  });
}

function makeEl(id) {
  const el = {
    id, tagName: 'DIV', className: '', dataset: {}, hidden: false,
    // a real CSSStyleDeclaration, not a bare object: pages legitimately call
    // documentElement.style.setProperty(...) to drive CSS custom properties
    style: { setProperty(){}, getPropertyValue(){ return ''; }, removeProperty(){} },
    textContent: '', innerHTML: '', value: '0', checked: false,
    children: [], attributes: [], scrollHeight: 0, clientHeight: 0, offsetParent: {},
    classList: { add(){}, remove(){}, toggle(){return false;}, contains(){return false;} },
    appendChild(c){ this.children.push(c); return c; },
    addEventListener(){}, removeEventListener(){}, dispatchEvent(){return true;},
    setAttribute(){}, getAttribute(){return null;}, removeAttribute(){}, hasAttribute(){return false;},
    focus(){}, click(){}, closest(){ return makeEl('closest'); },
    querySelector(){ return makeEl('q'); }, querySelectorAll(){ return []; },
    getBoundingClientRect(){ return {top:0,left:0,right:0,bottom:0,width:100,height:100}; },
    getContext(){ return anything('ctx'); },
    insertBefore(c){ return c; }, remove(){},
  };
  return el;
}

function run(file) {
  const html = fs.readFileSync(file, 'utf8');
  // the authored script is the last bare <script>...</script>
  const bare = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m => m[1]);
  if (!bare.length) return { file, ok: false, err: 'no bare <script> block found' };
  const code = bare[bare.length - 1];

  // The pages read their data out of <script type="application/json"> tags via
  // getElementById(...).textContent, so the stub has to serve the REAL content or the
  // very first JSON.parse fails and masks whatever we were actually testing for.
  const jsonBlocks = new Map();
  for (const m of html.matchAll(/<script id="([^"]+)" type="application\/json">([\s\S]*?)<\/script>/g)) {
    jsonBlocks.set(m[1], m[2]);
  }

  const els = new Map();
  const doc = {
    getElementById(id){
      if(!els.has(id)){ const e = makeEl(id);
        if(jsonBlocks.has(id)) e.textContent = jsonBlocks.get(id);
        els.set(id, e); }
      return els.get(id);
    },
    querySelector(){ return makeEl('q'); },
    querySelectorAll(){ return []; },
    createElement(t){ const e = makeEl('new'); e.tagName = String(t).toUpperCase(); return e; },
    createElementNS(){ return makeEl('ns'); },
    addEventListener(){}, removeEventListener(){},
    documentElement: makeEl('html'), body: makeEl('body'), head: makeEl('head'),
    characterSet: 'UTF-8', title: '',
  };
  const win = {
    document: doc, THREE: anything('THREE'), innerWidth: 1280, innerHeight: 800,
    devicePixelRatio: 1, location: { search: '', hostname: '', href: 'file:///x' },
    addEventListener(){}, removeEventListener(){},
    requestAnimationFrame(){ return 1; }, cancelAnimationFrame(){},
    setTimeout(){ return 1; }, clearTimeout(){}, setInterval(){ return 1; }, clearInterval(){},
    matchMedia(){ return { matches:false, addEventListener(){}, addListener(){} }; },
    getComputedStyle(){ return new Proxy({}, { get: () => '0px' }); },
    localStorage: { getItem(){return null;}, setItem(){}, removeItem(){} },
    history: { pushState(){}, replaceState(){}, back(){}, length: 1 },
    URLSearchParams: URLSearchParams, Map, Set, Math, JSON, console,
    AudioContext: anything('AudioContext'), webkitAudioContext: anything('AudioContext'),
    Image: function(){ return makeEl('img'); },
    performance: { now: () => 0 },
  };
  win.window = win; win.self = win; win.globalThis = win;

  const ctx = vm.createContext(win);
  try {
    new vm.Script(code, { filename: path.basename(file) + ':<script>' }).runInContext(ctx, { timeout: 15000 });
    return { file, ok: true };
  } catch (e) {
    const line = (e.stack || '').split('\n').find(l => l.includes('<script>')) || '';
    return { file, ok: false, err: e.name + ': ' + e.message, at: line.trim() };
  }
}

const files = process.argv.slice(2);
if (!files.length) { console.error('usage: node check_boot.js <file.html> [...]'); process.exit(2); }
let bad = 0;
for (const f of files) {
  const r = run(f);
  if (r.ok) console.log('  BOOT OK   ' + r.file);
  else { bad++; console.log('  BOOT FAIL ' + r.file + '\n            ' + r.err + (r.at ? '\n            ' + r.at : '')); }
}
process.exit(bad ? 1 : 0);
