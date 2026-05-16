// 目前登入使用者快取
let _currentUser = null;
let _currentProfile = null;

async function getUser() {
  if (_currentUser) return _currentUser;
  const { data: { user } } = await db.auth.getUser();
  _currentUser = user;
  return user;
}

async function getProfile() {
  if (_currentProfile) return _currentProfile;
  const user = await getUser();
  if (!user) return null;
  const { data } = await db
    .from('user_profiles')
    .select('*, family_members(*)')
    .eq('user_id', user.id)
    .single();
  _currentProfile = data;
  return data;
}

async function requireAuth() {
  // getUser 與 getProfile 共用同一個 session，不需要等 getUser 完才開始 getProfile
  const user = await getUser();
  if (!user) {
    window.location.href = 'login.html';
    return null;
  }
  const profile = await getProfile();
  if (!profile) {
    showProfileSetupModal();
    return null;
  }
  return { user, profile };
}

async function signInWithGoogle() {
  const { error } = await db.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: window.location.origin + '/index.html' }
  });
  if (error) showToast('登入失敗：' + error.message, 'error');
}

async function signOut() {
  await db.auth.signOut();
  _currentUser = null;
  _currentProfile = null;
  window.location.href = 'login.html';
}

async function saveProfile(memberId) {
  const user = await getUser();
  const member = getMember(memberId);
  const { error } = await db.from('user_profiles').upsert({
    user_id: user.id,
    member_id: memberId,
    display_name: member.name,
  });
  if (error) { showToast('儲存失敗', 'error'); return; }
  _currentProfile = null;
  window.location.href = 'index.html';
}

function showProfileSetupModal() {
  const html = `
    <div id="profile-modal" class="modal-overlay">
      <div class="modal-box" style="text-align:center;">
        <div style="font-size:2.5rem;margin-bottom:0.5rem;">👋</div>
        <h2 style="margin-bottom:0.25rem;">你是誰呢？</h2>
        <p style="color:#888;margin-bottom:1.5rem;">請選擇你的身份，之後就認識你了！</p>
        <div style="display:flex;gap:1rem;justify-content:center;">
          <button class="btn-member" onclick="saveProfile('bei')" style="background:#5BB8E820;border:2px solid #5BB8E8;color:#5BB8E8;">
            ☁️ 貝（我）
          </button>
          <button class="btn-member" onclick="saveProfile('qun')" style="background:#7B5EA720;border:2px solid #7B5EA7;color:#7B5EA7;">
            🌙 群（先生）
          </button>
        </div>
      </div>
    </div>`;
  document.body.insertAdjacentHTML('beforeend', html);
}

// 全站 toast 提示
function showToast(msg, type = 'info') {
  const el = document.createElement('div');
  el.className = `toast toast-${type}`;
  el.textContent = msg;
  document.body.appendChild(el);
  requestAnimationFrame(() => el.classList.add('show'));
  setTimeout(() => { el.classList.remove('show'); setTimeout(() => el.remove(), 300); }, 2800);
}

// 格式化金額
function formatMoney(n) {
  return '$' + Number(n).toLocaleString('zh-TW');
}

// 格式化日期 YYYY-MM-DD → M/D
function fmtDate(str) {
  if (!str) return '';
  const d = new Date(str);
  return `${d.getMonth() + 1}/${d.getDate()}`;
}

// 取得今天 YYYY-MM-DD
function today() {
  return new Date().toISOString().slice(0, 10);
}

// 取得本月第一天
function monthStart(ym) {
  return ym + '-01';
}

// 取得本月最後一天
function monthEnd(ym) {
  const [y, m] = ym.split('-').map(Number);
  return new Date(y, m, 0).toISOString().slice(0, 10);
}

// 現在是 YYYY-MM
function currentYM() {
  return new Date().toISOString().slice(0, 7);
}
