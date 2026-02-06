/**
 * TetherFlow - Phase 3 Implementation
 * Features: Auto-Detection, DoH/DoT DNS, Traffic Shaping, System Integration
 */

// Global State
const state = {
    password: null,
    profiles: [],
    history: [],
    autoRefresh: true,
    refreshInterval: null,
    currentPage: 'dashboard',
    currentSSID: null,
    matchingProfile: null,
    speedTestHistory: [],
    sessionStats: null,
    isSpeedTesting: false,
    // Phase 3
    autoDetection: false,
    dnsSettings: null,
    trafficShaping: null,
    systemSettings: null,
    trafficRules: []
};

const API_BASE = '/api';

// Initialize Icons
function initIcons() {
    if (typeof lucide !== 'undefined') {
        lucide.createIcons();
    }
}

// Initialize Application
document.addEventListener('DOMContentLoaded', () => {
    init();
    initIcons();
    loadTheme();
});

function init() {
    setupNavigation();
    setupModalClose();
    loadStatus();
    loadProfiles();
    loadHistory();
    loadSpeedTestHistory();
    loadSessionStats();
    detectWifi();
    // Phase 3
    loadPhase3Settings();

    if (state.autoRefresh) {
        startAutoRefresh();
    }
}

// Theme Management
function loadTheme() {
    const savedTheme = localStorage.getItem('theme');
    const isDark = savedTheme === 'dark' ||
        (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches);

    if (isDark) {
        document.documentElement.classList.add('dark');
        document.getElementById('dark-mode').checked = true;
    }
}

function toggleTheme() {
    const isDark = document.documentElement.classList.toggle('dark');
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
    document.getElementById('dark-mode').checked = isDark;
}

function toggleDarkMode() {
    const checkbox = document.getElementById('dark-mode');
    if (checkbox.checked) {
        document.documentElement.classList.add('dark');
        localStorage.setItem('theme', 'dark');
    } else {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('theme', 'light');
    }
}

// Navigation
function setupNavigation() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const page = item.dataset.page;
            showPage(page);

            // Update active state
            document.querySelectorAll('.nav-item').forEach(i => {
                i.classList.remove('nav-active');
                i.classList.remove('bg-surface-100', 'dark:bg-surface-800');
            });
            item.classList.add('nav-active');
            item.classList.add('bg-surface-100', 'dark:bg-surface-800');
        });
    });
}

function showPage(pageId) {
    state.currentPage = pageId;

    // Hide all pages
    document.querySelectorAll('.page-content').forEach(page => {
        page.classList.add('hidden');
    });

    // Show target page with animation
    const targetPage = document.getElementById(`page-${pageId}`);
    targetPage.classList.remove('hidden');
    targetPage.classList.remove('animate-fade-in');
    void targetPage.offsetWidth; // Trigger reflow
    targetPage.classList.add('animate-fade-in');

    // Update title and subtitle with i18n
    if (typeof i18n !== 'undefined') {
        document.getElementById('page-title').textContent = i18n.t(`page.${pageId}.title`);
        const headerSubtitle = document.getElementById('page-subtitle');
        if (headerSubtitle) {
            headerSubtitle.textContent = i18n.t(`page.${pageId}.subtitle`);
        }
        if (pageId === 'profiles') renderProfiles();
        if (pageId === 'history') renderHistory();
        if (pageId === 'dashboard') {
            loadSessionStats();
            renderSpeedTestHistory();
        }
        if (pageId === 'settings') {
            loadPhase3Settings();
        }
    } else {
        const titles = {
            'dashboard': 'Dashboard',
            'profiles': 'Wi-Fi Profiles',
            'history': 'History',
            'settings': 'Settings'
        };
        document.getElementById('page-title').textContent = titles[pageId];
    }
}

