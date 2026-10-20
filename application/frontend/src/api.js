const API = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1').replace(/\/$/, '');
async function request(path, options = {}) {
  let response;
  try {
    response = await fetch(`${API}${path}`, {
      ...options,
      headers: { ...(options.body ? {'Content-Type': 'application/json'} : {}), ...options.headers },
    });
  } catch {
    throw new Error('Cannot reach the API. Check that FastAPI is running and VITE_API_BASE_URL is correct.');
  }
  if (response.status === 204) return null;
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = typeof body.detail === 'string' ? body.detail : body.detail?.[0]?.msg || body.detail?.detail;
    throw new Error(detail || `Request failed (${response.status})`);
  }
  return body;
}
const qs = params => {
  const q = new URLSearchParams();
  Object.entries(params || {}).forEach(([k,v]) => { if (v !== '' && v !== null && v !== undefined) q.set(k, v); });
  return q.size ? `?${q}` : '';
};
export const api = {
  health: () => fetch(`${API.replace(/\/api\/v1$/, '')}/health`).then(r => { if(!r.ok) throw new Error('API health check failed'); return r.json(); }),
  dashboard: () => request('/dashboard'),
  tasks: params => request(`/tasks${qs(params)}`),
  task: id => request(`/tasks/${id}`),
  createTask: data => request('/tasks', {method:'POST', body:JSON.stringify(data)}),
  updateTask: (id,data) => request(`/tasks/${id}`, {method:'PATCH', body:JSON.stringify(data)}),
  deleteTask: id => request(`/tasks/${id}`, {method:'DELETE'}),
  goals: params => request(`/goals${qs(params)}`),
  createGoal: data => request('/goals', {method:'POST', body:JSON.stringify(data)}),
  updateGoal: (id,data) => request(`/goals/${id}`, {method:'PATCH', body:JSON.stringify(data)}),
  deleteGoal: id => request(`/goals/${id}`, {method:'DELETE'}),
  milestones: id => request(`/goals/${id}/milestones`),
  createMilestone: (id,data) => request(`/goals/${id}/milestones`, {method:'POST', body:JSON.stringify(data)}),
  updateMilestone: (id,data) => request(`/milestones/${id}`, {method:'PATCH', body:JSON.stringify(data)}),
  deleteMilestone: id => request(`/milestones/${id}`, {method:'DELETE'}),
};
