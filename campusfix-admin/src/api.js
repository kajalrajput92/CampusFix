const API_BASE = (
  import.meta.env?.VITE_API_BASE_URL ||
  (import.meta.env?.PROD ? 'https://campusfix-backend-sdzj.onrender.com/api' : '/api')
).replace(/\/$/, '');
const TOKEN_KEY = 'campusfix_admin_session';

export function readSession() {
  try {
    return JSON.parse(sessionStorage.getItem(TOKEN_KEY) || 'null');
  } catch {
    sessionStorage.removeItem(TOKEN_KEY);
    return null;
  }
}

export function saveSession(token) {
  sessionStorage.setItem(TOKEN_KEY, JSON.stringify({ token }));
}

export function clearSession() {
  sessionStorage.removeItem(TOKEN_KEY);
}

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

export async function api(path, { method = 'GET', query, body, token, signal } = {}) {
  const url = new URL(`${API_BASE}${path}`, window.location.origin);
  Object.entries(query || {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, value);
  });
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  let response;
  try {
    response = await fetch(url, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
      signal,
    });
  } catch (error) {
    if (error.name === 'AbortError') throw error;
    throw new ApiError('Cannot reach the CampusFix API. Check the API URL and server.', 0);
  }
  let payload;
  try {
    payload = await response.json();
  } catch {
    throw new ApiError(`The API returned an invalid response (${response.status}).`, response.status);
  }
  if (response.status === 401) {
    clearSession();
    window.dispatchEvent(new Event('campusfix:unauthorized'));
  }
  if (!response.ok || payload?.success === false) {
    throw new ApiError(payload?.message || `Request failed (${response.status}).`, response.status);
  }
  return payload;
}

export async function apiBinary(path, { query, token, signal } = {}) {
  const url = new URL(`${API_BASE}${path}`, window.location.origin);
  Object.entries(query || {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, value);
  });
  let response;
  try {
    response = await fetch(url, { headers: { Accept: 'image/*, application/json', Authorization: `Bearer ${token}` }, signal });
  } catch (error) {
    if (error.name === 'AbortError') throw error;
    throw new ApiError('Cannot reach the CampusFix API.', 0);
  }
  if (response.status === 401) {
    clearSession();
    window.dispatchEvent(new Event('campusfix:unauthorized'));
  }
  if (!response.ok) {
    let message = `Request failed (${response.status}).`;
    try { message = (await response.json()).message || message; } catch { /* binary error body */ }
    throw new ApiError(message, response.status);
  }
  return response.blob();
}

export const dataOf = (payload) => payload?.data ?? [];
