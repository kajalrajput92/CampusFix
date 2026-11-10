import assert from 'node:assert/strict';
import { afterEach, beforeEach, test } from 'node:test';

const session = new Map();
globalThis.sessionStorage = {
  getItem: (key) => session.get(key) ?? null,
  setItem: (key, value) => session.set(key, value),
  removeItem: (key) => session.delete(key),
};
globalThis.window = Object.assign(new EventTarget(), {
  location: { origin: 'http://localhost:5173' },
});

const { api, apiBinary, clearSession, dataOf, readSession, saveSession } = await import('../src/api.js');

beforeEach(() => {
  session.clear();
  globalThis.fetch = async () => new Response(JSON.stringify({ success: true, data: {} }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});

afterEach(() => {
  clearSession();
});

test('session helpers safely save, read, and clear the tab session', () => {
  saveSession('test-token');
  assert.deepEqual(readSession(), { token: 'test-token' });
  clearSession();
  assert.equal(readSession(), null);
});

test('JSON API sends bearer auth and query/body and returns the envelope', async () => {
  let request;
  globalThis.fetch = async (url, options) => {
    request = { url: new URL(url), options };
    return new Response(JSON.stringify({ success: true, data: { user_id: 7 } }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  };

  const result = await api('/admin/students', {
    method: 'POST',
    query: { page: 2 },
    body: { active: true },
    token: 'admin-token',
  });

  assert.deepEqual(result.data, { user_id: 7 });
  assert.equal(request.url.pathname, '/api/admin/students');
  assert.equal(request.url.searchParams.get('page'), '2');
  assert.equal(request.options.headers.Authorization, 'Bearer admin-token');
  assert.equal(request.options.headers['Content-Type'], 'application/json');
  assert.equal(request.options.body, JSON.stringify({ active: true }));
});

test('401 clears the saved token and dispatches the unauthorized event', async () => {
  saveSession('expired-token');
  let unauthorizedEvents = 0;
  window.addEventListener('campusfix:unauthorized', () => { unauthorizedEvents += 1; }, { once: true });
  globalThis.fetch = async () => new Response(JSON.stringify({ success: false, message: 'Unauthorized.' }), {
    status: 401,
    headers: { 'Content-Type': 'application/json' },
  });

  await assert.rejects(api('/auth/me', { token: 'expired-token' }), { status: 401 });
  assert.equal(readSession(), null);
  assert.equal(unauthorizedEvents, 1);
});

test('binary image request sends bearer auth and returns image bytes', async () => {
  let request;
  globalThis.fetch = async (url, options) => {
    request = { url: new URL(url), options };
    return new Response(new Uint8Array([1, 2, 3]), {
      status: 200,
      headers: { 'Content-Type': 'image/png' },
    });
  };

  const blob = await apiBinary('/complaints/image', { query: { id: 13 }, token: 'staff-token' });
  assert.equal(request.url.searchParams.get('id'), '13');
  assert.equal(request.options.headers.Authorization, 'Bearer staff-token');
  assert.match(request.options.headers.Accept, /image/);
  assert.equal(blob.type, 'image/png');
  assert.deepEqual([...new Uint8Array(await blob.arrayBuffer())], [1, 2, 3]);
});

test('dataOf returns the data field or an empty list', () => {
  assert.deepEqual(dataOf({ data: [1, 2] }), [1, 2]);
  assert.deepEqual(dataOf({}), []);
});
