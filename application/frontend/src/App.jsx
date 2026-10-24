import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Activity, ArrowDownUp, ArrowRight, Bell, Calendar, CalendarClock, Check, CheckCheck,
  ChevronDown, CircleHelp, Clock3, Command, Flag, FolderKanban, Goal, LayoutDashboard,
  ListTodo, Menu, MoreHorizontal, Plus, Search, Settings2, Sparkles, Target, Trash2,
  TrendingUp, X, Zap, CircleAlert, Pencil, CalendarDays, RefreshCw, LogOut
} from 'lucide-react';
import { api, setAccessToken } from './api';

const navGroups = [
  {title:'WORKSPACE', items:[
    {id:'dashboard',label:'Dashboard',icon:LayoutDashboard},
    {id:'today',label:'Today',icon:SunIcon},
    {id:'tomorrow',label:'Tomorrow',icon:CalendarClock},
    {id:'all',label:'All tasks',icon:ListTodo},
  ]},
  {title:'PLANNING', items:[
    {id:'overdue',label:'Overdue',icon:CircleAlert},
    {id:'missing',label:'Missing due date',icon:Calendar},
    {id:'weekly',label:'This week',icon:CalendarDays},
    {id:'monthly',label:'This month',icon:Calendar},
    {id:'completed',label:'Completed',icon:CheckCheck},
  ]},
  {title:'GROWTH', items:[
    {id:'short',label:'Short-term plans',icon:Zap},
    {id:'long',label:'Long-term plans',icon:Target},
    {id:'goals',label:'All goals',icon:Flag},
  ]},
];
function SunIcon(props){ return <Sparkles {...props}/>; }
const todayString = () => new Date().toLocaleDateString('en-CA');
const prettyDate = (value, options={month:'short',day:'numeric'}) => value ? new Date(`${value}T12:00:00`).toLocaleDateString('en-US',options) : 'No due date';
const initialsFor = user => String(user?.full_name || user?.name || user?.email || 'User').trim().split(/\s+/).map(part => part[0]).join('').slice(0, 2).toUpperCase();
function readStoredUser() {
  try { return JSON.parse(sessionStorage.getItem('daymark_user') || 'null'); } catch { return null; }
}

const emptyTask = {title:'',description:'',status:'Pending',priority:'Medium',due_date:'',goal_id:''};
const emptyGoal = {title:'',description:'',goal_type:'Short-Term',priority:'Medium',status:'Active',target_date:''};
const priorityClass = p => `priority priority-${String(p||'medium').toLowerCase()}`;
const statusClass = s => `status status-${String(s||'pending').toLowerCase().replace(' ','-')}`;