// Toast Notifications
function showToast(message, type = 'success') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');

    const colors = {
        success: 'bg-emerald-500',
        error: 'bg-rose-500',
        warning: 'bg-amber-500',
        info: 'bg-blue-500'
    };

    const icons = {
        success: 'check-circle',
        error: 'x-circle',
        warning: 'alert-triangle',
        info: 'info'
    };

    let displayMessage = message;
    if (typeof i18n !== 'undefined' && message && typeof message === 'string' && message.startsWith('toast.')) {
        const translated = i18n.t(message);
        displayMessage = translated || message;
    }

    toast.className = `${colors[type]} text-white px-6 py-4 rounded-xl shadow-lg flex items-center gap-3 toast-enter transform transition-all duration-300`;
    toast.innerHTML = `
        <i data-lucide="${icons[type]}" class="w-5 h-5"></i>
        <span class="font-medium">${displayMessage}</span>
    `;

    container.appendChild(toast);
    initIcons();

    requestAnimationFrame(() => {
        toast.classList.remove('toast-enter');
        toast.classList.add('toast-enter-active');
    });

    setTimeout(() => {
        toast.classList.remove('toast-enter-active');
        toast.classList.add('toast-exit-active');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// API Helper
async function apiCall(endpoint, options = {}) {
    const { suppressError, ...fetchOptions } = options;
    const url = `${API_BASE}${endpoint}`;
    console.log('[API] 呼叫:', url, '方法:', fetchOptions.method || 'GET');
    
    try {
        const response = await fetch(url, {
            headers: {
                'Content-Type': 'application/json'
            },
            ...fetchOptions
        });

        console.log('[API] 回應狀態:', response.status);
        const data = await response.json();
        console.log('[API] 回應資料:', data);
        return data;
    } catch (error) {
        console.error('[API] 錯誤:', error);
        console.error('[API] 錯誤詳情:', error.message);
        if (!suppressError) {
            showToast('Network connection failed: ' + error.message, 'error');
        }
        return { success: false, error: 'Network error: ' + error.message };
    }
}

// ==================== Phase 3: New Features ====================

// T007: Wi-Fi Auto-Detection
async function loadPhase3Settings() {
    const data = await apiCall('/status');
    if (data.success) {
        const { auto_detection, dns_settings, traffic_shaping, system_settings } = data.data;

        // Update state
        state.autoDetection = auto_detection;
        state.dnsSettings = dns_settings;
        state.trafficShaping = traffic_shaping;
        state.systemSettings = system_settings;

        // Update UI
        updateAutoDetectionUI();
        updateDNSUI();
        updateTrafficUI();
        updateSystemUI();
    }
}

function updateAutoDetectionUI() {
    const toggle = document.getElementById('autodetect-toggle');
    const statusText = document.getElementById('autodetect-status-text');
    if (!toggle || !statusText) return;

    toggle.checked = state.autoDetection;
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    statusText.textContent = state.autoDetection ? t('autodetect.enabled') : t('autodetect.disabled');
}

async function toggleAutoDetection() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const newState = document.getElementById('autodetect-toggle').checked;

    const data = await apiCall('/wifi/auto-detection', {
        method: 'POST',
        body: JSON.stringify({ enabled: newState })
    });

    if (data.success) {
        state.autoDetection = data.data.enabled;
        updateAutoDetectionUI();
        showToast(t('autodetect.enabled'), 'success');
    } else {
        showToast(data.error, 'error');
        document.getElementById('autodetect-toggle').checked = state.autoDetection;
    }
}

// T008: DNS Settings
function updateDNSUI() {
    if (!state.dnsSettings) return;

    const toggle = document.getElementById('dns-toggle');
    const statusText = document.getElementById('dns-status-text');
    const providerSelect = document.getElementById('dns-provider');
    const serversDisplay = document.getElementById('dns-servers-display');

    if (toggle) toggle.checked = state.dnsSettings.enabled;

    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    if (statusText) statusText.textContent = state.dnsSettings.enabled ? t('dns.enabled') : t('dns.disabled');

    if (providerSelect) {
        providerSelect.value = state.dnsSettings.provider;
        updateDNSServersDisplay();
    }
}

function updateDNSServersDisplay() {
    const provider = document.getElementById('dns-provider')?.value;
    const serversDisplay = document.getElementById('dns-servers-display');

    const dnsServers = {
        'cloudflare': '1.1.1.1, 1.0.0.1',
        'cloudflare_family': '1.1.1.3, 1.0.0.3',
        'google': '8.8.8.8, 8.8.4.4',
        'quad9': '9.9.9.9, 149.112.112.112',
        'opendns': '208.67.222.222, 208.67.220.220'
    };

    if (serversDisplay && dnsServers[provider]) {
        serversDisplay.textContent = `Servers: ${dnsServers[provider]}`;
    }
}

async function toggleDNSSettings() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const newState = document.getElementById('dns-toggle').checked;
    const provider = document.getElementById('dns-provider')?.value || 'cloudflare';

    const data = await apiCall('/dns/settings', {
        method: 'POST',
        body: JSON.stringify({
            enabled: newState,
            provider: provider
        })
    });

    if (data.success) {
        state.dnsSettings = data.data;
        updateDNSUI();
        showToast(t('dns.applied'), 'success');
    } else {
        showToast(data.error, 'error');
        document.getElementById('dns-toggle').checked = state.dnsSettings?.enabled || false;
    }
}

function changeDNSProvider() {
    updateDNSServersDisplay();
    // If DNS is enabled, apply new provider immediately
    if (state.dnsSettings?.enabled) {
        toggleDNSSettings();
    }
}

// T009: Traffic Shaping
function updateTrafficUI() {
    if (!state.trafficShaping) return;

    const toggle = document.getElementById('traffic-toggle');
    const statusText = document.getElementById('traffic-status-text');
    const rulesSection = document.getElementById('traffic-rules-section');

    if (toggle) toggle.checked = state.trafficShaping.enabled;

    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    if (statusText) statusText.textContent = state.trafficShaping.enabled ? t('traffic.enabled') : t('traffic.disabled');

    if (rulesSection) {
        rulesSection.classList.toggle('hidden', !state.trafficShaping.enabled);
    }

    renderTrafficRules();
}

function renderTrafficRules() {
    const container = document.getElementById('traffic-rules-list');
    if (!container || !state.trafficShaping) return;

    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const rules = state.trafficShaping.rules || [];

    if (rules.length === 0) {
        container.innerHTML = `<p class="text-center text-surface-500 py-4 text-sm">${t('traffic.no_rules')}</p>`;
        return;
    }

    container.innerHTML = rules.map(rule => `
        <div class="flex items-center justify-between p-3 rounded-xl bg-surface-50 dark:bg-surface-800/50">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                    <i data-lucide="sliders" class="w-4 h-4 text-amber-600"></i>
                </div>
                <div>
                    <p class="font-medium text-surface-900 dark:text-white text-sm">${rule.name}</p>
                    <p class="text-xs text-surface-500">Port ${rule.port} (${rule.protocol.toUpperCase()}) - ${rule.bandwidth} Kbps</p>
                </div>
            </div>
            <button onclick="deleteTrafficRule(${rule.id})" class="p-2 rounded-lg hover:bg-rose-100 dark:hover:bg-rose-900/30 text-surface-500 hover:text-rose-600 transition-colors">
                <i data-lucide="trash-2" class="w-4 h-4"></i>
            </button>
        </div>
    `).join('');

    initIcons();
}

async function toggleTrafficShaping() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const newState = document.getElementById('traffic-toggle').checked;

    const data = await apiCall('/traffic/enable', {
        method: 'POST',
        body: JSON.stringify({ enabled: newState })
    });

    if (data.success) {
        state.trafficShaping = data.data;
        updateTrafficUI();
        showToast(newState ? t('traffic.enabled') : t('traffic.disabled'), 'success');
    } else {
        showToast(data.error, 'error');
        document.getElementById('traffic-toggle').checked = state.trafficShaping?.enabled || false;
    }
}

function showAddTrafficRuleModal() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    document.getElementById('traffic-modal-title').textContent = t('traffic.add_rule');
    document.getElementById('traffic-rule-id').value = '';
    document.getElementById('traffic-rule-name').value = '';
    document.getElementById('traffic-rule-port').value = '';
    document.getElementById('traffic-rule-protocol').value = 'tcp';
    document.getElementById('traffic-rule-bandwidth').value = '1000';

    const modal = document.getElementById('traffic-rule-modal');
    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

function closeTrafficModal() {
    const modal = document.getElementById('traffic-rule-modal');
    modal.classList.add('hidden');
    modal.classList.remove('flex');
}

