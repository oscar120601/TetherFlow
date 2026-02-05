/**
 * TetherFlow Web UI - JavaScript Application
 */

// 全域狀態
const state = {
    password: null,
    profiles: [],
    history: [],
    autoRefresh: true,
    refreshInterval: null
};

const API_BASE = 'http://localhost:5000/api';

// 初始化
function init() {
    setupNavigation();
    loadStatus();
    loadProfiles();
    loadHistory();
    
    // 自動重新整理
    if (state.autoRefresh) {
        startAutoRefresh();
    }
}

// 導航設定
function setupNavigation() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const page = item.dataset.page;
            showPage(page);
            
            // 更新 active 狀態
            document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
            item.classList.add('active');
        });
    });
}

// 顯示頁面
function showPage(pageId) {
    document.querySelectorAll('.page').forEach(page => {
        page.classList.remove('active');
    });
    document.getElementById(`page-${pageId}`).classList.add('active');
    
    // 更新標題
    const titles = {
        'dashboard': '儀表板',
        'profiles': 'Profiles',
        'history': '歷史記錄',
        'settings': '設定'
    };
    document.querySelector('.page-title').textContent = titles[pageId];
}

// Toast 通知
function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast ${type}`;
    toast.classList.add('show');
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// API 呼叫輔助函數
async function apiCall(endpoint, options = {}) {
    try {
        const response = await fetch(`${API_BASE}${endpoint}`, {
            headers: {
                'Content-Type': 'application/json'
            },
            ...options
        });
        
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('API Error:', error);
        showToast('網路連線失敗', 'error');
        return { success: false, error: '網路錯誤' };
    }
}

// 載入狀態
async function loadStatus() {
    const data = await apiCall('/status');
    
    if (data.success) {
        const { ttl, mtu, is_cloaked, has_password } = data.data;
        
        // 更新 TTL
        document.getElementById('ttl-value').textContent = ttl;
        const ttlBadge = document.getElementById('ttl-badge');
        ttlBadge.textContent = ttl === 65 ? '偽裝模式' : '正常';
        ttlBadge.className = 'status-badge' + (ttl === 65 ? ' success' : '');
        
        // 更新 MTU
        document.getElementById('mtu-value').textContent = mtu;
        const mtuBadge = document.getElementById('mtu-badge');
        mtuBadge.textContent = mtu === 1400 ? '偽裝模式' : '正常';
        mtuBadge.className = 'status-badge' + (mtu === 1400 ? ' success' : '');
        
        // 更新主狀態
        const cloakStatus = document.getElementById('cloak-status');
        const cloakBadge = document.getElementById('cloak-badge');
        
        if (is_cloaked) {
            cloakStatus.textContent = '🟢 偽裝中';
            cloakBadge.textContent = '已啟動';
            cloakBadge.className = 'status-badge success';
        } else {
            cloakStatus.textContent = '🔴 正常模式';
            cloakBadge.textContent = '未啟動';
            cloakBadge.className = 'status-badge';
        }
        
        // 更新密碼狀態
        if (has_password) {
            state.password = 'saved';
            updatePasswordUI(true);
        }
    }
}

// 更新密碼 UI
function updatePasswordUI(saved) {
    const card = document.getElementById('password-card');
    const status = document.getElementById('password-status');
    const clearBtn = document.getElementById('btn-clear-pwd');
    const startBtn = document.getElementById('btn-start');
    const stopBtn = document.getElementById('btn-stop');
    
    if (saved) {
        card.classList.add('saved');
        status.textContent = '已設定';
        clearBtn.style.display = 'inline-flex';
        startBtn.disabled = false;
        stopBtn.disabled = false;
    } else {
        card.classList.remove('saved');
        status.textContent = '未設定';
        clearBtn.style.display = 'none';
        startBtn.disabled = true;
        stopBtn.disabled = true;
    }
}

// 切換密碼顯示
function togglePassword() {
    const input = document.getElementById('password-input');
    const checkbox = document.getElementById('show-password');
    input.type = checkbox.checked ? 'text' : 'password';
}

// 儲存密碼
async function savePassword() {
    const input = document.getElementById('password-input');
    const password = input.value.trim();
    
    if (!password) {
        showToast('請輸入密碼', 'error');
        return;
    }
    
    const data = await apiCall('/save-password', {
        method: 'POST',
        body: JSON.stringify({ password })
    });
    
    if (data.success) {
        state.password = password;
        updatePasswordUI(true);
        showToast('✅ 密碼已儲存！現在可以啟動/停止偽裝');
        input.value = '';
    } else {
        showToast(data.error || '密碼錯誤', 'error');
    }
}

// 清除密碼
async function clearPassword() {
    await apiCall('/clear-password', { method: 'POST' });
    state.password = null;
    updatePasswordUI(false);
    showToast('密碼已清除');
}

// 啟動偽裝
async function startCloaking() {
    if (!state.password) {
        showToast('請先儲存密碼', 'warning');
        return;
    }
    
    const btn = document.getElementById('btn-start');
    btn.innerHTML = '<span class="loading"></span> 處理中...';
    btn.disabled = true;
    
    const data = await apiCall('/start', { method: 'POST' });
    
    if (data.success) {
        showToast(data.message, 'success');
        loadStatus();
        loadHistory();
    } else {
        showToast(data.error, 'error');
        if (data.error && data.error.includes('密碼')) {
            clearPassword();
        }
    }
    
    btn.innerHTML = '<span class="btn-icon">🟢</span><span class="btn-text"><strong>啟動偽裝</strong><small>設定 TTL=65, MTU=1400</small></span>';
    btn.disabled = false;
}

// 停止偽裝
async function stopCloaking() {
    if (!state.password) {
        showToast('請先儲存密碼', 'warning');
        return;
    }
    
    const btn = document.getElementById('btn-stop');
    btn.innerHTML = '<span class="loading"></span> 處理中...';
    btn.disabled = true;
    
    const data = await apiCall('/stop', { method: 'POST' });
    
    if (data.success) {
        showToast(data.message, 'success');
        loadStatus();
        loadHistory();
    } else {
        showToast(data.error, 'error');
    }
    
    btn.innerHTML = '<span class="btn-icon">🔴</span><span class="btn-text"><strong>停止偽裝</strong><small>還原 TTL=64, MTU=1500</small></span>';
    btn.disabled = false;
}

// Profile 功能
async function loadProfiles() {
    const data = await apiCall('/profiles');
    
    if (data.success) {
        state.profiles = data.data;
        renderProfiles();
    }
}

function renderProfiles() {
    const container = document.getElementById('profiles-list');
    
    if (state.profiles.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <span class="empty-icon">📭</span>
                <p>尚無 Profiles</p>
                <p class="empty-hint">點擊「新增 Profile」建立您的第一個設定</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = state.profiles.map(profile => `
        <div class="profile-item" data-id="${profile.id}">
            <div class="profile-info">
                <div class="profile-name">${profile.name}</div>
                <div class="profile-details">
                    SSID: ${profile.ssid} | TTL: ${profile.ttl} | MTU: ${profile.mtu}
                    ${profile.auto_start ? '| 🔄 自動啟動' : ''}
                </div>
            </div>
            <div class="profile-actions">
                <button class="btn btn-secondary" onclick="editProfile(${profile.id})">編輯</button>
                <button class="btn btn-secondary" onclick="deleteProfile(${profile.id})">刪除</button>
            </div>
        </div>
    `).join('');
}

function showAddProfileModal() {
    document.getElementById('modal-title').textContent = '新增 Profile';
    document.getElementById('profile-id').value = '';
    document.getElementById('profile-name').value = '';
    document.getElementById('profile-ssid').value = '';
    document.getElementById('profile-ttl').value = '65';
    document.getElementById('profile-mtu').value = '1400';
    document.getElementById('profile-auto').checked = false;
    document.getElementById('profile-modal').classList.add('show');
}

function editProfile(id) {
    const profile = state.profiles.find(p => p.id === id);
    if (!profile) return;
    
    document.getElementById('modal-title').textContent = '編輯 Profile';
    document.getElementById('profile-id').value = profile.id;
    document.getElementById('profile-name').value = profile.name;
    document.getElementById('profile-ssid').value = profile.ssid;
    document.getElementById('profile-ttl').value = profile.ttl;
    document.getElementById('profile-mtu').value = profile.mtu;
    document.getElementById('profile-auto').checked = profile.auto_start;
    document.getElementById('profile-modal').classList.add('show');
}

function closeModal() {
    document.getElementById('profile-modal').classList.remove('show');
}

async function saveProfile() {
    const id = document.getElementById('profile-id').value;
    const profile = {
        name: document.getElementById('profile-name').value,
        ssid: document.getElementById('profile-ssid').value,
        ttl: parseInt(document.getElementById('profile-ttl').value),
        mtu: parseInt(document.getElementById('profile-mtu').value),
        auto_start: document.getElementById('profile-auto').checked
    };
    
    if (!profile.name || !profile.ssid) {
        showToast('請填寫名稱和 SSID', 'error');
        return;
    }
    
    const endpoint = id ? `/profiles/${id}` : '/profiles';
    const method = id ? 'PUT' : 'POST';
    
    const data = await apiCall(endpoint, {
        method,
        body: JSON.stringify(profile)
    });
    
    if (data.success) {
        showToast(id ? 'Profile 已更新' : 'Profile 已建立', 'success');
        closeModal();
        loadProfiles();
    } else {
        showToast(data.error, 'error');
    }
}

async function deleteProfile(id) {
    if (!confirm('確定要刪除這個 Profile 嗎？')) return;
    
    const data = await apiCall(`/profiles/${id}`, { method: 'DELETE' });
    
    if (data.success) {
        showToast('Profile 已刪除', 'success');
        loadProfiles();
    }
}

// 歷史記錄
async function loadHistory() {
    const data = await apiCall('/history');
    
    if (data.success) {
        state.history = data.data;
        renderHistory();
    }
}

function renderHistory() {
    const container = document.getElementById('history-list');
    
    if (state.history.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <span class="empty-icon">📭</span>
                <p>尚無操作記錄</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = state.history.slice().reverse().map(item => {
        const date = new Date(item.timestamp);
        const timeStr = date.toLocaleString('zh-TW');
        const actionText = item.action === 'start_cloaking' ? '啟動偽裝' : '停止偽裝';
        
        return `
            <div class="history-item">
                <span class="history-time">${timeStr}</span>
                <span class="history-action">${actionText}</span>
                <span class="history-status ${item.success ? 'success' : 'error'}">
                    ${item.success ? '成功' : '失敗'}
                </span>
            </div>
        `;
    }).join('');
}

async function clearHistory() {
    if (!confirm('確定要清空所有歷史記錄嗎？')) return;
    
    // 這裡需要後端支援，目前只是前端清空
    state.history = [];
    renderHistory();
    showToast('歷史記錄已清空');
}

// 設定
function toggleAutoRefresh() {
    state.autoRefresh = document.getElementById('auto-refresh').checked;
    
    if (state.autoRefresh) {
        startAutoRefresh();
    } else {
        stopAutoRefresh();
    }
}

function startAutoRefresh() {
    stopAutoRefresh();
    state.refreshInterval = setInterval(() => {
        loadStatus();
    }, 5000);
}

function stopAutoRefresh() {
    if (state.refreshInterval) {
        clearInterval(state.refreshInterval);
        state.refreshInterval = null;
    }
}

function toggleDarkMode() {
    const isDark = document.getElementById('dark-mode').checked;
    document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
}

// 重新整理全部
function refreshAll() {
    loadStatus();
    loadProfiles();
    loadHistory();
    showToast('已重新整理');
}

// 頁面載入時初始化
document.addEventListener('DOMContentLoaded', () => {
    // 載入主題設定
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
        document.getElementById('dark-mode').checked = true;
        document.documentElement.setAttribute('data-theme', 'dark');
    }
    
    init();
});

// 點擊 modal 外部關閉
document.getElementById('profile-modal').addEventListener('click', (e) => {
    if (e.target.id === 'profile-modal') {
        closeModal();
    }
});