function AuthScreen({ onSubmit, onGoogleLogin, onForgot, onReset, error, loading }) {
  const resetToken = new URLSearchParams(window.location.search).get('token');
  const [mode, setMode] = useState(resetToken ? 'reset' : 'login');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [localError, setLocalError] = useState('');
  const [googleReady, setGoogleReady] = useState(false);

  useEffect(() => {
    const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
    console.log("Google Client ID loaded:", Boolean(clientId), clientId);

    if (!clientId || mode === 'forgot' || mode === 'reset') {
      setGoogleReady(false);
      return undefined;
    }

    let cancelled = false;
    let timer = null;
    let script = document.querySelector(
      'script[src="https://accounts.google.com/gsi/client"]'
    );

    const renderGoogleButton = () => {
      if (
        cancelled ||
        !window.google?.accounts?.id
      ) {
        return false;
      }

      const target = document.getElementById('daymark-google-button');
      if (!target) return false;

      window.google.accounts.id.initialize({
        client_id: clientId,
        callback: (response) => {
          if (response?.credential && typeof onGoogleLogin === 'function') {
            onGoogleLogin(response.credential);
          }
        },
      });

      target.innerHTML = '';
      window.google.accounts.id.renderButton(target, {
        theme: 'outline',
        size: 'large',
        shape: 'pill',
        width: 320,
        text: 'continue_with',
      });

      setGoogleReady(true);
      return true;
    };

    if (renderGoogleButton()) {
      return () => {
        cancelled = true;
      };
    }

    if (!script) {
      script = document.createElement('script');
      script.src = 'https://accounts.google.com/gsi/client';
      script.async = true;
      script.defer = true;
      document.head.appendChild(script);
    }

    script.addEventListener('load', renderGoogleButton);

    timer = window.setInterval(() => {
      if (renderGoogleButton()) {
        window.clearInterval(timer);
        timer = null;
      }
    }, 250);

    return () => {
      cancelled = true;
      if (timer !== null) window.clearInterval(timer);
      script?.removeEventListener('load', renderGoogleButton);
    };
  }, [mode, onGoogleLogin]);
  const submit = event => {
    event.preventDefault(); setLocalError('');
    if (mode === 'register' && password !== confirmPassword) { setLocalError('Passwords do not match.'); return; }
    if (mode === 'forgot') { onForgot(email.trim()); return; }
    if (mode === 'reset') { if (password !== confirmPassword) { setLocalError('Passwords do not match.'); return; } onReset(resetToken, password); return; }
    onSubmit(mode, mode === 'register' ? { full_name: fullName.trim(), email: email.trim(), password } : { email: email.trim(), password });
  };
  return <main className="auth-screen"><section className="auth-card">
    <div className="auth-brand"><div className="brand-mark"><Command size={21}/></div><div><b>daymark</b><span>PERSONAL WORKSPACE</span></div></div>
    <div className="auth-heading"><div className="eyebrow"><Sparkles size={14}/> YOUR SPACE TO MAKE PROGRESS</div><h1>{mode === 'login' ? 'Welcome back' : mode === 'register' ? 'Create your account' : 'Reset your password'}</h1><p>{mode === 'login' ? 'Sign in to continue your plans.' : mode === 'register' ? 'A clear plan starts with one small step.' : 'We’ll send reset instructions if the account exists.'}</p></div>
    {!['forgot','reset'].includes(mode) && <div className="auth-tabs"><button type="button" className={mode === 'login' ? 'selected' : ''} onClick={() => {setMode('login');setLocalError('');}}>Sign in</button><button type="button" className={mode === 'register' ? 'selected' : ''} onClick={() => {setMode('register');setLocalError('');}}>Create account</button></div>}
    <form className="form-stack" onSubmit={submit}>
      {mode === 'register' && <label>Full name<input autoComplete="name" value={fullName} onChange={e=>setFullName(e.target.value)} required maxLength={120} placeholder="Your name"/></label>}
      <label>Email address<input type="email" autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)} required placeholder="you@example.com"/></label>
      {mode !== 'forgot' && <label>Password<input type="password" autoComplete={mode==='login'?'current-password':'new-password'} value={password} onChange={e=>setPassword(e.target.value)} required minLength={8} placeholder="At least 8 characters"/></label>}
      {['register','reset'].includes(mode) && <label>Confirm password<input type="password" autoComplete="new-password" value={confirmPassword} onChange={e=>setConfirmPassword(e.target.value)} required minLength={8} placeholder="Enter password again"/></label>}
      {(localError || error) && <div className="alert error-alert"><CircleAlert size={17}/><span>{localError || error}</span></div>}
      <button className="btn btn-primary auth-submit" type="submit" disabled={loading}>{loading?'Please wait…':mode==='login'?'Sign in':mode==='register'?'Create account':mode==='reset'?'Update password':'Send reset instructions'} <ArrowRight size={16}/></button>
    </form>
    {mode==='login' && <button className="text-action auth-forgot" type="button" onClick={()=>{setMode('forgot');setLocalError('');}}>Forgot password?</button>}
    {mode==='forgot' && <button className="text-action auth-forgot" type="button" onClick={()=>{setMode('login');setLocalError('');}}>Back to sign in</button>}
    {mode==='login' && <><div className="auth-divider"><span>or continue with</span></div><div id="daymark-google-button" className="google-button"></div>{!import.meta.env.VITE_GOOGLE_CLIENT_ID&&<p className="auth-footnote">Google Sign-In becomes available after setting VITE_GOOGLE_CLIENT_ID.</p>}</>}
    <p className="auth-footnote">Your account and workspace data are managed by your configured Daymark API.</p>
  </section></main>;
}
export default function App(){
  const [authUser, setAuthUser] = useState(() => readStoredUser());
  const [authLoading, setAuthLoading] = useState(false);
  const [authError, setAuthError] = useState('');
  const [page,setPage] = useState('dashboard');
  const [dashboard,setDashboard] = useState(null);
  const [tasks,setTasks] = useState([]);
  const [goals,setGoals] = useState([]);
  const [query,setQuery] = useState('');
  const [filterStatus,setFilterStatus] = useState('');
  const [filterPriority,setFilterPriority] = useState('');
  const [sort,setSort] = useState('due_date');
  const [order,setOrder] = useState('asc');
  const [loading,setLoading] = useState(true);
  const [error,setError] = useState('');
  const [notice,setNotice] = useState('');
  const [taskModal,setTaskModal] = useState(null);
  const [goalModal,setGoalModal] = useState(null);
  const [mobileOpen,setMobileOpen] = useState(false);
  const [milestoneGoal,setMilestoneGoal] = useState(null);
  const [milestones,setMilestones] = useState([]);
  const [milestoneTitle,setMilestoneTitle] = useState('');
  const [milestoneDate,setMilestoneDate] = useState('');
  const [apiOnline,setApiOnline] = useState(null);

  const handleAuth = useCallback(async (mode, data) => {
    setAuthLoading(true);
    setAuthError('');
    try {
      const result = mode === 'register' ? await api.register(data) : await api.login(data);
      const token = result?.access_token || result?.accessToken || result?.token;
      const user = result?.user || result?.data?.user;
      if (!token || !user) throw new Error('The API response must include access_token and user. Check your backend authentication response schema.');
      setAccessToken(token);
      sessionStorage.setItem('daymark_access_token', token);
      sessionStorage.setItem('daymark_user', JSON.stringify(user));
      setAuthUser(user);
      setPage('dashboard');
      setNotice(mode === 'register' ? 'Account created successfully' : 'Welcome back!');
    } catch (e) {
      setAuthError(e instanceof Error ? e.message : 'Authentication failed.');
    } finally {
      setAuthLoading(false);
    }
  }, []);

  const handleGoogle = useCallback(async credential => {
    setAuthLoading(true); setAuthError('');
    try {
      const result = await api.googleLogin(credential);
      const token = result?.access_token; const user = result?.user;
      if (!token || !user) throw new Error('Unexpected Google Sign-In response.');
      setAccessToken(token); sessionStorage.setItem('daymark_access_token', token);
      sessionStorage.setItem('daymark_user', JSON.stringify(user)); setAuthUser(user); setNotice('Signed in with Google');
    } catch (e) { setAuthError(e instanceof Error ? e.message : 'Google Sign-In failed.'); }
    finally { setAuthLoading(false); }
  }, []);

  const handleReset = useCallback(async (token, password) => {
    setAuthLoading(true); setAuthError('');
    try { await api.resetPassword(token, password); window.history.replaceState({}, '', window.location.pathname); setAuthError('Password updated. You can now sign in.'); }
    catch(e) { setAuthError(e.message); }
    finally { setAuthLoading(false); }
  }, []);

  const handleForgot = useCallback(async email => {
    setAuthLoading(true); setAuthError('');
    try { await api.requestPasswordReset(email); setNotice('If the account exists, reset instructions will be sent.'); setAuthError('Password reset requested. Check your email if the account exists.'); }
    catch(e) { setAuthError(e.message); }
    finally { setAuthLoading(false); }
  }, []);

  const handleLogout = () => {
    setAccessToken(null);
    sessionStorage.removeItem('daymark_access_token');
    sessionStorage.removeItem('daymark_user');
    setAuthUser(null);
    setDashboard(null); setTasks([]); setGoals([]); setMilestones([]); setMilestoneGoal(null);
    setTaskModal(null); setGoalModal(null); setError(''); setAuthError(''); setNotice(''); setPage('dashboard');
  };

  useEffect(() => {
    const token = sessionStorage.getItem('daymark_access_token');
    if (token) setAccessToken(token);
  }, []);

  const load = useCallback(async () => {
    if (!authUser) { setLoading(false); return; }
    setLoading(true); setError('');
    try {
      const [dash, allGoals] = await Promise.all([api.dashboard(),api.goals()]);
      setDashboard(dash); setGoals(allGoals);
      const view = ['today','tomorrow','overdue','missing','weekly','monthly','completed'].includes(page) ? page : 'all';
      const [taskRows,health] = await Promise.all([
        api.tasks({view,search:query,status:filterStatus,priority:filterPriority,sort,order}),
        api.health().catch(()=>null)
      ]);
      setTasks(taskRows); setApiOnline(!!health);
    } catch(e) { setError(e.message); setApiOnline(false); }
    finally { setLoading(false); }
  },[authUser,page,query,filterStatus,filterPriority,sort,order]);
  useEffect(()=>{ if (authUser) load(); },[authUser, load]);
  useEffect(()=>{ if(notice){const id=setTimeout(()=>setNotice(''),3200);return()=>clearTimeout(id);} },[notice]);
  const activeTitle = useMemo(()=>({
    dashboard:'Love that what U-R doing',today:'Today',tomorrow:'Tomorrow',all:'All tasks',overdue:'Overdue tasks',
    missing:'Tasks without a due date',weekly:'This week',monthly:'This month',completed:'Completed tasks',
    short:'Short-term plans',long:'Long-term plans',goals:'Goals & milestones'
  }[page] || 'Dashboard'),[page]);
  const isGoalPage = ['short','long','goals'].includes(page);
  const visibleGoals = goals.filter(g=> page==='short' ? g.goal_type==='Short-Term' : page==='long' ? g.goal_type==='Long-Term' : true);
  const setPageAndClose = id => {setPage(id);setMobileOpen(false);setQuery('');setFilterStatus('');setFilterPriority('');};

  async function saveTask(event){
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const payload = {
      title:String(form.get('title')||'').trim(), description:String(form.get('description')||'').trim()||null,
      status:form.get('status'),priority:form.get('priority'),due_date:form.get('due_date')||null,
      goal_id:form.get('goal_id') ? Number(form.get('goal_id')) : null
    };
    try{
      if(taskModal?.id) await api.updateTask(taskModal.id,payload); else await api.createTask(payload);
      setTaskModal(null);setNotice(taskModal?.id?'Task updated successfully':'Task created successfully');await load();
    }catch(e){setError(e.message);}
  }
  async function removeTask(task){
    if(!window.confirm(`Delete “${task.title}”? This cannot be undone.`))return;
    try{await api.deleteTask(task.id);setNotice('Task deleted');await load();}catch(e){setError(e.message);}
  }
  async function quickStatus(task){
    const status=task.status==='Completed'?'Pending':'Completed';
    try{await api.updateTask(task.id,{status});setNotice(status==='Completed'?'Task completed':'Task reopened');await load();}catch(e){setError(e.message);}
  }
  async function saveGoal(event){
    event.preventDefault();const f=new FormData(event.currentTarget);
    const payload={title:String(f.get('title')||'').trim(),description:String(f.get('description')||'').trim()||null,
      goal_type:f.get('goal_type'),priority:f.get('priority'),status:f.get('status'),target_date:f.get('target_date')||null};
    try{if(goalModal?.id)await api.updateGoal(goalModal.id,payload);else await api.createGoal(payload);
      setGoalModal(null);setNotice(goalModal?.id?'Goal updated':'Goal created');await load();
    }catch(e){setError(e.message);}
  }
  async function removeGoal(goal){
    if(!window.confirm(`Delete goal “${goal.title}”? Linked tasks will remain but become unlinked.`))return;
    try{await api.deleteGoal(goal.id);setNotice('Goal deleted');await load();}catch(e){setError(e.message);}
  }
  async function openMilestones(goal){
    try{setMilestones(await api.milestones(goal.id));setMilestoneGoal(goal);setMilestoneTitle('');setMilestoneDate('');}
    catch(e){setError(e.message);}
  }
  async function addMilestone(e){
    e.preventDefault();if(!milestoneTitle.trim())return;
    try{await api.createMilestone(milestoneGoal.id,{title:milestoneTitle.trim(),due_date:milestoneDate||null,completed:false});
      setMilestones(await api.milestones(milestoneGoal.id));setMilestoneTitle('');setMilestoneDate('');setNotice('Milestone added');await load();}
    catch(e){setError(e.message);}
  }
  async function toggleMilestone(m){try{await api.updateMilestone(m.id,{completed:!m.completed});setMilestones(await api.milestones(milestoneGoal.id));await load();}catch(e){setError(e.message);}}
  async function deleteMilestone(m){if(!window.confirm(`Delete milestone “${m.title}”?`))return;try{await api.deleteMilestone(m.id);setMilestones(await api.milestones(milestoneGoal.id));await load();}catch(e){setError(e.message);}}

  if (!authUser) return <AuthScreen onSubmit={handleAuth} onGoogleLogin={handleGoogle} onForgot={handleForgot} onReset={handleReset} error={authError} loading={authLoading}/>;

  const stats=dashboard?.stats||{total:0,pending:0,in_progress:0,completed:0,overdue:0};
  const pageTasks = !isGoalPage && page!=='dashboard';
  return <div className="app-shell">
    <aside className={`sidebar ${mobileOpen?'sidebar-open':''}`}>
      <div className="brand"><div className="brand-mark"><Command size={20}/></div><div><b>daymark</b><span>PERSONAL WORKSPACE</span></div><button className="icon-btn sidebar-close" aria-label="Close menu" onClick={()=>setMobileOpen(false)}><X size={18}/></button></div>
      <button className="workspace-switch" onClick={()=>setNotice('You are using your personal workspace.')}><div className="workspace-avatar">P</div><span><b>Personal workspace</b><small>Free plan</small></span><ChevronDown size={15}/></button>
      <div className="nav-scroll">{navGroups.map(group=><div className="nav-group" key={group.title}><div className="nav-label">{group.title}</div>{group.items.map(item=>{const Icon=item.icon;return <button key={item.id} className={`nav-item ${page===item.id?'active':''}`} onClick={()=>setPageAndClose(item.id)}><Icon size={17}/><span>{item.label}</span>{item.id==='overdue'&&stats.overdue>0&&<em>{stats.overdue}</em>}</button>})}</div>)}</div>
      <div className="sidebar-bottom"><div className="focus-card"><div className="focus-icon"><Sparkles size={16}/></div><b>Make space for focus</b><p>Small steps, meaningful progress. Keep moving forward.</p><div className="focus-track"><i style={{width:`${stats.total?Math.round(stats.completed/stats.total*100):0}%`}}/></div><small>{stats.total?Math.round(stats.completed/stats.total*100):0}% of tasks completed</small></div><button className="nav-item" onClick={()=>setNotice('Settings are not included in this initial release.')}><Settings2 size={17}/>Settings</button><div className="profile"><div className="profile-avatar">{initialsFor(authUser)}</div><div className="profile-copy"><b>{authUser.full_name || authUser.name || authUser.email}</b><small>{authUser.email}</small></div><button className="icon-btn" title="Log out" aria-label="Log out" onClick={handleLogout}><LogOut size={17}/></button></div></div>
    </aside>
    {mobileOpen&&<button className="mobile-scrim" aria-label="Close navigation" onClick={()=>setMobileOpen(false)}/>}
    <main className="main-area">
      <header className="topbar"><div className="topbar-left"><button className="icon-btn mobile-menu" aria-label="Open menu" onClick={()=>setMobileOpen(true)}><Menu size={20}/></button><div className="breadcrumb">Workspace <span>/</span> <b>{activeTitle}</b></div></div><div className="topbar-actions"><div className={`connection ${apiOnline===false?'offline':'online'}`}><span/>{apiOnline===false?'API offline':'Connected'}</div><button className="icon-btn notification" aria-label="Notifications" onClick={()=>setNotice('You’re all caught up.')}><Bell size={18}/><i/></button><button className="avatar-small" title="Log out" aria-label="Log out" onClick={handleLogout}>{initialsFor(authUser)}</button></div></header>
      <div className="content">
        {error&&<div className="alert error-alert"><CircleAlert size={18}/><div><b>Something needs attention</b><p>{error}</p></div><button className="icon-btn" onClick={()=>setError('')} aria-label="Dismiss error"><X size={17}/></button></div>}
        {apiOnline===false&&<div className="api-banner"><CircleAlert size={17}/><span>Backend unavailable. Start FastAPI and PostgreSQL, then retry.</span><button onClick={load}><RefreshCw size={14}/> Retry</button></div>}
        {page==='dashboard'?<Dashboard userName={authUser.full_name || authUser.name || authUser.email} dash={dashboard} tasks={tasks} loading={loading} onNew={()=>setTaskModal({})} onPage={setPageAndClose} onEdit={t=>setTaskModal(t)} onStatus={quickStatus} onDelete={removeTask} onGoal={g=>setPageAndClose(g.goal_type==='Short-Term'?'short':'long')}/>
          :isGoalPage?<GoalsPage goals={visibleGoals} loading={loading} page={page} onNew={()=>setGoalModal({})} onEdit={g=>setGoalModal(g)} onDelete={removeGoal} onMilestones={openMilestones}/>
          :<TasksPage title={activeTitle} page={page} tasks={tasks} goals={goals} loading={loading} query={query} setQuery={setQuery} status={filterStatus} setStatus={setFilterStatus} priority={filterPriority} setPriority={setFilterPriority} sort={sort} setSort={setSort} order={order} setOrder={setOrder} onNew={()=>setTaskModal({})} onEdit={t=>setTaskModal(t)} onStatus={quickStatus} onDelete={removeTask}/>}
      </div>
      <footer className="footer"><span>daymark <span className="footer-dot">•</span> Built for intentional progress</span><span><span className="live-dot"/> {apiOnline===false?'Waiting for API':'All systems operational'}</span></footer>
    </main>
    {taskModal&&<Modal title={taskModal.id?'Edit task':'Create a task'} subtitle="Make your next step clear and achievable." onClose={()=>setTaskModal(null)}><form className="form-stack" onSubmit={saveTask}>
      <label>Task title <input name="title" defaultValue={taskModal.title||''} required minLength="1" maxLength="180" placeholder="e.g. Finish VPC Terraform module" autoFocus/></label>
      <label>Description <textarea name="description" defaultValue={taskModal.description||''} rows="3" placeholder="Add a little context (optional)"/></label>
      <div className="form-grid"><label>Status <select name="status" defaultValue={taskModal.status||'Pending'}><option>Pending</option><option>In Progress</option><option>Completed</option></select></label><label>Priority <select name="priority" defaultValue={taskModal.priority||'Medium'}><option>Low</option><option>Medium</option><option>High</option></select></label></div>
      <div className="form-grid"><label>Due date <input type="date" name="due_date" defaultValue={taskModal.due_date||''}/></label><label>Link to goal <select name="goal_id" defaultValue={taskModal.goal_id||''}><option value="">No goal</option>{goals.map(g=><option key={g.id} value={g.id}>{g.title}</option>)}</select></label></div>
      <div className="modal-actions"><button type="button" className="btn btn-quiet" onClick={()=>setTaskModal(null)}>Cancel</button><button type="submit" className="btn btn-primary"><Check size={16}/>{taskModal.id?'Save changes':'Create task'}</button></div>
    </form></Modal>}
    {goalModal&&<Modal title={goalModal.id?'Edit goal':'Create a goal'} subtitle="Turn a bigger intention into measurable progress." onClose={()=>setGoalModal(null)}><form className="form-stack" onSubmit={saveGoal}>
      <label>Goal title <input name="title" defaultValue={goalModal.title||''} required maxLength="180" placeholder="e.g. Become an AWS Cloud Engineer"/></label>
      <label>Description <textarea name="description" defaultValue={goalModal.description||''} rows="3" placeholder="What does success look like?"/></label>
      <div className="form-grid"><label>Plan type <select name="goal_type" defaultValue={goalModal.goal_type||'Short-Term'}><option>Short-Term</option><option>Long-Term</option></select></label><label>Priority <select name="priority" defaultValue={goalModal.priority||'Medium'}><option>Low</option><option>Medium</option><option>High</option></select></label></div>
      <div className="form-grid"><label>Target date <input type="date" name="target_date" defaultValue={goalModal.target_date||''}/></label><label>Status <select name="status" defaultValue={goalModal.status||'Active'}><option>Active</option><option>Paused</option><option>Completed</option></select></label></div>
      <div className="modal-actions"><button type="button" className="btn btn-quiet" onClick={()=>setGoalModal(null)}>Cancel</button><button type="submit" className="btn btn-primary"><Check size={16}/>{goalModal.id?'Save changes':'Create goal'}</button></div>
    </form></Modal>}
    {milestoneGoal&&<Modal title="Goal milestones" subtitle={milestoneGoal.title} onClose={()=>setMilestoneGoal(null)}><div className="milestone-list">{milestones.map(m=><div className="milestone-row" key={m.id}><button className={`milestone-check ${m.completed?'checked':''}`} aria-label={m.completed?'Mark incomplete':'Mark complete'} onClick={()=>toggleMilestone(m)}>{m.completed&&<Check size={13}/>}</button><div className={m.completed?'milestone-done':''}><b>{m.title}</b><small>{prettyDate(m.due_date)}</small></div><button className="icon-btn danger-icon" aria-label="Delete milestone" onClick={()=>deleteMilestone(m)}><Trash2 size={15}/></button></div>)}{!milestones.length&&<div className="empty-inline">No milestones yet. Add the first step below.</div>}</div><form className="milestone-add" onSubmit={addMilestone}><label>Milestone title<input value={milestoneTitle} onChange={e=>setMilestoneTitle(e.target.value)} required placeholder="e.g. Complete first project"/></label><label>Due date<input type="date" value={milestoneDate} onChange={e=>setMilestoneDate(e.target.value)}/></label><button className="btn btn-primary" type="submit"><Plus size={16}/> Add milestone</button></form></Modal>}
    {notice&&<div className="toast"><span className="toast-icon"><Check size={15}/></span>{notice}<button className="icon-btn" onClick={()=>setNotice('')} aria-label="Dismiss"><X size={15}/></button></div>}
  </div>;
}

