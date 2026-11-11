import React, { StrictMode, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import {
  Activity, AlertCircle, Bell, Building2, Check, ChevronDown, ChevronLeft,
  ChevronRight, ClipboardList, LayoutDashboard, LogOut, MapPin, Menu,
  MessageSquare, Search, ShieldCheck, Users, X,
} from 'lucide-react';
import { api, apiBinary, clearSession, dataOf, readSession, saveSession } from './api';
import './styles.css';

const sections = [
  ['dashboard', 'Overview', LayoutDashboard], ['complaints', 'Complaints', ClipboardList],
  ['students', 'Students', Users], ['staff', 'Staff', Users], ['departments', 'Departments', Building2],
  ['locations', 'Locations', MapPin], ['feedback', 'Feedback', MessageSquare],
  ['notifications', 'Notifications', Bell], ['profile', 'Admin profile', ShieldCheck],
];
const statuses = ['SUBMITTED', 'UNDER_REVIEW', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED'];
const priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
const formatDate = (value) => value && !Number.isNaN(new Date(value).getTime()) ? new Date(value).toLocaleString() : '—';
const value = (object, ...keys) => keys.map((key) => object?.[key]).find((item) => item !== undefined && item !== null && item !== '') ?? '—';

function App() {
  const [session, setSession] = useState(readSession);
  const [admin, setAdmin] = useState(null);
  const [page, setPage] = useState('dashboard');
  const [complaintStatus, setComplaintStatus] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);
  const [toast, setToast] = useState('');
  const [authChecking, setAuthChecking] = useState(Boolean(readSession()?.token));
  const toastTimer = useRef(null);

  const signOut = useCallback(() => {
    clearSession(); setSession(null); setAdmin(null); setPage('dashboard');
  }, []);
  const revokeAndSignOut = useCallback(async () => {
    const token = session?.token;
    if (token) { try { await api('/auth/logout', { method: 'POST', token }); } catch { /* always clear the local session */ } }
    signOut();
  }, [session?.token, signOut]);
  useEffect(() => {
    window.history.replaceState({
      ...window.history.state,
      campusfixPage: 'dashboard',
      campusfixComplaintStatus: '',
    }, '', window.location.href);

    const restorePage = (event) => {
      const nextPage = sections.some(([key]) => key === event.state?.campusfixPage)
        ? event.state.campusfixPage
        : 'dashboard';
      setPage(nextPage);
      setComplaintStatus(event.state?.campusfixComplaintStatus || '');
      setMenuOpen(false);
    };

    window.addEventListener('popstate', restorePage);
    return () => window.removeEventListener('popstate', restorePage);
  }, []);
  useEffect(() => {
    const handler = () => signOut();
    window.addEventListener('campusfix:unauthorized', handler);
    return () => window.removeEventListener('campusfix:unauthorized', handler);
  }, [signOut]);
  useEffect(() => () => window.clearTimeout(toastTimer.current), []);

  useEffect(() => {
    if (!session?.token) { setAuthChecking(false); return undefined; }
    let alive = true;
    api('/auth/me', { token: session.token })
      .then((result) => {
        if (!alive) return;
        const user = result.data || {};
        if (user.role !== 'ADMIN') throw new Error('This account is not authorized for the admin dashboard.');
        setAdmin(user); setAuthChecking(false);
      })
      .catch((error) => { if (alive) { signOut(); setToast(error.message); setAuthChecking(false); } });
    return () => { alive = false; };
  }, [session?.token, signOut]);

  const notify = useCallback((message) => {
    window.clearTimeout(toastTimer.current);
    setToast(message); toastTimer.current = window.setTimeout(() => setToast(''), 3500);
  }, []);
  const navigate = useCallback((nextPage, status = '') => {
    const currentState = window.history.state || {};
    if (currentState.campusfixPage !== nextPage || currentState.campusfixComplaintStatus !== status) {
      window.history.pushState({
        ...currentState,
        campusfixPage: nextPage,
        campusfixComplaintStatus: status,
      }, '', window.location.href);
    }
    setPage(nextPage);
    setComplaintStatus(status);
    setMenuOpen(false);
  }, []);

  if (!session?.token) return <Login onLogin={(token, user) => { saveSession(token); setAuthChecking(true); setSession({ token }); setAdmin(user); }} />;
  if (authChecking || !admin) return <div className="auth-wait"><span className="spinner" /> Verifying administrator session…</div>;

  const ActiveIcon = sections.find(([key]) => key === page)?.[2] || LayoutDashboard;
  return <div className="shell">
    <aside className={`sidebar ${menuOpen ? 'open' : ''}`}>
      <div className="brand"><div className="brand-mark">CF</div><div><strong>CampusFix</strong><small>ADMIN CONSOLE</small></div><button className="icon-button mobile-close" onClick={() => setMenuOpen(false)} aria-label="Close navigation"><X size={18} /></button></div>
      <div className="nav-label">WORKSPACE</div>
      <nav>{sections.map(([key, label, Icon]) => <button key={key} className={`nav-item ${page === key ? 'selected' : ''}`} onClick={() => navigate(key)}><Icon size={18} /><span>{label}</span>{key === 'notifications' && <span className="nav-dot" />}</button>)}</nav>
      <div className="sidebar-bottom"><div className="secure-note"><ShieldCheck size={17} /><span>Administrator session<br /><b>Role verified by API</b></span></div><button className="nav-item logout" onClick={revokeAndSignOut}><LogOut size={18} /><span>Sign out</span></button></div>
    </aside>
    {menuOpen && <button className="scrim" onClick={() => setMenuOpen(false)} aria-label="Close menu" />}
    <main className="main-area">
      <header className="topbar"><button className="icon-button menu-toggle" onClick={() => setMenuOpen(true)} aria-label="Open navigation"><Menu size={20} /></button><div className="crumb">Admin <ChevronRight size={14} /> <span><ActiveIcon size={15} /> {sections.find(([key]) => key === page)?.[1]}</span></div><div className="top-user"><div className="avatar">{String(value(admin, 'email')).slice(0, 1).toUpperCase()}</div><div><b>{value(admin, 'full_name', 'email')}</b><small>Administrator</small></div><ChevronDown size={15} /></div></header>
      <section className="content"><Page page={page} token={session.token} admin={admin} notify={notify} onNavigate={navigate} complaintStatus={complaintStatus} /></section>
    </main>
    {toast && <div className="toast" role="status"><AlertCircle size={17} />{toast}</div>}
  </div>;
}

function Login({ onLogin }) {
  const [email, setEmail] = useState(''); const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false); const [error, setError] = useState('');
  async function submit(event) {
    event.preventDefault(); setError('');
    if (!email.trim() || !/^\S+@\S+\.\S+$/.test(email.trim()) || !password) { setError('Enter a valid email address and password.'); return; }
    setBusy(true);
    try {
      const result = await api('/auth/login', { method: 'POST', body: { email: email.trim(), password } });
      const auth = result.data || {};
      if (!auth.access_token || auth.user?.role !== 'ADMIN') throw new Error('This account does not have ADMIN access.');
      onLogin(auth.access_token, auth.user);
    } catch (exception) { setError(exception.message); }
    finally { setBusy(false); }
  }
  return <div className="login-page"><div className="login-panel"><div className="brand login-brand"><div className="brand-mark">CF</div><div><strong>CampusFix</strong><small>ADMIN CONSOLE</small></div></div><div className="login-emblem"><ShieldCheck size={25} /></div><p className="eyebrow">CAMPUS OPERATIONS</p><h1>Welcome back</h1><p className="muted">Sign in with an authorized administrator account.</p><form onSubmit={submit} className="form-stack"><label>Email address<input type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} required /></label><label>Password<input type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required /></label>{error && <div className="error-banner" role="alert"><AlertCircle size={17} />{error}</div>}<button className="primary-button full-width" disabled={busy}>{busy ? <><span className="spinner small" /> Signing in…</> : 'Sign in securely'}</button></form><small className="login-foot">Access is checked against the CampusFix API.</small></div><div className="login-decoration"><span className="orb orb-one" /><span className="orb orb-two" /><div className="decor-copy"><span>REPORT. RESOLVE. IMPROVE.</span><h2>A better campus<br />starts with listening.</h2><p>One place to coordinate the work that keeps campus moving.</p></div></div></div>;
}