async function saveTrafficRule() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    const rule = {
        name: document.getElementById('traffic-rule-name').value,
        port: document.getElementById('traffic-rule-port').value,
        protocol: document.getElementById('traffic-rule-protocol').value,
        bandwidth: parseInt(document.getElementById('traffic-rule-bandwidth').value)
    };

    if (!rule.name || !rule.port) {
        showToast(t('toast.fill_required'), 'error');
        return;
    }

    const data = await apiCall('/traffic/rules', {
        method: 'POST',
        body: JSON.stringify(rule)
    });

    if (data.success) {
        showToast(t('common.save'), 'success');
        closeTrafficModal();
        loadPhase3Settings();
    } else {
        showToast(data.error, 'error');
    }
}

async function deleteTrafficRule(ruleId) {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    if (!confirm(t('traffic.delete_confirm'))) return;

    const data = await apiCall(`/traffic/rules?id=${ruleId}`, { method: 'DELETE' });

    if (data.success) {
        showToast(t('common.delete'), 'success');
        loadPhase3Settings();
    }
}

// T010: System Integration
function updateSystemUI() {
    if (!state.systemSettings) return;

    const autoLaunchToggle = document.getElementById('autolaunch-toggle');
    const menubarToggle = document.getElementById('menubar-toggle');
    const shortcutDisplay = document.getElementById('current-shortcut');

    if (autoLaunchToggle) autoLaunchToggle.checked = state.systemSettings.auto_launch;
    if (menubarToggle) menubarToggle.checked = state.systemSettings.menubar_enabled;
    if (shortcutDisplay) shortcutDisplay.textContent = state.systemSettings.global_shortcut;
}

async function toggleAutoLaunch() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const newState = document.getElementById('autolaunch-toggle').checked;

    const data = await apiCall('/system/settings', {
        method: 'POST',
        body: JSON.stringify({
            auto_launch: newState,
            menubar_enabled: state.systemSettings?.menubar_enabled || false,
            global_shortcut: state.systemSettings?.global_shortcut || 'Cmd+Shift+T'
        })
    });

    if (data.success) {
        state.systemSettings = data.data;
        updateSystemUI();
        showToast(newState ? t('system.auto_launch') + ' ON' : t('system.auto_launch') + ' OFF', 'success');
    }
}

async function toggleMenubar() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const newState = document.getElementById('menubar-toggle').checked;

    const data = await apiCall('/system/settings', {
        method: 'POST',
        body: JSON.stringify({
            auto_launch: state.systemSettings?.auto_launch || false,
            menubar_enabled: newState,
            global_shortcut: state.systemSettings?.global_shortcut || 'Cmd+Shift+T'
        })
    });

    if (data.success) {
        state.systemSettings = data.data;
        updateSystemUI();
        showToast(newState ? t('system.menubar') + ' ON' : t('system.menubar') + ' OFF', 'success');
    }
}

function recordShortcut() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    showToast(t('system.press_key'), 'info');
    // TODO: Implement shortcut recording
}

// ==================== T004: Wi-Fi Auto-Detection ====================

async function detectWifi() {
    const data = await apiCall('/wifi/detect');

    if (data.success) {
        state.currentSSID = data.data.ssid;
        state.matchingProfile = data.data.matching_profile;
        updateWifiDetectionUI(data.data);
    } else {
        hideWifiDetectionUI();
    }
}

function updateWifiDetectionUI(data) {
    const container = document.getElementById('wifi-detection-section');
    if (!container) return;

    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const hasProfile = data.matching_profile !== null;
    const canAutoStart = data.can_auto_start;

    container.classList.remove('hidden');

    let actionButton = '';
    if (hasProfile && canAutoStart) {
        actionButton = `
            <button onclick="autoStartFromProfile(${data.matching_profile.id})" 
                    class="px-4 py-2 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white font-medium transition-all flex items-center gap-2">
                <i data-lucide="zap" class="w-4 h-4"></i>
                ${t('wifi.auto_start')}
            </button>
        `;
    } else if (hasProfile) {
        actionButton = `
            <button onclick="showAddProfileModalWithSSID('${data.ssid}')" 
                    class="px-4 py-2 rounded-lg bg-primary-500 hover:bg-primary-600 text-white font-medium transition-all">
                ${t('wifi.edit_profile')}
            </button>
        `;
    } else {
        actionButton = `
            <button onclick="showAddProfileModalWithSSID('${data.ssid}')" 
                    class="px-4 py-2 rounded-lg bg-primary-500 hover:bg-primary-600 text-white font-medium transition-all flex items-center gap-2">
                <i data-lucide="plus" class="w-4 h-4"></i>
                ${t('wifi.create_profile')}
            </button>
        `;
    }

    container.innerHTML = `
        <div class="glass-card rounded-2xl p-6 border-l-4 ${hasProfile ? 'border-emerald-400' : 'border-primary-400'}">
            <div class="flex items-center justify-between">
                <div class="flex items-center gap-4">
                    <div class="w-12 h-12 rounded-xl ${hasProfile ? 'bg-emerald-100 dark:bg-emerald-900/30' : 'bg-primary-100 dark:bg-primary-900/30'} flex items-center justify-center">
                        <i data-lucide="wifi" class="w-6 h-6 ${hasProfile ? 'text-emerald-600' : 'text-primary-600'}"></i>
                    </div>
                    <div>
                        <h3 class="text-lg font-semibold text-surface-900 dark:text-white">
                            ${data.ssid}
                        </h3>
                        <p class="text-sm text-surface-500 dark:text-surface-400">
                            ${hasProfile
            ? `${t('wifi.profile_found')}: ${data.matching_profile.name}`
            : t('wifi.no_profile')}
                        </p>
                    </div>
                </div>
                <div class="flex items-center gap-3">
                    <button onclick="scanWifiNetworks()" class="p-2 rounded-lg hover:bg-surface-100 dark:hover:bg-surface-800 text-surface-500 transition-all" title="${t('wifi.scan')}">
                        <i data-lucide="refresh-cw" class="w-5 h-5"></i>
                    </button>
                    ${actionButton}
                </div>
            </div>
        </div>
    `;

    initIcons();
}

function hideWifiDetectionUI() {
    const container = document.getElementById('wifi-detection-section');
    if (container) {
        container.classList.add('hidden');
    }
}