function Dashboard({userName,dash,tasks,loading,onNew,onPage,onEdit,onStatus,onDelete}) {
  const currentHour = Number(new Intl.DateTimeFormat("en-IN",{timeZone:"Asia/Kolkata",hour:"2-digit",hourCycle:"h23"}).format(new Date()));
  const greeting = currentHour >= 5 && currentHour < 12 ? "Good morning" : currentHour >= 12 && currentHour < 17 ? "Good afternoon" : currentHour >= 17 && currentHour < 21 ? "Good evening" : "Good night";
  const stats = dash?.stats || {total:0,pending:0,in_progress:0,completed:0,overdue:0};
  const completion = stats.total ? Math.round((stats.completed / stats.total) * 100) : 0;
  const cards = [
    {label:"Total tasks",value:stats.total,icon:ListTodo,tone:"violet",note:"Across your workspace"},
    {label:"In progress",value:stats.in_progress,icon:Activity,tone:"blue",note:"Work in motion"},
    {label:"Completed",value:stats.completed,icon:CheckCheck,tone:"green",note:`${completion}% completion rate`},
    {label:"Overdue",value:stats.overdue,icon:Clock3,tone:"orange",note:stats.overdue ? "Needs your attention" : "You’re on track"},
  ];

  return (
    <>
      <div className="welcome-row">
        <div>
          <div className="eyebrow"><Sparkles size={14}/> YOUR SPACE TO MAKE PROGRESS</div>
          <h1>{greeting}, {(userName || 'there').trim().split(/\s+/)[0]} <span className="wave">✳</span></h1>
          <p className="subhead">A clear mind starts with a clear plan. Here’s your day at a glance.</p>
        </div>
        <button className="btn btn-primary new-task-btn" onClick={onNew}><Plus size={17}/> New task</button>
      </div>

      <div className="date-strip">
        <div className="date-icon"><CalendarDays size={17}/></div>
        <div><b>{new Date().toLocaleDateString("en-US",{weekday:"long",month:"long",day:"numeric"})}</b><span>One step at a time. You’ve got this.</span></div>
        <div className="date-strip-right"><span className="live-dot"/> Live workspace</div>
      </div>

      <div className="section-heading">
        <div><h2>Your overview</h2><p>Here’s where things stand right now.</p></div>
        <button className="text-action" onClick={()=>onPage("all")}>View all tasks <ArrowRight size={15}/></button>
      </div>

      <div className="stat-grid">
        {cards.map(c=>{const Icon=c.icon;return (
          <div className="stat-card" key={c.label}>
            <div className={`stat-icon ${c.tone}`}><Icon size={19}/></div>
            <span className="stat-label">{c.label}</span>
            <div className="stat-bottom"><strong>{loading?"—":c.value}</strong><span className={`stat-note ${c.tone==="orange"&&stats.overdue?"warn":""}`}>{c.note}</span></div>
            {c.label==="Completed"&&<div className="mini-track"><i style={{width:`${completion}%`}}/></div>}
          </div>
        );})}
      </div>

      <div className="dashboard-grid">
        <section className="panel tasks-panel">
          <div className="panel-head"><div><h2>Today’s focus</h2><p>Keep your attention on what matters.</p></div><button className="round-action" aria-label="View today's tasks" onClick={()=>onPage("today")}><ArrowRight size={17}/></button></div>
          {loading?<SkeletonRows/>:dash?.today_tasks?.length?<div className="focus-list">{dash.today_tasks.map(t=><TaskRow key={t.id} task={t} onEdit={onEdit} onStatus={onStatus} onDelete={onDelete}/>)}</div>:<EmptyState icon={CheckCheck} title="A little breathing room" text="No tasks due today. Add one or enjoy the space." action="Create a task" onAction={onNew}/>}
          <button className="panel-footer-link" onClick={()=>onPage("today")}>See today’s plan <ArrowRight size={14}/></button>
        </section>

        <section className="panel progress-panel">
          <div className="panel-head"><div><h2>Your progress</h2><p>Consistency beats intensity.</p></div><div className="progress-head-icon"><TrendingUp size={17}/></div></div>
          <div className="progress-ring-wrap"><div className="progress-ring" style={{"--progress":`${completion*3.6}deg`}}><div><strong>{completion}%</strong><span>complete</span></div></div></div>
          <div className="progress-legend">
            <div><span className="legend-dot done-dot"/><span>Completed</span><b>{stats.completed}</b></div>
            <div><span className="legend-dot pending-dot"/><span>Still to do</span><b>{stats.total-stats.completed}</b></div>
          </div>
          <div className="progress-encouragement"><Sparkles size={15}/><span>{completion===100&&stats.total?"Everything complete — amazing work!":completion>=60?"You’re building real momentum.":"Every completed task is progress. Keep going."}</span></div>
        </section>
      </div>

      <div className="lower-grid">
        <section className="panel">
          <div className="panel-head"><div><h2>Coming up</h2><p>Your next deadlines, in order.</p></div><button className="text-action compact" onClick={()=>onPage("weekly")}>This week <ArrowRight size={14}/></button></div>
          {loading?<SkeletonRows count={3}/>:dash?.upcoming_tasks?.length?<div className="upcoming-list">{dash.upcoming_tasks.slice(0,4).map(t=><div className="upcoming-row" key={t.id}><div className="upcoming-date"><b>{new Date(`${t.due_date}T12:00:00`).getDate()}</b><small>{new Date(`${t.due_date}T12:00:00`).toLocaleDateString("en-US",{month:"short"})}</small></div><div className="upcoming-main"><b>{t.title}</b><small>{t.status}</small></div><span className={priorityClass(t.priority)}>{t.priority}</span><button className="icon-btn" onClick={()=>onEdit(t)} aria-label="Edit task"><Pencil size={14}/></button></div>)}</div>:<EmptyState icon={CalendarClock} title="Nothing on the horizon" text="Upcoming tasks will appear here." action="Add a task" onAction={onNew}/>}
        </section>

        <section className="panel goals-panel">
          <div className="panel-head"><div><h2>Goals in motion</h2><p>Small steps add up to big things.</p></div><button className="text-action compact" onClick={()=>onPage("goals")}>All goals <ArrowRight size={14}/></button></div>
          {loading?<SkeletonRows count={3}/>:dash?.short_term_goals?.length||dash?.long_term_goals?.length?[...(dash?.short_term_goals||[]),...(dash?.long_term_goals||[])].slice(0,3).map(g=><div className="goal-progress-row" key={g.id}><div className="goal-bullet"><Target size={15}/></div><div className="goal-progress-content"><div><b>{g.title}</b><span>{g.progress}%</span></div><div className="goal-track"><i style={{width:`${g.progress}%`}}/></div><small>{g.completed_task_count} of {g.task_count} tasks complete</small></div></div>):<EmptyState icon={Target} title="What are you working toward?" text="Create a goal to connect daily actions to the bigger picture." action="Create a goal" onAction={()=>onPage("goals")}/>}
        </section>
      </div>
    </>
  );
}