function Page({ page, token, admin, notify, onNavigate, complaintStatus }) {
  switch (page) {
    case 'dashboard': return <Dashboard token={token} onNavigate={onNavigate} />;
    case 'complaints': return <Complaints token={token} notify={notify} initialStatus={complaintStatus} />;
    case 'students': return <Students token={token} notify={notify} />;
    case 'staff': return <Staff token={token} notify={notify} />;
    case 'departments': return <Catalog token={token} kind="departments" notify={notify} />;
    case 'locations': return <Catalog token={token} kind="locations" notify={notify} />;
    case 'feedback': return <Feedback token={token} />;
    case 'notifications': return <Notifications token={token} notify={notify} />;
    case 'profile': return <Profile token={token} admin={admin} notify={notify} />;
    default: return <Dashboard token={token} />;
  }
}

function useLoad(loader, deps = []) {
  const [state, setState] = useState({ loading: true, data: null, error: '' });
  const [reload, setReload] = useState(0);
  useEffect(() => {
    const controller = new AbortController(); let alive = true;
    setState((current) => ({ ...current, loading: true, error: '' }));
    loader(controller.signal).then((data) => { if (alive) setState({ loading: false, data, error: '' }); })
      .catch((error) => { if (alive && error.name !== 'AbortError') setState({ loading: false, data: null, error: error.message }); });
    return () => { alive = false; controller.abort(); };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, reload]);
  return { ...state, refresh: () => setReload((n) => n + 1) };
}

function Heading({ eyebrow = 'CAMPUSFIX ADMIN', title, description, action }) {
  return <div className="page-heading"><div><p className="eyebrow">{eyebrow}</p><h1>{title}</h1>{description && <p className="muted">{description}</p>}</div>{action}</div>;
}
function Card({ children, className = '' }) { return <div className={`card ${className}`}>{children}</div>; }
function Loading() { return <div className="state-box"><span className="spinner" />Loading data…</div>; }
function ErrorState({ message, retry }) { return <div className="state-box error-state"><AlertCircle size={20} /><span>{message}</span>{retry && <button className="text-button" onClick={retry}>Retry</button>}</div>; }
function Empty({ children = 'No records found.' }) { return <div className="empty-state"><div className="empty-icon"><ClipboardList size={20} /></div><strong>{children}</strong></div>; }
function Pill({ children }) { return <span className={`pill ${String(children).toLowerCase().replaceAll('_', '-')}`}>{String(children || '—').replaceAll('_', ' ')}</span>; }
function Table({ columns, rows, renderRow }) { return <div className="table-wrap"><table><thead><tr>{columns.map((column) => <th key={column}>{column}</th>)}</tr></thead><tbody>{rows.map(renderRow)}</tbody></table></div>; }