async function scanWifiNetworks() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    showToast(t('wifi.scanning'), 'info');
    const data = await apiCall('/wifi/scan');

    if (data.success && data.data.length > 0) {
        showWifiScanModal(data.data);
    } else {
        showToast(t('wifi.no_networks'), 'warning');
    }
}

function showWifiScanModal(networks) {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    let modal = document.getElementById('wifi-scan-modal');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'wifi-scan-modal';
        modal.className = 'fixed inset-0 z-50 hidden items-center justify-center modal-backdrop';
        document.body.appendChild(modal);
    }

    const networksHtml = networks.map(net => `
        <div class="p-4 flex items-center justify-between hover:bg-surface-50 dark:hover:bg-surface-800/50 rounded-xl cursor-pointer transition-colors"
             onclick="selectWifiNetwork('${net.ssid}')">
            <div class="flex items-center gap-3">
                <i data-lucide="wifi" class="w-5 h-5 ${parseInt(net.rssi) > -60 ? 'text-emerald-500' : parseInt(net.rssi) > -75 ? 'text-amber-500' : 'text-rose-500'}"></i>
                <div>
                    <p class="font-medium text-surface-900 dark:text-white">${net.ssid}</p>
                    <p class="text-xs text-surface-500">Ch ${net.channel} • ${net.rssi} dBm</p>
                </div>
            </div>
            ${net.has_profile
            ? `<span class="px-2 py-1 rounded-full text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300">${t('profiles.title')}</span>`
            : '<i data-lucide="plus-circle" class="w-5 h-5 text-surface-400"></i>'}
        </div>
    `).join('');

    modal.innerHTML = `
        <div class="glass-card rounded-2xl w-full max-w-md mx-4 animate-slide-up max-h-[80vh] flex flex-col">
            <div class="p-6 border-b border-surface-200 dark:border-surface-700 flex items-center justify-between">
                <h3 class="text-xl font-bold text-surface-900 dark:text-white">${t('wifi.available_networks')}</h3>
                <button onclick="closeWifiScanModal()" class="p-2 rounded-lg hover:bg-surface-100 dark:hover:bg-surface-800">
                    <i data-lucide="x" class="w-5 h-5 text-surface-500"></i>
                </button>
            </div>
            <div class="p-4 overflow-y-auto space-y-2">
                ${networksHtml}
            </div>
        </div>
    `;

    modal.classList.remove('hidden');
    modal.classList.add('flex');
    initIcons();
}

