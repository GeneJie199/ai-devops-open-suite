import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

const source = readFileSync(new URL('../assets/ui/suite-ui.js', import.meta.url), 'utf8');
const storageKey = 'ai-devops.ui.theme.v2';

function harness({ url = 'http://127.0.2.136:8766/team.html', saved, dark = false, storageDenied = false, links = [] } = {}) {
  const values = new Map(saved ? [[storageKey, saved]] : []);
  const events = [];
  const media = new Map();
  const location = { href: url };
  const document = {
    documentElement: { dataset: {} }, readyState: 'loading',
    querySelectorAll(selector) { return selector === '[data-suite-theme-select]' ? [] : links; },
    addEventListener() {},
  };
  const window = {
    matchMedia(query) {
      const entry = { matches: query.includes('color-scheme') ? dark : false, listeners: [], addEventListener(_, fn) { this.listeners.push(fn); } };
      media.set(query, entry); return entry;
    },
    dispatchEvent(event) { events.push(event); },
  };
  const sandbox = {
    window, document, location, URL, Object, Set,
    CustomEvent: class { constructor(type, options) { this.type = type; this.detail = options.detail; } },
    localStorage: {
      getItem(key) { if (storageDenied) throw new Error('storage denied'); return values.get(key) ?? null; },
      setItem(key, value) { if (storageDenied) throw new Error('storage denied'); values.set(key, value); },
    },
    history: { state: { retained: true }, replaceState(state, title, next) { assert.deepEqual(state, { retained: true }); location.href = String(next); } },
  };
  vm.runInNewContext(source, sandbox, { filename: 'shipped-suite-ui.js', timeout: 1000 });
  return { api: window.SuiteUI, document, location, values, events, window, media };
}
function link(href, dataset = {}) {
  let value = href; let writes = 0;
  return {
    dataset, get href() { return value; }, set href(next) { value = next; writes++; },
    get writes() { return writes; }, getAttribute(name) { return name === 'href' ? value : null; },
  };
}

test('incoming explicit theme wins, and changing it survives reload without losing Suite context', () => {
  const h = harness({ url: 'http://127.0.2.136:18766/team.html?suite-theme=dark&suite-fleetscope=http%3A%2F%2F127.0.2.136%3A18770%2F#providers', saved: 'light' });
  assert.equal(h.document.documentElement.dataset.suiteTheme, 'dark');
  h.api.setTheme('light');
  const next = new URL(h.location.href);
  assert.equal(next.searchParams.get('suite-theme'), 'light');
  assert.equal(next.searchParams.get('suite-fleetscope'), 'http://127.0.2.136:18770/');
  assert.equal(next.hash, '#providers');
  assert.equal(h.values.get(storageKey), 'light');
  assert.equal(harness({ url: next.href, saved: 'light' }).api.getTheme(), 'light');
});

test('cross-product presentation preserves discovered custom ports, hostname and module context', () => {
  const target = link('https://[::1]:19466/?suite-fleetscope=https%3A%2F%2F%5B%3A%3A1%5D%3A19470%2F', { suite: 'devcycle', suitePage: 'suite' });
  const h = harness({ saved: 'dark', links: [target] });
  h.api.refreshNavigation();
  const next = new URL(target.href);
  assert.equal(next.origin, 'https://[::1]:19466');
  assert.equal(next.pathname, '/suite.html');
  assert.equal(next.searchParams.get('suite-fleetscope'), 'https://[::1]:19470/');
  assert.equal(next.searchParams.get('suite-theme'), 'dark');
  h.api.refreshNavigation();
  assert.equal(target.writes, 1, 'observer must not rewrite an already decorated href forever');
});

test('unresolved, fragment, mail and executable links are not turned into module destinations', () => {
  const targets = [link(null), link('#providers'), link('mailto:help@example.invalid'), link('javascript:alert(1)')];
  harness({ links: targets }).api.refreshNavigation();
  assert.deepEqual(targets.map(x => x.writes), [0, 0, 0, 0]);
});

test('System follows OS changes; explicit Light remains stable and emits a palette event', () => {
  const h = harness({ dark: true });
  assert.equal(h.api.getTheme(), 'system');
  assert.equal(h.document.documentElement.dataset.suiteTheme, 'dark');
  const system = h.media.get('(prefers-color-scheme: dark)');
  system.matches = false; system.listeners.forEach(fn => fn());
  assert.equal(h.document.documentElement.dataset.suiteTheme, 'light');
  h.api.setTheme('light'); system.matches = true; system.listeners.forEach(fn => fn());
  assert.equal(h.document.documentElement.dataset.suiteTheme, 'light');
  const event = h.events.at(-1);
  assert.equal(event.type, 'suite:themechange');
  assert.equal(event.detail.mode, 'light');
  assert.equal(event.detail.resolved, 'light');
});

test('denied persistence and invalid external preferences do not prevent local presentation', () => {
  const h = harness({ storageDenied: true, dark: true, url: 'http://127.0.0.1:8766/?suite-theme=untrusted-value' });
  assert.equal(h.api.getTheme(), 'system');
  h.api.setTheme('light');
  assert.equal(h.document.documentElement.dataset.suiteTheme, 'light');
  h.api.setTheme('untrusted-value');
  assert.equal(h.api.getTheme(), 'light');
});

test('a valid incoming cross-product theme survives denied local storage', () => {
  const h = harness({ storageDenied: true, dark: false, url: 'http://127.0.2.136:8766/team.html?suite-theme=dark' });
  assert.equal(h.api.getTheme(), 'dark');
  assert.equal(h.document.documentElement.dataset.suiteTheme, 'dark');
  h.api.setTheme('light');
  assert.equal(new URL(h.location.href).searchParams.get('suite-theme'), 'light');
  assert.equal(h.document.documentElement.dataset.suiteTheme, 'light');
});

test('provider and delivery routes keep the destination instance and accessible fragment', () => {
  for (const [page, fragment] of [['providers', '#providers'], ['delivery', '#missions']]) {
    const target = link('http://127.0.2.168:8766/?suite-devcycle=http%3A%2F%2F127.0.2.168%3A8766%2F', { suite: 'devcycle', suitePage: page });
    harness({ links: [target] }).api.refreshNavigation();
    const parsed = new URL(target.href);
    assert.equal(parsed.hostname, '127.0.2.168');
    assert.equal(parsed.port, '8766');
    assert.equal(parsed.pathname, '/team.html');
    assert.equal(parsed.hash, fragment);
    assert.equal(parsed.searchParams.get('suite-devcycle'), 'http://127.0.2.168:8766/');
  }
});