function Dashboard({ token, onNavigate }) {
  const stats = useLoad(() => api('/admin/dashboard/stats', { token }).then(dataOf));
  const feedback = useLoad(() => api('/admin/feedback/stats', { token }).then(dataOf));
  return <><Heading title="Campus overview" description="A live view of reports and campus operations." />{stats.loading ? <Loading /> : stats.error ? <ErrorState message={stats.error} retry={stats.refresh} /> : <>
    <div className="stat-grid">{[
      ['Total complaints', value(stats.data?.complaints, 'total_complaints'), ClipboardList, 'blue', 'complaints', ''],
      ['Awaiting review', value(stats.data?.complaints, 'submitted'), Activity, 'amber', 'complaints', 'SUBMITTED'],
      ['Assigned', value(stats.data?.complaints, 'assigned'), Users, 'violet', 'complaints', 'ASSIGNED'],
      ['In progress', value(stats.data?.complaints, 'in_progress'), Activity, 'cyan', 'complaints', 'IN_PROGRESS'],
      ['Resolved', value(stats.data?.complaints, 'resolved'), Check, 'green', 'complaints', 'RESOLVED'],
      ['Students', value(stats.data?.users, 'students'), Users, 'blue', 'students', ''],
      ['Staff', value(stats.data?.users, 'staff'), Users, 'violet', 'staff', ''],
      ['Under review', value(stats.data?.complaints, 'under_review'), Search, 'amber', 'complaints', 'UNDER_REVIEW'],
    ].map(([label, count, Icon, color, target, status]) => <button type="button" className="card stat-card stat-card-button" key={label} onClick={() => onNavigate(target, status)} aria-label={`${label}: ${count}. Open ${target === 'complaints' ? 'complaints' : target}.`}><div className={`stat-icon ${color}`}><Icon size={18} /></div><span>{label}</span><strong>{count}</strong><small>Current totals</small></button>)}</div>
    <div className="overview-grid"><Card><div className="card-heading"><div><h2>Complaint status</h2><p>Distribution from the backend totals</p></div><span className="live-badge">LIVE DATA</span></div><div className="status-list">{statuses.map((status) => <div className="status-row" key={status}><span className="status-bullet" /><span>{status.replaceAll('_', ' ')}</span><b>{value(stats.data?.complaints, status.toLowerCase())}</b></div>)}</div></Card>
      <Card><div className="card-heading"><div><h2>Feedback snapshot</h2><p>Ratings submitted by students</p></div><MessageSquare size={18} className="subtle-icon" /></div>{feedback.loading ? <Loading /> : feedback.error ? <ErrorState message={feedback.error} retry={feedback.refresh} /> : <><div className="rating-large">{value(feedback.data, 'average_rating', 'average')}<span>/ 5</span></div><p className="muted">Average rating</p><div className="rating-meta"><div><strong>{value(feedback.data, 'total_feedback', 'total')}</strong><small>Total responses</small></div><div><strong>{value(feedback.data, 'five_star', 'five_star_count')}</strong><small>5-star ratings</small></div></div></>}</Card></div>
    <div className="notice-line"><AlertCircle size={16} />Recent complaints, department breakdowns, and activity feeds are not exposed by the current backend API.</div>
  </>}</>;
}