function closeWifiScanModal() {
    const modal = document.getElementById('wifi-scan-modal');
    if (modal) {
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
}

function selectWifiNetwork(ssid) {
    closeWifiScanModal();
    showAddProfileModalWithSSID(ssid);
}

async function autoStartFromProfile(profileId) {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const profile = state.profiles.find(p => p.id === profileId);
    if (!profile) return;

    if (!state.password) {
        showToast(t('toast.password_required'), 'warning');
        showPage('dashboard');
        return;
    }

    const data = await apiCall('/start', {
        method: 'POST',
        body: JSON.stringify({
            profile_id: profileId,
            ttl: profile.ttl,
            mtu: profile.mtu
        })
    });

    if (data.success) {
        showToast(`${t('wifi.auto_start')}: ${profile.name}`, 'success');
        loadStatus();
        loadHistory();
    } else {
        showToast(data.error, 'error');
    }
}

// ==================== T005: Speed Test ====================

async function runSpeedTest() {
    if (state.isSpeedTesting) return;

    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    state.isSpeedTesting = true;
    const btn = document.getElementById('btn-speed-test');
    const originalContent = btn ? btn.innerHTML : '';

    if (btn) {
        btn.innerHTML = `
            <div class="w-5 h-5 border-2 border-white/30 border-t-white rounded-full spinner mr-2"></div>
            ${t('speed.running')}
        `;
        btn.disabled = true;
    }

    showToast(t('speed.running'), 'info');

    const data = await apiCall('/speed-test', { method: 'POST' });

    state.isSpeedTesting = false;
    if (btn) {
        btn.innerHTML = originalContent;
        btn.disabled = false;
    }

    if (data.success) {
        showToast(`${t('speed.download')}: ${data.download} Mbps`, 'success');
        state.speedTestHistory.push(data);
        renderSpeedTestHistory();
        updateSpeedChart();
    } else {
        showToast(data.error || t('speed.failed'), 'error');
    }
}

async function loadSpeedTestHistory() {
    const data = await apiCall('/speed-test/history');
    if (data.success) {
        state.speedTestHistory = data.data;
        renderSpeedTestHistory();
    }
}

function renderSpeedTestHistory() {
    const container = document.getElementById('speed-test-history');
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    if (!container) return;

    if (state.speedTestHistory.length === 0) {
        container.innerHTML = `
            <div class="text-center py-8 text-surface-500 dark:text-surface-400">
                <i data-lucide="gauge" class="w-12 h-12 mx-auto mb-3 opacity-50"></i>
                <p>${t('speed.no_tests')}</p>
            </div>
        `;
        initIcons();
        return;
    }

    const recentTests = state.speedTestHistory.slice(-5).reverse();

    container.innerHTML = recentTests.map(test => {
        const date = new Date(test.timestamp);
        const timeStr = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        return `
            <div class="flex items-center justify-between p-3 rounded-xl bg-surface-50 dark:bg-surface-800/50">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-lg bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center">
                        <i data-lucide="download" class="w-5 h-5 text-primary-600"></i>
                    </div>
                    <div>
                        <p class="font-medium text-surface-900 dark:text-white">${test.download} Mbps</p>
                        <p class="text-xs text-surface-500">${timeStr}</p>
                    </div>
                </div>
                ${test.upload > 0 ? `
                    <div class="text-right">
                        <p class="text-sm font-medium text-surface-700 dark:text-surface-300">↑ ${test.upload} Mbps</p>
                        <p class="text-xs text-surface-500">${test.ping} ms</p>
                    </div>
                ` : ''}
            </div>
        `;
    }).join('');

    initIcons();
}

function updateSpeedChart() {
    const chartContainer = document.getElementById('speed-chart');
    if (!chartContainer || state.speedTestHistory.length === 0) return;

    const recentTests = state.speedTestHistory.slice(-10);
    const maxSpeed = Math.max(...recentTests.map(t => t.download), 100);

    chartContainer.innerHTML = `
        <div class="flex items-end justify-between h-32 gap-2">
            ${recentTests.map(test => {
        const height = (test.download / maxSpeed) * 100;
        return `
                    <div class="flex-1 flex flex-col items-center gap-1">
                        <div class="w-full bg-primary-500/20 rounded-t-lg relative overflow-hidden" style="height: 100%;">
                            <div class="absolute bottom-0 w-full bg-primary-500 rounded-t-lg transition-all duration-500" style="height: ${height}%"></div>
                        </div>
                    </div>
                `;
    }).join('')}
        </div>
    `;
}

// ==================== T006: Session Statistics ====================

async function loadSessionStats() {
    const data = await apiCall('/stats');
    if (data.success) {
        state.sessionStats = data.data;
        renderSessionStats();
    }
}

function renderSessionStats() {
    if (!state.sessionStats) return;

    const stats = state.sessionStats;

    const totalSessionsEl = document.getElementById('stat-total-sessions');
    const totalTimeEl = document.getElementById('stat-total-time');
    const avgDurationEl = document.getElementById('stat-avg-duration');

    if (totalSessionsEl) {
        totalSessionsEl.textContent = stats.total_sessions || 0;
    }
    
    if (totalTimeEl) {
        // Support both formats: total_cloak_time_hours (from /api/stats) 
        // or total_cloak_time in seconds (from /api/status)
        let hours;
        if (stats.total_cloak_time_hours !== undefined) {
            hours = stats.total_cloak_time_hours;
        } else {
            const totalSeconds = stats.total_cloak_time || 0;
            hours = totalSeconds / 3600;
        }
        totalTimeEl.textContent = `${hours.toFixed(1)}h`;
    }
    
    if (avgDurationEl) {
        // Support both formats: avg_session_minutes (from /api/stats)
        // or calculate from total_cloak_time (from /api/status)
        let minutes;
        if (stats.avg_session_minutes !== undefined) {
            minutes = stats.avg_session_minutes;
        } else {
            const totalSeconds = stats.total_cloak_time || 0;
            const sessions = stats.total_sessions || 0;
            minutes = sessions > 0 ? Math.round(totalSeconds / sessions / 60) : 0;
        }
        avgDurationEl.textContent = `${Math.round(minutes)}m`;
    }

    renderUsageChart(stats.daily_usage || {});
}

function renderUsageChart(dailyUsage) {
    const container = document.getElementById('usage-chart');
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    if (!container) return;

    const dates = Object.keys(dailyUsage).sort().slice(-7);
    if (dates.length === 0) {
        container.innerHTML = `<p class="text-center text-surface-500 py-4">${t('stats.no_data')}</p>`;
        return;
    }

    const maxUsage = Math.max(...Object.values(dailyUsage), 3600);

    container.innerHTML = `
        <div class="flex items-end justify-between h-40 gap-3">
            ${dates.map(date => {
        const usage = dailyUsage[date] || 0;
        const hours = (usage / 3600).toFixed(1);
        const height = Math.max((usage / maxUsage) * 100, 5);
        const dayLabel = new Date(date).toLocaleDateString([], { weekday: 'short' });

        return `
                    <div class="flex-1 flex flex-col items-center gap-2">
                        <div class="w-full bg-gradient-to-t from-primary-600 to-primary-400 rounded-t-lg relative group cursor-pointer" style="height: ${height}%">
                            <div class="absolute -top-8 left-1/2 -translate-x-1/2 bg-surface-800 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                                ${hours}h
                            </div>
                        </div>
                        <span class="text-xs text-surface-500">${dayLabel}</span>
                    </div>
                `;
    }).join('')}
        </div>
    `;
}

// ==================== Existing Functions ====================

function updateStatusUI(ttl, mtu, isCloaked, hasPassword) {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    const ttlValue = document.getElementById('ttl-value');
    const ttlBadge = document.getElementById('ttl-badge');
    const ttlIcon = document.getElementById('ttl-icon');

    if (ttlValue) ttlValue.textContent = ttl;
    const isCloakedTTL = ttl === 65;

    if (ttlBadge) {
        ttlBadge.innerHTML = `
            <span class="w-1.5 h-1.5 rounded-full ${isCloakedTTL ? 'bg-emerald-500' : 'bg-surface-400'}"></span>
            <span>${isCloakedTTL ? (t('status.cloaked') || '偽裝中') : (t('status.normal') || '正常')}</span>
        `;
        ttlBadge.className = `inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium ${isCloakedTTL ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' : 'bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300'
            }`;
    }

    if (ttlIcon) {
        ttlIcon.innerHTML = `<i data-lucide="${isCloakedTTL ? 'activity' : 'radio'}" class="w-6 h-6 ${isCloakedTTL ? 'text-emerald-500' : 'text-surface-400'}"></i>`;
    }

    const mtuValue = document.getElementById('mtu-value');
    const mtuBadge = document.getElementById('mtu-badge');
    const mtuIcon = document.getElementById('mtu-icon');

    if (mtuValue) mtuValue.textContent = mtu;
    const isCloakedMTU = mtu === 1400;

    if (mtuBadge) {
        mtuBadge.innerHTML = `
            <span class="w-1.5 h-1.5 rounded-full ${isCloakedMTU ? 'bg-emerald-500' : 'bg-surface-400'}"></span>
            <span>${isCloakedMTU ? (t('status.cloaked') || '偽裝中') : (t('status.normal') || '正常')}</span>
        `;
        mtuBadge.className = `inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium ${isCloakedMTU ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' : 'bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300'
            }`;
    }

    if (mtuIcon) {
        mtuIcon.innerHTML = `<i data-lucide="${isCloakedMTU ? 'package' : 'box'}" class="w-6 h-6 ${isCloakedMTU ? 'text-emerald-500' : 'text-surface-400'}"></i>`;
    }

    const cloakStatus = document.getElementById('cloak-status');
    const cloakBadge = document.getElementById('cloak-badge');
    const cloakIcon = document.getElementById('cloak-icon');
    const cloakBg = document.getElementById('cloak-bg');

    if (cloakStatus) cloakStatus.textContent = isCloaked ? (t('status.cloaked') || '偽裝中') : (t('status.normal') || '正常');
    if (cloakBadge) {
        cloakBadge.innerHTML = `
            <span class="w-1.5 h-1.5 rounded-full ${isCloaked ? 'bg-white animate-pulse' : 'bg-surface-400'}"></span>
            <span>${isCloaked ? (t('status.active') || '已啟動') : (t('status.inactive') || '未啟動')}</span>
        `;
        cloakBadge.className = `inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium ${isCloaked ? 'bg-white/20 text-white' : 'bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300'
            }`;
    }

    if (cloakIcon) {
        cloakIcon.innerHTML = `<i data-lucide="${isCloaked ? 'shield-check' : 'shield'}" class="w-6 h-6 ${isCloaked ? 'text-white' : 'text-surface-400'}"></i>`;
    }

    if (cloakBg) {
        if (isCloaked) {
            cloakBg.classList.remove('opacity-0');
            cloakBg.classList.add('opacity-100');
        } else {
            cloakBg.classList.remove('opacity-100');
            cloakBg.classList.add('opacity-0');
        }
    }

    initIcons();

    if (hasPassword) {
        state.password = 'saved';
        updatePasswordUI(true);
    }
}

function updatePasswordUI(saved) {
    console.log('[DEBUG] updatePasswordUI() 被呼叫，saved=', saved);
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    const section = document.getElementById('password-section');
    const status = document.getElementById('password-status');
    const clearBtn = document.getElementById('btn-clear-pwd');
    const startBtn = document.getElementById('btn-start');
    const stopBtn = document.getElementById('btn-stop');
    
    console.log('[DEBUG] DOM 元素:', { section: !!section, status: !!status, clearBtn: !!clearBtn, startBtn: !!startBtn, stopBtn: !!stopBtn });

    if (saved) {
        console.log('[DEBUG] 設定 UI 為已儲存狀態，啟用按鈕');
        if (section) {
            section.classList.remove('border-amber-400');
            section.classList.add('border-emerald-400');
        }
        if (status) {
            const statusText = t('password.set') || '已設定';
            status.textContent = statusText;
            status.className = 'px-3 py-1 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300';
        }
        if (clearBtn) clearBtn.classList.remove('hidden');
        if (startBtn) {
            startBtn.disabled = false;
            console.log('[DEBUG] 啟動按鈕已啟用');
        }
        if (stopBtn) {
            stopBtn.disabled = false;
            console.log('[DEBUG] 停止按鈕已啟用');
        }
    } else {
        if (section) {
            section.classList.remove('border-emerald-400');
            section.classList.add('border-amber-400');
        }
        if (status) {
            const statusText = t('password.not_set') || '未設定';
            status.textContent = statusText;
            status.className = 'px-3 py-1 rounded-full text-xs font-medium bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300';
        }
        if (clearBtn) clearBtn.classList.add('hidden');
        if (startBtn) startBtn.disabled = true;
        if (stopBtn) stopBtn.disabled = true;
    }
}

function togglePasswordVisibility() {
    const input = document.getElementById('password-input');
    const eye = document.getElementById('password-eye');

    if (input.type === 'password') {
        input.type = 'text';
        eye.setAttribute('data-lucide', 'eye-off');
    } else {
        input.type = 'password';
        eye.setAttribute('data-lucide', 'eye');
    }
    initIcons();
}

async function savePassword() {
    console.log('[DEBUG] savePassword() 被呼叫');
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const input = document.getElementById('password-input');
    const password = input.value.trim();
    
    console.log('[DEBUG] 輸入的密碼長度:', password.length);

    if (!password) {
        console.log('[DEBUG] 密碼為空');
        showToast(t('password.error.empty') || '請輸入密碼', 'error');
        return;
    }

    console.log('[DEBUG] 呼叫 API /save-password');
    const data = await apiCall('/save-password', {
        method: 'POST',
        body: JSON.stringify({ password })
    });
    
    console.log('[DEBUG] API 回應:', data);

    if (data.success) {
        console.log('[DEBUG] 密碼儲存成功，更新 state 和 UI');
        state.password = password;
        console.log('[DEBUG] state.password 已設定:', state.password ? '有值' : '空');
        updatePasswordUI(true);
        showToast(t('password.success') || '密碼已儲存！', 'success');
        input.value = '';
    } else {
        console.log('[DEBUG] 密碼儲存失敗:', data.error);
        showToast(data.error || '密碼錯誤', 'error');
    }
}

async function clearPassword() {
    await apiCall('/clear-password', { method: 'POST' });
    state.password = null;
    updatePasswordUI(false);
    showToast('Password cleared');
}

async function startCloaking() {
    console.log('[DEBUG] startCloaking() 被呼叫');
    console.log('[DEBUG] state.password:', state.password ? '有值' : '空');
    
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    if (!state.password) {
        console.log('[DEBUG] 沒有密碼，無法啟動');
        showToast(t('toast.password_required') || '請先輸入並儲存密碼', 'warning');
        // 自動滾動到密碼輸入區域
        document.getElementById('password-section')?.scrollIntoView({ behavior: 'smooth' });
        return;
    }

    const btn = document.getElementById('btn-start');
    console.log('[DEBUG] 開始啟動偽裝流程');
    const originalText = btn.innerHTML;
    btn.innerHTML = `
        <div class="absolute inset-0 bg-gradient-to-br from-emerald-500 to-green-600"></div>
        <div class="relative z-10 flex items-center justify-center h-full">
            <div class="w-6 h-6 border-2 border-white/30 border-t-white rounded-full spinner mr-2"></div>
            <span>${t('control.starting') || '啟動中...'}</span>
        </div>
    `;
    btn.disabled = true;

    // 同步執行，等待結果
    console.log('[DEBUG] 呼叫 /api/start');
    const data = await apiCall('/start', { 
        method: 'POST',
        body: JSON.stringify({ ttl: 65, mtu: 1400 })
    });

    if (data.success) {
        showToast(data.message, 'success');
        loadStatus();
        loadHistory();
    } else {
        // 顯示詳細錯誤
        const errorMsg = data.error || '啟動失敗';
        showToast(errorMsg, 'error');
        
        // 如果是密碼錯誤，清除密碼並提示重新輸入
        if (errorMsg.includes('密碼') || errorMsg.includes('password')) {
            clearPassword();
            showToast('請重新輸入正確的系統管理員密碼', 'warning');
        }
    }

    resetStartButton();
}

async function stopCloaking() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    if (!state.password) {
        showToast(t('toast.password_required'), 'warning');
        return;
    }

    const btn = document.getElementById('btn-stop');
    btn.innerHTML = `
        <div class="absolute inset-0 bg-gradient-to-br from-rose-500 to-red-600"></div>
        <div class="relative z-10 flex items-center justify-center h-full">
            <div class="w-6 h-6 border-2 border-white/30 border-t-white rounded-full spinner mr-2"></div>
            <span>${t('control.stopping') || '停止中...'}</span>
        </div>
    `;
    btn.disabled = true;

    const data = await apiCall('/stop', { method: 'POST', body: JSON.stringify({}) });

    if (data.success) {
        showToast(data.message, 'success');
        loadStatus();
        loadHistory();
        loadSessionStats();
    } else {
        showToast(data.error, 'error');
        // 檢查是否是密碼錯誤（支援中英文）
        if (data.error && (data.error.includes('password') || data.error.includes('密碼'))) {
            clearPassword();
        }
    }

    resetStopButton();
}