function TasksPage({title,page,tasks,goals,loading,query,setQuery,status,setStatus,priority,setPriority,sort,setSort,order,setOrder,onNew,onEdit,onStatus,onDelete}){
  return <><div className="page-heading"><div><div className="eyebrow">TASK PLANNER</div><h1>{title}</h1><p className="subhead">{page==='today'?'Make today count, one task at a time.':page==='tomorrow'?'Set yourself up for a smoother tomorrow.':page==='overdue'?'A fresh look at tasks that need attention.':page==='missing'?'Give these tasks a deadline when you can.':page==='weekly'?'Your next seven days, at a glance.':page==='monthly'?'Upcoming tasks through the end of this month.':page==='completed'?'Take a moment to appreciate what you’ve finished.':'Everything you’re working on, all in one place.'}</p></div><button className="btn btn-primary" onClick={onNew}><Plus size={17}/> New task</button></div>
    <div className="task-toolbar"><div className="search-box"><Search size={17}/><input aria-label="Search tasks" placeholder="Search tasks..." value={query} onChange={e=>setQuery(e.target.value)}/>{query&&<button onClick={()=>setQuery('')} aria-label="Clear search"><X size={14}/></button>}<kbd>⌘ K</kbd></div><div className="filter-controls"><select aria-label="Filter by status" value={status} onChange={e=>setStatus(e.target.value)}><option value="">All statuses</option><option>Pending</option><option>In Progress</option><option>Completed</option></select><select aria-label="Filter by priority" value={priority} onChange={e=>setPriority(e.target.value)}><option value="">All priorities</option><option>High</option><option>Medium</option><option>Low</option></select><select aria-label="Sort tasks" value={sort} onChange={e=>setSort(e.target.value)}><option value="due_date">Due date</option><option value="created_at">Created date</option><option value="title">Title</option><option value="priority">Priority</option></select><button className="icon-btn sort-toggle" title={`Sort ${order}`} onClick={()=>setOrder(order==='asc'?'desc':'asc')}><ArrowDownUp size={16}/></button></div></div>
    <div className="list-meta"><span><b>{loading?'…':tasks.length}</b> {tasks.length===1?'task':'tasks'} {query?`matching “${query}”`:''}</span><span className="list-meta-right"><span className="live-dot"/> Synced with database</span></div>
    <section className="panel task-table-panel">{loading?<SkeletonRows count={5}/>:tasks.length?<div className="task-list">{tasks.map(t=><TaskRow key={t.id} task={t} onEdit={onEdit} onStatus={onStatus} onDelete={onDelete}/>)}</div>:<EmptyState icon={page==='completed'?CheckCheck:FolderKanban} title={query?'No matching tasks':`No ${title.toLowerCase()} yet`} text={query?'Try another search term or clear the filters.':'This space is ready for your next step.'} action={query?'Clear search':'Create a task'} onAction={query?()=>setQuery(''):onNew}/>}</section>
    <div className="task-tip"><Sparkles size={15}/><span><b>Pro tip:</b> Link tasks to a goal to see how daily progress contributes to your bigger plans.</span></div>
  </>;
}