function Complaints({ token, notify, initialStatus = '' }) {
  const [filters, setFilters] = useState(() => ({ search: '', status: initialStatus, priority: '', category: '', page: 1 }));
  const [detail, setDetail] = useState(null); const [staff, setStaff] = useState([]); const [staffId, setStaffId] = useState(''); const [busy, setBusy] = useState(false);
  const [nextStatus, setNextStatus] = useState(''); const [nextPriority, setNextPriority] = useState(''); const [remarks, setRemarks] = useState('');
  const [searchText, setSearchText] = useState('');
  useEffect(() => { const id = window.setTimeout(() => setFilters((f) => ({ ...f, search: searchText, page: 1 })), 300); return () => clearTimeout(id); }, [searchText]);
  const query = useMemo(() => ({ ...filters, per_page: 10 }), [filters]);
  const load = useLoad(() => api('/admin/complaints', { token, query }).then((r) => ({ rows: dataOf(r), pagination: r.pagination || {} })), [token, JSON.stringify(query)]);
  async function openComplaint(id) {
    setDetail({ loading: true }); setStaffId('');
    try { const result = await api('/admin/complaints/show', { token, query: { id } }); const payload = dataOf(result); const complaint = payload?.complaint || payload; setDetail({ data: complaint, history: payload?.status_history || [], priorityHistory: payload?.priority_history || [], images: payload?.images || [] }); setNextStatus(''); setNextPriority(complaint?.priority || ''); setRemarks(''); }
    catch (error) { setDetail({ error: error.message }); }
    try { const result = await api('/admin/staff', { token, query: { page: 1, per_page: 100, is_active: 1 } }); setStaff(dataOf(result)); } catch { setStaff([]); }
  }
  async function assign() {
    if (!staffId || !detail?.data) return;
    if (!window.confirm('Assign this complaint to the selected staff member?')) return;
    setBusy(true);
    try { const id = detail.data.complaint_id; await api('/admin/complaints/assign', { method: 'POST', token, body: { complaint_id: Number(id), staff_id: Number(staffId) } }); notify('Complaint assigned successfully.'); setDetail(null); load.refresh(); }
    catch (error) { notify(error.message); }
    finally { setBusy(false); }
  }
  async function updateAdminStatus() {
    if (!detail?.data || !nextStatus) return;
    if (nextStatus === 'REJECTED' && !remarks.trim()) { notify('Add a reason before rejecting.'); return; }
    if (!window.confirm(`Change complaint status to ${nextStatus.replaceAll('_', ' ')}?`)) return;
    setBusy(true);
    try { await api('/admin/complaints/status', { method: 'PATCH', token, body: { complaint_id: Number(detail.data.complaint_id), status: nextStatus, remarks: remarks.trim() } }); notify('Complaint status updated.'); setDetail(null); load.refresh(); }
    catch (error) { notify(error.message); } finally { setBusy(false); }
  }
  async function updateAdminPriority() {
    if (!detail?.data || nextPriority === detail.data.priority) return;
    setBusy(true);
    try { await api('/admin/complaints/priority', { method: 'PATCH', token, body: { complaint_id: Number(detail.data.complaint_id), priority: nextPriority } }); notify('Complaint priority updated.'); setDetail(null); load.refresh(); }
    catch (error) { notify(error.message); } finally { setBusy(false); }
  }
  const pagination = load.data?.pagination || {};
  return <><Heading title="Complaints" description="Review reports, filter the queue, and assign work to staff." /><Card className="data-card"><div className="filters"><div className="search-field"><Search size={17} /><input aria-label="Search complaints" placeholder="Search title or description…" value={searchText} onChange={(e) => setSearchText(e.target.value)} /></div><select aria-label="Filter by status" value={filters.status} onChange={(e) => setFilters({ ...filters, status: e.target.value, page: 1 })}><option value="">All statuses</option>{statuses.map((s) => <option key={s}>{s}</option>)}</select><select aria-label="Filter by priority" value={filters.priority} onChange={(e) => setFilters({ ...filters, priority: e.target.value, page: 1 })}><option value="">All priorities</option>{priorities.map((p) => <option key={p}>{p}</option>)}</select><input aria-label="Filter by category" placeholder="Category" value={filters.category} onChange={(e) => setFilters({ ...filters, category: e.target.value, page: 1 })} /></div>
    {load.loading ? <Loading /> : load.error ? <ErrorState message={load.error} retry={load.refresh} /> : !load.data?.rows?.length ? <Empty>No complaints match these filters.</Empty> : <><Table columns={['Complaint', 'Category', 'Status', 'Priority', 'Submitted', '']} rows={load.data.rows} renderRow={(row) => <tr key={row.complaint_id}><td><b>{value(row, 'title')}</b><small className="cell-sub">#{value(row, 'complaint_id')} · {value(row, 'student_name', 'full_name')}</small></td><td>{value(row, 'category')}</td><td><Pill>{value(row, 'status')}</Pill></td><td><Pill>{value(row, 'priority')}</Pill></td><td>{formatDate(value(row, 'created_at'))}</td><td><button className="text-button" onClick={() => openComplaint(row.complaint_id)}>View details</button></td></tr>} /><Pager page={Number(pagination.current_page || filters.page)} pages={Number(pagination.last_page || pagination.total_pages || 1)} onPage={(page) => setFilters({ ...filters, page })} /></>}</Card>
    {detail && <Modal title="Complaint details" close={() => setDetail(null)}>{detail.loading ? <Loading /> : detail.error ? <ErrorState message={detail.error} /> : <><div className="detail-grid">{Object.entries({ Complaint: value(detail.data, 'complaint_number'), Title: value(detail.data, 'title'), Description: value(detail.data, 'description'), Category: value(detail.data, 'category'), Status: value(detail.data, 'status'), Priority: value(detail.data, 'priority'), Student: value(detail.data, 'student_name'), Email: value(detail.data, 'student_email'), Location: [detail.data.building_name, detail.data.block_name, detail.data.floor_number, detail.data.room_number].filter(Boolean).join(' · ') || '—', Department: value(detail.data, 'department_name'), Submitted: formatDate(detail.data.created_at), Resolution: value(detail.data, 'resolution_notes') }).map(([k, v]) => <div key={k}><small>{k}</small><p>{String(v)}</p></div>)}</div>{detail.images?.length > 0 && <div className="image-gallery">{detail.images.map((image) => <ProtectedImage key={image.image_id} imageId={image.image_id} token={token} />)}</div>}{detail.history?.length > 0 && <><h3>Status history</h3><div className="status-history">{detail.history.map((item, index) => <div key={`${item.changed_at}-${index}`}><Pill>{item.new_status}</Pill><span>{value(item, 'remarks')}</span><small>{formatDate(item.changed_at)}</small></div>)}</div></>}{detail.priorityHistory?.length > 0 && <><h3>Priority history</h3><div className="status-history">{detail.priorityHistory.map((item, index) => <div key={`${item.changed_at}-${index}`}><Pill>{item.old_priority} → {item.new_priority}</Pill><span>{value(item, 'changed_by_name')}</span><small>{formatDate(item.changed_at)}</small></div>)}</div></>}<h3>Manage complaint</h3><div className="management-grid"><div><label className="control-label">Status<select value={nextStatus} onChange={(e) => setNextStatus(e.target.value)}><option value="">No status change</option>{(detail.data.status === 'SUBMITTED' ? ['UNDER_REVIEW', 'REJECTED'] : detail.data.status === 'UNDER_REVIEW' ? ['REJECTED'] : detail.data.status === 'RESOLVED' ? ['CLOSED'] : []).map((status) => <option key={status} value={status}>{status.replaceAll('_', ' ')}</option>)}</select></label>{nextStatus === 'REJECTED' && <textarea aria-label="Reason for rejection" placeholder="Reason for rejection (required)" value={remarks} onChange={(e) => setRemarks(e.target.value)} maxLength={2000} />}{nextStatus && <button className="secondary-button" disabled={busy} onClick={updateAdminStatus}>Update status</button>}</div><div><label className="control-label">Priority<select value={nextPriority} onChange={(e) => setNextPriority(e.target.value)} disabled={['CLOSED', 'REJECTED'].includes(detail.data.status)}>{priorities.map((priority) => <option key={priority}>{priority}</option>)}</select></label>{!['CLOSED', 'REJECTED'].includes(detail.data.status) && <button className="secondary-button" disabled={busy || nextPriority === detail.data.priority} onClick={updateAdminPriority}>Update priority</button>}</div></div><h3>Assign to staff</h3><div className="inline-form"><select aria-label="Staff assignee" value={staffId} onChange={(e) => setStaffId(e.target.value)}><option value="">Select active staff…</option>{staff.map((person) => <option key={person.user_id} value={person.user_id}>{person.full_name}</option>)}</select><button className="primary-button" disabled={busy || !staffId} onClick={assign}>{busy ? 'Saving…' : 'Assign complaint'}</button></div></>}</Modal>}
  </>;
}

function Students({ token, notify }) {
  const [search, setSearch] = useState(''); const [active, setActive] = useState(''); const [page, setPage] = useState(1); const [selected, setSelected] = useState(null); const [busy, setBusy] = useState(false);
  const result = useLoad(() => api('/admin/students', { token, query: { search, is_active: active, page, per_page: 10 } }).then((r) => ({ rows: dataOf(r), pagination: r.pagination || {} })), [token, search, active, page]);
  async function toggle(student) {
    if (!window.confirm(`${student.is_active ? 'Deactivate' : 'Activate'} ${student.full_name}? This revokes existing sessions.`)) return;
    setBusy(true);
    try { await api('/admin/students/status', { method: 'PATCH', token, body: { student_id: Number(student.user_id), is_active: student.is_active ? 0 : 1 } }); notify('Student status updated; previous sessions were revoked.'); result.refresh(); }
    catch (error) { notify(error.message); } finally { setBusy(false); }
  }
  async function details(student) {
    try {
      const [profile, complaints] = await Promise.all([
        api('/admin/students/show', { token, query: { id: student.user_id } }),
        api('/admin/students/complaints', { token, query: { student_id: student.user_id, page: 1, per_page: 10 } }),
      ]);
      setSelected({ profile: dataOf(profile), complaints: dataOf(complaints), pagination: complaints.pagination || {} });
    } catch (error) { notify(error.message); }
  }
  return <><Heading title="Student directory" description="Search student accounts, view complaint history, and manage access." /><Card className="data-card"><div className="filters"><div className="search-field"><Search size={17} /><input aria-label="Search students" placeholder="Search name, email or enrollment…" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} /></div><select aria-label="Filter student account state" value={active} onChange={(e) => { setActive(e.target.value); setPage(1); }}><option value="">All account states</option><option value="1">Active</option><option value="0">Inactive</option></select></div>{result.loading ? <Loading /> : result.error ? <ErrorState message={result.error} retry={result.refresh} /> : !result.data?.rows?.length ? <Empty>No students found.</Empty> : <><Table columns={['Student', 'Email', 'Enrollment', 'Department', 'Complaints', 'Status', '']} rows={result.data.rows} renderRow={(student) => <tr key={student.user_id}><td><b>{value(student, 'full_name')}</b><small className="cell-sub">ID {value(student, 'user_id')}</small></td><td>{value(student, 'email')}</td><td>{value(student, 'enrollment_number')}</td><td>{value(student, 'department_name')}</td><td>{value(student, 'complaint_count')}</td><td><Pill>{student.is_active ? 'Active' : 'Inactive'}</Pill></td><td><button className="text-button" onClick={() => details(student)}>Details</button><button disabled={busy} className="text-button danger-text" onClick={() => toggle(student)}>{student.is_active ? 'Deactivate' : 'Activate'}</button></td></tr>} /><Pager page={Number(result.data.pagination.page || page)} pages={Number(result.data.pagination.total_pages || 1)} onPage={setPage} /></>}</Card>
    {selected && <Modal title="Student account and complaint history" close={() => setSelected(null)}><div className="detail-grid">{Object.entries(selected.profile).filter(([key]) => !/password|token|secret/i.test(key)).map(([key, val]) => <div key={key}><small>{key.replaceAll('_', ' ')}</small><p>{String(val ?? '—')}</p></div>)}</div><h3>Recent complaints</h3>{selected.complaints.length === 0 ? <p className="muted">No complaints submitted.</p> : <Table columns={['Tracking ID', 'Title', 'Status', 'Priority', 'Submitted']} rows={selected.complaints} renderRow={(item) => <tr key={item.complaint_id}><td>{value(item, 'complaint_number')}</td><td>{value(item, 'title')}</td><td><Pill>{value(item, 'status')}</Pill></td><td><Pill>{value(item, 'priority')}</Pill></td><td>{formatDate(item.created_at)}</td></tr>} />}{selected.pagination.total_pages > 1 && <p className="form-hint">Showing first 10 complaints. Use the complaint queue for paginated browsing.</p>}</Modal>}
  </>;
}

function Staff({ token, notify }) {
  const [search, setSearch] = useState(''); const [active, setActive] = useState(''); const [page, setPage] = useState(1); const [busy, setBusy] = useState(false); const [person, setPerson] = useState(null); const [editor, setEditor] = useState(null);
  const result = useLoad(() => api('/admin/staff', { token, query: { search, is_active: active, page, per_page: 10 } }).then((r) => ({ rows: dataOf(r), pagination: r.pagination || {} })), [token, search, active, page]);
  const departments = useLoad(() => api('/admin/departments', { token }).then(dataOf), [token]);
  async function toggle(item) {
    if (!window.confirm(`${item.is_active ? 'Deactivate' : 'Activate'} ${item.full_name}?`)) return;
    setBusy(true); try { await api('/admin/staff/status', { method: 'PATCH', token, body: { staff_id: Number(item.user_id), is_active: item.is_active ? 0 : 1 } }); notify('Staff status updated.'); result.refresh(); }
    catch (error) { notify(error.message); } finally { setBusy(false); }
  }
  async function saveStaff(event) {
    event.preventDefault(); if (busy) return;
    const fields = Object.fromEntries(new FormData(event.currentTarget));
    const body = { full_name: fields.full_name.trim(), email: fields.email.trim(), phone: fields.phone.trim(), department_id: fields.department_id || null, employee_id: fields.employee_id.trim() };
    if (!editor.user_id) body.password = fields.password;
    setBusy(true);
    try {
      await api(editor.user_id ? '/admin/staff/update' : '/admin/staff', { method: editor.user_id ? 'PATCH' : 'POST', token, body: editor.user_id ? { ...body, staff_id: Number(editor.user_id) } : body });
      notify(editor.user_id ? 'Staff profile updated; existing sessions were revoked.' : 'Staff account created.'); setEditor(null); setPerson(null); result.refresh();
    } catch (error) { notify(error.message); } finally { setBusy(false); }
  }
  return <><Heading title="Staff directory" description="Manage staff profiles, assignment counts, and account activation." action={<button className="primary-button" onClick={() => setEditor({})}>+ Add staff</button>} /><Card className="data-card"><div className="filters"><div className="search-field"><Search size={17} /><input placeholder="Search staff…" aria-label="Search staff" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} /></div><select value={active} aria-label="Filter staff status" onChange={(e) => { setActive(e.target.value); setPage(1); }}><option value="">All account states</option><option value="1">Active</option><option value="0">Inactive</option></select></div>{result.loading ? <Loading /> : result.error ? <ErrorState message={result.error} retry={result.refresh} /> : !result.data?.rows?.length ? <Empty>No staff found.</Empty> : <><Table columns={['Staff member', 'Email', 'Department', 'Assigned complaints', 'Status', 'Action']} rows={result.data.rows} renderRow={(item) => <tr key={item.user_id}><td><b>{value(item, 'full_name')}</b><small className="cell-sub">ID {value(item, 'user_id')}</small></td><td>{value(item, 'email')}</td><td>{value(item, 'department_name')}</td><td>{value(item, 'assigned_complaints')}</td><td><Pill>{item.is_active ? 'Active' : 'Inactive'}</Pill></td><td><button className="text-button" onClick={async () => { try { const r = await api('/admin/staff/show', { token, query: { id: item.user_id } }); setPerson(dataOf(r)); } catch (e) { notify(e.message); } }}>Details</button><button disabled={busy} className="text-button danger-text" onClick={() => toggle(item)}>{item.is_active ? 'Deactivate' : 'Activate'}</button></td></tr>} /><Pager page={Number(result.data.pagination.page || page)} pages={Number(result.data.pagination.total_pages || 1)} onPage={setPage} /></>}</Card>{person && <Modal title="Staff profile" close={() => setPerson(null)}><div className="detail-grid">{Object.entries(person).filter(([key]) => !/password|token|secret/i.test(key)).map(([key, val]) => <div key={key}><small>{key.replaceAll('_', ' ')}</small><p>{String(val ?? '—')}</p></div>)}</div><button className="secondary-button" onClick={() => setEditor(person)}>Edit staff profile</button></Modal>}{editor && <Modal title={editor.user_id ? 'Edit staff profile' : 'Create staff account'} close={() => setEditor(null)}><form className="form-stack" onSubmit={saveStaff}><label>Full name<input name="full_name" required maxLength="150" defaultValue={editor.full_name || ''} /></label><label>Email<input name="email" type="email" required defaultValue={editor.email || ''} /></label>{!editor.user_id && <label>Temporary password (min 8 characters)<input name="password" type="password" required minLength="8" autoComplete="new-password" /></label>}<label>Phone<input name="phone" maxLength="20" defaultValue={editor.phone || ''} /></label><label>Department<select name="department_id" defaultValue={editor.department_id || ''}><option value="">No department</option>{(departments.data || []).map((department) => <option key={department.department_id} value={department.department_id}>{department.department_name}</option>)}</select></label><label>Employee ID<input name="employee_id" maxLength="100" defaultValue={editor.employee_id || ''} /></label><button className="primary-button" disabled={busy || departments.loading}>{busy ? 'Saving…' : 'Save staff account'}</button></form></Modal>}<div className="notice-line"><AlertCircle size={16} />New accounts receive a password set by the administrator. Staff can change it through the existing profile flow.</div></>;
}