function resetStartButton() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const btn = document.getElementById('btn-start');
    btn.innerHTML = `
        <div class="absolute inset-0 bg-gradient-to-br from-emerald-500 to-green-600 transition-transform group-hover:scale-105"></div>
        <div class="relative z-10">
            <div class="flex items-center justify-between mb-3">
                <div class="w-12 h-12 rounded-xl bg-white/20 flex items-center justify-center">
                    <i data-lucide="power" class="w-6 h-6 text-white"></i>
                </div>
                <i data-lucide="arrow-right" class="w-5 h-5 text-white/70 group-hover:translate-x-1 transition-transform"></i>
            </div>
            <h3 class="text-xl font-bold text-white mb-1">${t('control.start') || '啟動偽裝'}</h3>
            <p class="text-green-100 text-sm">${t('control.start.subtitle') || '修改 TTL/MTU 模擬手機流量'}</p>
        </div>
    `;
    btn.disabled = false;
    initIcons();
}

function resetStopButton() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const btn = document.getElementById('btn-stop');
    btn.innerHTML = `
        <div class="absolute inset-0 bg-gradient-to-br from-rose-500 to-red-600 transition-transform group-hover:scale-105"></div>
        <div class="relative z-10">
            <div class="flex items-center justify-between mb-3">
                <div class="w-12 h-12 rounded-xl bg-white/20 flex items-center justify-center">
                    <i data-lucide="square" class="w-6 h-6 text-white"></i>
                </div>
                <i data-lucide="arrow-right" class="w-5 h-5 text-white/70 group-hover:translate-x-1 transition-transform"></i>
            </div>
            <h3 class="text-xl font-bold text-white mb-1">${t('control.stop') || '停止偽裝'}</h3>
            <p class="text-red-100 text-sm">${t('control.stop.subtitle') || '還原 TTL/MTU 到預設值'}</p>
        </div>
    `;
    btn.disabled = false;
    initIcons();
}