function TaskRow({task,onEdit,onStatus,onDelete}){
  return <div className={`task-row ${task.status==='Completed'?'task-row-completed':''}`}><button className={`task-check ${task.status==='Completed'?'checked':''}`} onClick={()=>onStatus(task)} aria-label={task.status==='Completed'?'Reopen task':'Mark task complete'}>{task.status==='Completed'&&<Check size={13}/>}</button><div className="task-title-cell"><button className="task-title-button" onClick={()=>onEdit(task)}>{task.title}</button>{task.description&&<small>{task.description}</small>}<div className="task-mobile-meta"><span className={statusClass(task.status)}>{task.status}</span><span className={priorityClass(task.priority)}>{task.priority}</span></div></div><span className={statusClass(task.status)}>{task.status}</span><span className={priorityClass(task.priority)}>{task.priority}</span><span className={`task-due ${task.due_date&&task.due_date<todayString()&&task.status!=='Completed'?'due-late':''}`}><Calendar size={14}/>{prettyDate(task.due_date)}</span><div className="task-row-actions"><button className="icon-btn" aria-label="Edit task" onClick={()=>onEdit(task)}><Pencil size={15}/></button><button className="icon-btn danger-icon" aria-label="Delete task" onClick={()=>onDelete(task)}><Trash2 size={15}/></button></div></div>;
}

