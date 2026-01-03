/**
 * Network helpers for consistent fetch calls.
 */
const csrfToken = () =>
  document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

const mergeHeaders = (headers = {}) => {
  const token = csrfToken();
  const normalized =
    headers instanceof Headers ? Object.fromEntries(headers) : headers;

  return token && !normalized['X-CSRF-Token']
    ? { ...normalized, 'X-CSRF-Token': token }
    : normalized;
};

export const fetchWithCsrf = (url, options = {}) => {
  const headers = mergeHeaders(options.headers);

  return fetch(url, { ...options, headers });
};

export const jsonFetch = async (url, options = {}) => {
  const headers = mergeHeaders({
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    ...options.headers
  });

  const response = await fetch(url, { ...options, headers });
  const contentType = response.headers.get('content-type') || '';
  const isJson = contentType.includes('application/json');
  const data = isJson ? await response.json().catch(() => null) : null;

  if (!response.ok) {
    const error = new Error(`Request failed with status ${response.status}`);

    error.status = response.status;
    error.data = data;
    throw error;
  }

  return data;
};