// Profile Management
async function loadProfiles() {
    const data = await apiCall('/profiles');

    if (data.success) {
        state.profiles = data.data;
        renderProfiles();
    }
}

function renderProfiles() {
    const container = document.getElementById('profiles-list');
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    if (state.profiles.length === 0) {
        container.innerHTML = `
            <div class="p-12 text-center">
                <div class="w-16 h-16 rounded-2xl bg-surface-100 dark:bg-surface-800 flex items-center justify-center mx-auto mb-4">
                    <i data-lucide="inbox" class="w-8 h-8 text-surface-400"></i>
                </div>
                <h4 class="text-lg font-medium text-surface-900 dark:text-white mb-2" data-i18n="profiles.empty">No Profiles</h4>
                <p class="text-sm text-surface-500 dark:text-surface-400" data-i18n="profiles.empty_hint">Click "Add Profile" to create your first configuration</p>
            </div>
        `;
        initIcons();
        return;
    }

    container.innerHTML = state.profiles.map(profile => `
        <div class="p-4 flex items-center justify-between hover:bg-surface-50 dark:hover:bg-surface-800/50 transition-colors group">
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-primary-500 to-purple-600 flex items-center justify-center">
                    <i data-lucide="wifi" class="w-6 h-6 text-white"></i>
                </div>
                <div>
                    <h4 class="font-medium text-surface-900 dark:text-white">${profile.name}</h4>
                    <p class="text-sm text-surface-500 dark:text-surface-400">
                        ${profile.ssid} • TTL: ${profile.ttl} • MTU: ${profile.mtu}
                        ${profile.auto_start ? `<span class="ml-2 text-primary-500">• ${t('profiles.auto_start')}</span>` : ''}
                    </p>
                </div>
            </div>
            <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <button onclick="editProfile(${profile.id})" class="p-2 rounded-lg hover:bg-surface-100 dark:hover:bg-surface-800 text-surface-500 hover:text-primary-600 transition-colors" title="${t('common.edit')}">
                    <i data-lucide="pencil" class="w-4 h-4"></i>
                </button>
                <button onclick="deleteProfile(${profile.id})" class="p-2 rounded-lg hover:bg-rose-100 dark:hover:bg-rose-900/30 text-surface-500 hover:text-rose-600 transition-colors" title="${t('common.delete')}">
                    <i data-lucide="trash-2" class="w-4 h-4"></i>
                </button>
            </div>
        </div>
    `).join('');

    initIcons();
}

function showAddProfileModal() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    document.getElementById('modal-title').textContent = t('profiles.add');
    document.getElementById('profile-id').value = '';
    document.getElementById('profile-name').value = '';
    document.getElementById('profile-ssid').value = '';
    document.getElementById('profile-ttl').value = '65';
    document.getElementById('profile-mtu').value = '1400';
    document.getElementById('profile-auto').checked = false;
    showModal();
}

function showAddProfileModalWithSSID(ssid) {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    document.getElementById('modal-title').textContent = t('profiles.add');
    document.getElementById('profile-id').value = '';
    document.getElementById('profile-name').value = ssid;
    document.getElementById('profile-ssid').value = ssid;
    document.getElementById('profile-ttl').value = '65';
    document.getElementById('profile-mtu').value = '1400';
    document.getElementById('profile-auto').checked = true;
    showModal();
}