function GoalsPage({goals,loading,page,onNew,onEdit,onDelete,onMilestones}){
  const short=goals.filter(g=>g.goal_type==='Short-Term').length,long=goals.filter(g=>g.goal_type==='Long-Term').length;
  return <><div className="page-heading"><div><div className="eyebrow">PERSONAL GROWTH</div><h1>{page==='short'?'Short-term plans':page==='long'?'Long-term plans':'Goals & milestones'}</h1><p className="subhead">Connect the small things you do each day to the life you’re building.</p></div><button className="btn btn-primary" onClick={onNew}><Plus size={17}/> New goal</button></div>
    <div className="goal-summary-strip"><div><div className="goal-summary-icon"><Target size={18}/></div><div><b>{loading?'—':goals.length}</b><small>Active goals shown</small></div></div><div><div className="goal-summary-icon purple"><Zap size={18}/></div><div><b>{short}</b><small>Short-term</small></div></div><div><div className="goal-summary-icon blue"><TrendingUp size={18}/></div><div><b>{long}</b><small>Long-term</small></div></div></div>
    {loading?<section className="panel"><SkeletonRows count={4}/></section>:goals.length?<div className="goal-card-grid">{goals.map(g=><article className="goal-card" key={g.id}><div className="goal-card-top"><div className={`goal-card-icon ${g.goal_type==='Long-Term'?'long-goal':''}`}><Target size={19}/></div><span className={priorityClass(g.priority)}>{g.priority} priority</span><div className="goal-menu"><button className="icon-btn" aria-label="Edit goal" onClick={()=>onEdit(g)}><Pencil size={14}/></button><button className="icon-btn danger-icon" aria-label="Delete goal" onClick={()=>onDelete(g)}><Trash2 size={14}/></button></div></div><span className="goal-type">{g.goal_type.toUpperCase()} PLAN</span><h3>{g.title}</h3><p className="goal-description">{g.description||'A goal without a description yet. Add a few details to make it actionable.'}</p><div className="goal-card-meta"><span><Calendar size={14}/>{g.target_date?`Target ${prettyDate(g.target_date,{month:'short',day:'numeric',year:'numeric'})}`:'No target date'}</span><span className={statusClass(g.status)}>{g.status}</span></div><div className="goal-progress-label"><span>Progress</span><b>{g.progress}%</b></div><div className="goal-track large"><i style={{width:`${g.progress}%`}}/></div><div className="goal-card-footer"><span>{g.task_count?`${g.completed_task_count} of ${g.task_count} tasks`:g.milestone_count?`${g.completed_milestone_count} of ${g.milestone_count} milestones`:'No linked tasks yet'}</span><button className="text-action compact" onClick={()=>onMilestones(g)}>Milestones <ArrowRight size={14}/></button></div></article>)}</div>:<section className="panel"><EmptyState icon={Target} title="Give your ambition a home" text="Create a short-term or long-term goal, then connect tasks and milestones to track progress." action="Create your first goal" onAction={onNew}/></section>}
  </>;
}

function Modal({title,subtitle,onClose,children}){useEffect(()=>{const fn=e=>{if(e.key==='Escape')onClose()};window.addEventListener('keydown',fn);return()=>window.removeEventListener('keydown',fn)},[onClose]);return <div className="modal-backdrop" onMouseDown={e=>{if(e.target===e.currentTarget)onClose()}}><section className="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title"><div className="modal-head"><div><h2 id="modal-title">{title}</h2><p>{subtitle}</p></div><button className="icon-btn" aria-label="Close dialog" onClick={onClose}><X size={19}/></button></div>{children}</section></div>}
function EmptyState({icon:Icon,title,text,action,onAction}){return <div className="empty-state"><div className="empty-icon"><Icon size={22}/></div><h3>{title}</h3><p>{text}</p>{action&&<button className="btn btn-secondary" onClick={onAction}><Plus size={15}/>{action}</button>}</div>}
function SkeletonRows({count=4}){return <div className="skeleton-list">{Array.from({length:count},(_,i)=><div className="skeleton-row" key={i}><i/><span/><span/><b/></div>)}</div>}
