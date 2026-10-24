const API = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1').replace(/\/$/, '');

let accessToken = null;

export function setAccessToken(token) {
  accessToken = token;
}

async function request(path, options = {}) {
  let response;

  try {
    response = await fetch(`${API}${path}`, {
      ...options,
      headers: {
        ...(options.body ? { 'Content-Type': 'application/json' } : {}),
        ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
        ...options.headers,
      },
    });
  } catch {
    throw new Error(
      'Cannot reach the API. Check that FastAPI is running and VITE_API_BASE_URL is correct.'
    );
  }

  if (response.status === 204) return null;

  const body = await response.json().catch(() => ({}));

  if (!response.ok) {
    const detail =
      typeof body.detail === 'string'
        ? body.detail
        : body.detail?.[0]?.msg || body.detail?.detail;

    throw new Error(detail || `Request failed (${response.status})`);
  }

  return body;
}

const qs = (params) => {
  const q = new URLSearchParams();

  Object.entries(params || {}).forEach(([key, value]) => {
    if (value !== '' && value !== null && value !== undefined) {
      q.set(key, value);
    }
  });

  return q.size ? `?${q}` : '';
};

export const api = {
  // Authentication
  register: (data) =>
    request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  login: (data) =>
    request('/auth/login', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  googleLogin: (credential) =>
    request('/auth/google', {
      method: 'POST',
      body: JSON.stringify({ credential }),
    }),

  me: () => request('/auth/me'),
  
  // Password reset
requestPasswordReset: (email) =>
  request('/auth/forgot-password', {
    method: 'POST',
    body: JSON.stringify({ email }),
  }),

resetPassword: (token, newPassword) =>
  request('/auth/reset-password', {
    method: 'POST',
    body: JSON.stringify({
      token,
      new_password: newPassword,
    }),
  }),

  // API health
  health: () =>
    fetch(`${API.replace(/\/api\/v1$/, '')}/health`).then((response) => {
      if (!response.ok) throw new Error('API health check failed');
      return response.json();
    }),

  // Dashboard
  dashboard: () => request('/dashboard'),

  // Tasks
  tasks: (params) => request(`/tasks${qs(params)}`),
  task: (id) => request(`/tasks/${id}`),

  createTask: (data) =>
    request('/tasks', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateTask: (id, data) =>
    request(`/tasks/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),

  deleteTask: (id) =>
    request(`/tasks/${id}`, {
      method: 'DELETE',
    }),

  // Goals
  goals: (params) => request(`/goals${qs(params)}`),

  createGoal: (data) =>
    request('/goals', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateGoal: (id, data) =>
    request(`/goals/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),

  deleteGoal: (id) =>
    request(`/goals/${id}`, {
      method: 'DELETE',
    }),

  // Milestones
  milestones: (id) => request(`/goals/${id}/milestones`),

  createMilestone: (id, data) =>
    request(`/goals/${id}/milestones`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateMilestone: (id, data) =>
    request(`/milestones/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),

  deleteMilestone: (id) =>
    request(`/milestones/${id}`, {
      method: 'DELETE',
    }),
};