function Catalog({ token, kind, notify }) {
  const isDept = kind === 'departments'; const path = `/admin/${kind}`; const [editing, setEditing] = useState(null); const [busy, setBusy] = useState(false);
  const list = useLoad(() => api(path, { token }).then(dataOf), [token, path]);
  async function removeDepartment(row) {
    if (Number(row.total_users || 0) > 0 || Number(row.total_complaints || 0) > 0) { notify('This department is still referenced by users or complaints.'); return; }
    if (!window.confirm(`Delete the unused department “${row.department_name}”?`)) return;
    try { await api('/admin/departments/delete', { method: 'DELETE', token, query: { id: row.department_id } }); notify('Department deleted.'); list.refresh(); }
    catch (error) { notify(error.message); }
  }
  async function save(event) {
    event.preventDefault(); const form = new FormData(event.currentTarget); const payload = Object.fromEntries(form.entries());
    if (isDept) { payload.department_name = payload.department_name.trim(); payload.description = payload.description.trim(); if (!payload.department_name) { notify('Department name is required.'); return; } }
    else { payload.building_name = payload.building_name.trim(); if (!payload.building_name) { notify('Building name is required.'); return; } }
    if (!window.confirm(`${editing?.id ? 'Save changes to' : 'Create'} this ${isDept ? 'department' : 'location'}?`)) return;
    setBusy(true); try { await api(editing?.id ? `${path}/update` : path, { method: editing?.id ? 'PATCH' : 'POST', token, body: editing?.id ? { ...payload, [isDept ? 'department_id' : 'location_id']: Number(editing.id) } : payload }); notify(`${isDept ? 'Department' : 'Location'} saved.`); setEditing(null); list.refresh(); }
    catch (error) { notify(error.message); } finally { setBusy(false); }
  }
  const rows = Array.isArray(list.data) ? list.data : [];
  return <><Heading title={isDept ? 'Departments' : 'Campus locations'} description={isDept ? 'Maintain the departments available to campus users.' : 'Maintain the campus buildings and location details.'} action={<button className="primary-button" onClick={() => setEditing({})}>+ Add {isDept ? 'department' : 'location'}</button>} /><Card className="data-card">{list.loading ? <Loading /> : list.error ? <ErrorState message={list.error} retry={list.refresh} /> : rows.length === 0 ? <Empty>No {kind} have been created yet.</Empty> : <Table columns={isDept ? ['Department', 'Description', 'Staff', 'Complaints', ''] : ['Building', 'Block', 'Floor', 'Room', 'Description', '']} rows={rows} renderRow={(row) => <tr key={row[isDept ? 'department_id' : 'location_id']}>{isDept ? <><td><b>{value(row, 'department_name')}</b></td><td>{value(row, 'description')}</td><td>{value(row, 'total_staff')}</td><td>{value(row, 'total_complaints')}</td></> : <><td><b>{value(row, 'building_name')}</b></td><td>{value(row, 'block_name')}</td><td>{value(row, 'floor_number')}</td><td>{value(row, 'room_number')}</td><td>{value(row, 'description')}</td></>}<td><button className="text-button" onClick={() => setEditing({ id: row[isDept ? 'department_id' : 'location_id'], ...row })}>Edit</button>{isDept && <button className="text-button danger-text" disabled={Number(row.total_users || 0) > 0 || Number(row.total_complaints || 0) > 0} title="Deletion requires no user or complaint references" onClick={() => removeDepartment(row)}>Delete</button>}</td></tr>} />}</Card>{!isDept && <div className="notice-line"><AlertCircle size={16} />Location deletion remains unavailable because there is no archival policy for locations referenced by complaints.</div>}{editing && <Modal title={`${editing.id ? 'Edit' : 'Add'} ${isDept ? 'department' : 'location'}`} close={() => setEditing(null)}><form className="form-stack" onSubmit={save}>{isDept ? <><label>Department name<input name="department_name" maxLength="100" defaultValue={editing.department_name || ''} required /></label><label>Description<textarea name="description" maxLength="5000" rows="4" defaultValue={editing.description || ''} /></label></> : <><label>Building name<input name="building_name" maxLength="150" defaultValue={editing.building_name || ''} required /></label><label>Block<input name="block_name" maxLength="100" defaultValue={editing.block_name || ''} /></label><label>Floor<input name="floor_number" maxLength="20" defaultValue={editing.floor_number || ''} /></label><label>Room<input name="room_number" maxLength="30" defaultValue={editing.room_number || ''} /></label><label>Description<textarea name="description" maxLength="5000" rows="3" defaultValue={editing.description || ''} /></label></>}<button className="primary-button" disabled={busy}>{busy ? 'Saving…' : 'Save'}</button></form></Modal>}</>;
}