function editProfile(id) {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const profile = state.profiles.find(p => p.id === id);
    if (!profile) return;

    document.getElementById('modal-title').textContent = t('profiles.edit');
    document.getElementById('profile-id').value = profile.id;
    document.getElementById('profile-name').value = profile.name;
    document.getElementById('profile-ssid').value = profile.ssid;
    document.getElementById('profile-ttl').value = profile.ttl;
    document.getElementById('profile-mtu').value = profile.mtu;
    document.getElementById('profile-auto').checked = profile.auto_start;
    showModal();
}

function showModal() {
    const modal = document.getElementById('profile-modal');
    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

function closeModal() {
    const modal = document.getElementById('profile-modal');
    modal.classList.add('hidden');
    modal.classList.remove('flex');
}

function setupModalClose() {
    const modal = document.getElementById('profile-modal');
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeModal();
        }
    });

    // Traffic rule modal close on backdrop click
    const trafficModal = document.getElementById('traffic-rule-modal');
    if (trafficModal) {
        trafficModal.addEventListener('click', (e) => {
            if (e.target === trafficModal) {
                closeTrafficModal();
            }
        });
    }
}

async function saveProfile() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    const id = document.getElementById('profile-id').value;
    const profile = {
        name: document.getElementById('profile-name').value,
        ssid: document.getElementById('profile-ssid').value,
        ttl: parseInt(document.getElementById('profile-ttl').value),
        mtu: parseInt(document.getElementById('profile-mtu').value),
        auto_start: document.getElementById('profile-auto').checked
    };

    if (!profile.name || !profile.ssid) {
        showToast(t('toast.fill_required'), 'error');
        return;
    }

    const endpoint = id ? `/profiles/${id}` : '/profiles';
    const method = id ? 'PUT' : 'POST';

    const data = await apiCall(endpoint, {
        method,
        body: JSON.stringify(profile)
    });

    if (data.success) {
        showToast(id ? t('profiles.updated') : t('profiles.created'), 'success');
        closeModal();
        loadProfiles();
        detectWifi();
    } else {
        showToast(data.error, 'error');
    }
}

async function deleteProfile(id) {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    if (!confirm(t('profiles.delete_confirm'))) return;

    const data = await apiCall(`/profiles/${id}`, { method: 'DELETE' });

    if (data.success) {
        showToast(t('profiles.deleted'), 'success');
        loadProfiles();
        detectWifi();
    }
}

// History Management
async function loadHistory() {
    const data = await apiCall('/history');

    if (data.success) {
        state.history = data.data;
        renderHistory();
    }
}

function renderHistory() {
    const container = document.getElementById('history-list');
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;

    if (state.history.length === 0) {
        container.innerHTML = `
            <div class="p-12 text-center">
                <div class="w-16 h-16 rounded-2xl bg-surface-100 dark:bg-surface-800 flex items-center justify-center mx-auto mb-4">
                    <i data-lucide="history" class="w-8 h-8 text-surface-400"></i>
                </div>
                <h4 class="text-lg font-medium text-surface-900 dark:text-white mb-2" data-i18n="history.empty">No History</h4>
                <p class="text-sm text-surface-500 dark:text-surface-400" data-i18n="history.empty_hint">Your operations will appear here</p>
            </div>
        `;
        initIcons();
        return;
    }

    const dateFormat = typeof i18n !== 'undefined' && i18n.currentLang === 'zh-TW' ? 'zh-TW' : 'en-US';

    container.innerHTML = state.history.slice().reverse().map(item => {
        const date = new Date(item.timestamp);
        const timeStr = date.toLocaleString(dateFormat);
        const isStart = item.action === 'start_cloaking';
        const duration = item.details?.duration_seconds;

        return `
            <div class="p-4 flex items-center justify-between hover:bg-surface-50 dark:hover:bg-surface-800/50 transition-colors">
                <div class="flex items-center gap-4">
                    <div class="w-10 h-10 rounded-lg ${isStart ? 'bg-emerald-100 dark:bg-emerald-900/30' : 'bg-rose-100 dark:bg-rose-900/30'} flex items-center justify-center">
                        <i data-lucide="${isStart ? 'power' : 'square'}" class="w-5 h-5 ${isStart ? 'text-emerald-600' : 'text-rose-600'}"></i>
                    </div>
                    <div>
                        <p class="font-medium text-surface-900 dark:text-white">
                            ${isStart ? t('history.action.start') : t('history.action.stop')}
                            ${duration ? `<span class="text-sm text-surface-500">(${Math.round(duration / 60)}m)</span>` : ''}
                        </p>
                        <p class="text-sm text-surface-500 dark:text-surface-400">${timeStr}</p>
                    </div>
                </div>
                <span class="px-3 py-1 rounded-full text-xs font-medium ${item.success
                ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300'
                : 'bg-rose-100 dark:bg-rose-900/30 text-rose-700 dark:text-rose-300'
            }">
                    ${item.success ? t('history.status.success') : t('history.status.failed')}
                </span>
            </div>
        `;
    }).join('');

    initIcons();
}

async function clearHistory() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    if (!confirm(t('history.clear_confirm'))) return;

    state.history = [];
    renderHistory();
    showToast(t('history.cleared'), 'success');
}

// Settings
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
        detectWifi();
    }, 5000);
}

function stopAutoRefresh() {
    if (state.refreshInterval) {
        clearInterval(state.refreshInterval);
        state.refreshInterval = null;
    }
}

function refreshAll() {
    const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
    loadStatus();
    loadProfiles();
    loadHistory();
    loadSpeedTestHistory();
    loadSessionStats();
    detectWifi();
    loadPhase3Settings();
    showToast(t('toast.refresh'), 'success');
}

async function loadStatus() {
    const data = await apiCall('/status');

    if (data.success) {
        const { ttl, mtu, is_cloaked, has_password, dns_servers } = data.data;
        updateStatusUI(ttl, mtu, is_cloaked, has_password);
        // Note: session_stats is loaded separately by loadSessionStats() to get calculated values
        // Update current DNS display
        if (dns_servers && dns_servers.length > 0) {
            const dnsContainer = document.getElementById('current-dns-servers');
            if (dnsContainer) {
                dnsContainer.innerHTML = dns_servers.map(s =>
                    `<span class="px-2 py-1 rounded-lg bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-400 text-sm">${s}</span>`
                ).join('');
            }
        }
    }
}