function Feedback({ token }) {
  const [filter, setFilter] = useState({ search: '', rating: '', page: 1 }); const [text, setText] = useState(''); const [selected, setSelected] = useState(null);
  useEffect(() => { const id = window.setTimeout(() => setFilter((f) => ({ ...f, search: text, page: 1 })), 300); return () => clearTimeout(id); }, [text]);
  const summary = useLoad(() => api('/admin/feedback/stats', { token }).then(dataOf), [token]);
  const list = useLoad(() => api('/admin/feedback', { token, query: { ...filter } }).then(dataOf), [token, JSON.stringify(filter)]);
  const rows = Array.isArray(list.data?.feedback) ? list.data.feedback : [];
  return <><Heading title="Student feedback" description="Review ratings and comments shared after resolution." />{summary.data && <div className="stat-grid compact-stats"><Card className="stat-card"><span>Average rating</span><strong>{value(summary.data, 'average_rating')} / 5</strong><small>All submitted feedback</small></Card><Card className="stat-card"><span>Responses</span><strong>{value(summary.data, 'total_feedback')}</strong><small>Total ratings</small></Card></div>}<Card className="data-card"><div className="filters"><div className="search-field"><Search size={17} /><input placeholder="Search feedback…" aria-label="Search feedback" value={text} onChange={(e) => setText(e.target.value)} /></div><select aria-label="Filter by rating" value={filter.rating} onChange={(e) => setFilter({ ...filter, rating: e.target.value, page: 1 })}><option value="">All ratings</option>{[5, 4, 3, 2, 1].map((n) => <option key={n} value={n}>{n} stars</option>)}</select></div>{list.loading ? <Loading /> : list.error ? <ErrorState message={list.error} retry={list.refresh} /> : !rows.length ? <Empty>No feedback received yet.</Empty> : <><Table columns={['Rating', 'Student', 'Complaint', 'Comment', 'Received', '']} rows={rows} renderRow={(row) => <tr key={row.feedback_id}><td><b className="stars">{'★'.repeat(Number(row.rating || 0))}</b> {value(row, 'rating')}/5</td><td>{value(row, 'student_name')}</td><td>#{value(row, 'complaint_number')}</td><td className="truncate">{value(row, 'comments')}</td><td>{formatDate(value(row, 'created_at'))}</td><td><button className="text-button" onClick={async () => { try { const r = await api('/admin/feedback/show', { token, query: { feedback_id: row.feedback_id } }); setSelected(dataOf(r)); } catch { setSelected(row); } }}>View</button></td></tr>} /><Pager page={Number(list.data.pagination?.page || filter.page)} pages={Number(list.data.pagination?.total_pages || 1)} onPage={(page) => setFilter({ ...filter, page })} /></>}</Card>{selected && <Modal title="Feedback details" close={() => setSelected(null)}><div className="detail-grid">{Object.entries(selected).map(([key, val]) => <div key={key}><small>{key.replaceAll('_', ' ')}</small><p>{String(val ?? '—')}</p></div>)}</div></Modal>}</>;
}

function Notifications({ token, notify }) {
  const [page, setPage] = useState(1);
  const list = useLoad(() => api('/notifications', { token, query: { page, limit: 20 } }).then(dataOf), [token, page]);
  async function mark(item) { try { await api('/notifications/read', { method: 'PATCH', token, query: { notification_id: item.notification_id } }); notify('Notification marked as read.'); list.refresh(); } catch (error) { notify(error.message); } }
  async function remove(item) {
    if (!window.confirm('Delete this notification from your account?')) return;
    try { await api('/notifications/delete', { method: 'DELETE', token, query: { notification_id: item.notification_id } }); notify('Notification deleted.'); list.refresh(); }
    catch (error) { notify(error.message); }
  }
  const rows = Array.isArray(list.data) ? list.data : [];
  return <><Heading title="Notifications" description="Notifications belonging to this signed-in admin account." action={<button className="secondary-button" disabled={!rows.some((item) => !item.is_read)} onClick={async () => { try { await api('/notifications/read-all', { method: 'PATCH', token }); notify('Notifications marked as read.'); list.refresh(); } catch (error) { notify(error.message); } }}>Mark all read</button>} /><Card className="notification-list">{list.loading ? <Loading /> : list.error ? <ErrorState message={list.error} retry={list.refresh} /> : !rows.length ? <Empty>You have no notifications.</Empty> : rows.map((item) => <div className={`notification-row ${item.is_read ? '' : 'unread'}`} key={item.notification_id}><div className="notification-icon"><Bell size={17} /></div><div className="notification-copy"><b>{value(item, 'title')}</b><p>{value(item, 'message')}</p><small>{formatDate(value(item, 'created_at'))}{item.complaint_id ? ` · Complaint #${item.complaint_id}` : ''}</small></div><div className="notification-actions">{!item.is_read && <button className="text-button" onClick={() => mark(item)}>Mark read</button>}<button className="text-button danger-text" onClick={() => remove(item)}>Delete</button></div></div>)}</Card>{(rows.length === 20 || page > 1) && <Pager page={page} pages={Math.max(page, page + (rows.length === 20 ? 1 : 0))} onPage={setPage} />}<div className="notice-line"><AlertCircle size={16} />The API scopes notifications to the current account. Admin-wide broadcasts and notification creation are unavailable.</div></>;
}

function Profile({ token, admin, notify }) {
  const profile = useLoad(() => api('/profile', { token }).then(dataOf), [token]);
  return <><Heading title="Administrator profile" description="Your account information from the authenticated profile API." />{profile.loading ? <Loading /> : profile.error ? <ErrorState message={profile.error} retry={profile.refresh} /> : <Card className="profile-card"><div className="profile-avatar">{String(value(profile.data, 'full_name', 'email') || 'A').slice(0, 1).toUpperCase()}</div><div><p className="eyebrow">ADMIN ACCOUNT</p><h2>{value(profile.data, 'full_name')}</h2><p className="muted">{value(profile.data, 'email')}</p></div><div className="profile-fields">{Object.entries(profile.data || {}).filter(([key]) => !/password|token|secret/i.test(key)).map(([key, val]) => <div key={key}><small>{key.replaceAll('_', ' ')}</small><b>{String(val ?? '—')}</b></div>)}</div><div className="notice-line"><AlertCircle size={16} />Profile editing and password changes are omitted; this console exposes only read-only account details.</div><button className="secondary-button" onClick={() => notify(`Signed in as ${value(admin, 'email')}`)}>Confirm account</button></Card>}</>;
}

function ProtectedImage({ imageId, token }) {
  const [source, setSource] = useState(''); const [error, setError] = useState('');
  useEffect(() => {
    const controller = new AbortController(); let objectUrl = '';
    apiBinary('/complaints/image', { token, query: { id: imageId }, signal: controller.signal })
      .then((blob) => { if (controller.signal.aborted || !blob.type.startsWith('image/')) return; objectUrl = URL.createObjectURL(blob); setSource(objectUrl); })
      .catch((exception) => { if (!controller.signal.aborted) setError(exception.message); });
    return () => { controller.abort(); if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [imageId, token]);
  if (error) return <div className="image-fallback" role="status">Image unavailable</div>;
  return source ? <img className="protected-image" src={source} alt="Complaint attachment" /> : <div className="image-fallback">Loading image…</div>;
}

function Modal({ title, close, children }) { useEffect(() => { const handle = (event) => { if (event.key === 'Escape') close(); }; window.addEventListener('keydown', handle); return () => window.removeEventListener('keydown', handle); }, [close]); return <div className="modal-backdrop" role="presentation" onMouseDown={(e) => { if (e.target === e.currentTarget) close(); }}><section className="modal" role="dialog" aria-modal="true" aria-label={title}><div className="modal-head"><h2>{title}</h2><button className="icon-button" aria-label="Close dialog" onClick={close}><X size={19} /></button></div><div className="modal-body">{children}</div></section></div>; }
function Pager({ page, pages, onPage }) { if (pages <= 1) return null; return <div className="pager"><span>Page {page} of {pages}</span><div><button className="icon-button" disabled={page <= 1} onClick={() => onPage(page - 1)} aria-label="Previous page"><ChevronLeft size={18} /></button><button className="icon-button" disabled={page >= pages} onClick={() => onPage(page + 1)} aria-label="Next page"><ChevronRight size={18} /></button></div></div>; }

createRoot(document.getElementById('root')).render(<StrictMode><App /></StrictMode>);
