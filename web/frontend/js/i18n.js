/**
 * TetherFlow - Internationalization (i18n) Module
 * Supports English and Traditional Chinese
 */

const i18n = {
    // Current language
    currentLang: localStorage.getItem('language') || 'zh-TW',

    // Translations
    translations: {
        'zh-TW': {
            // Navigation
            'nav.dashboard': '儀表板',
            'nav.profiles': 'Wi-Fi 配置',
            'nav.history': '操作歷史',
            'nav.settings': '設定',

            // Page Titles
            'page.dashboard.title': '儀表板',
            'page.dashboard.subtitle': '管理您的網路偽裝設定',
            'page.profiles.title': 'Wi-Fi 配置',
            'page.profiles.subtitle': '管理您的熱點設定檔',
            'page.history.title': '操作歷史',
            'page.history.subtitle': '檢視您的操作記錄',
            'page.settings.title': '設定',
            'page.settings.subtitle': '調整系統偏好',

            // Status Cards
            'status.ttl': 'TTL 值',
            'status.mtu': 'MTU 值',
            'status.cloak': '偽裝狀態',
            'status.cloaked': '偽裝中',
            'status.normal': '正常模式',
            'status.checking': '檢測中...',
            'status.active': '已啟動',
            'status.inactive': '未啟動',

            // Password Section
            'password.title': '管理員密碼',
            'password.subtitle': '修改網路設定需要密碼',
            'password.description': '為了修改系統網路設定，需要您的 Mac 登入密碼。密碼僅儲存在記憶體中，不會儲存到硬碟。',
            'password.placeholder': '輸入您的 Mac 密碼...',
            'password.save': '儲存密碼',
            'password.clear': '清除密碼',
            'password.set': '已設定',
            'password.not_set': '未設定',
            'password.error.empty': '請輸入密碼',
            'password.success': '密碼已儲存！現在可以控制偽裝',
            'password.cleared': '密碼已清除',

            // Control Buttons
            'control.start': '啟動偽裝',
            'control.start.subtitle': '設定 TTL=65, MTU=1400',
            'control.stop': '停止偽裝',
            'control.stop.subtitle': '還原 TTL=64, MTU=1500',
            'control.starting': '啟動中...',
            'control.stopping': '停止中...',

            // Profiles
            'profiles.title': 'Wi-Fi 配置',
            'profiles.subtitle': '管理您的熱點設定',
            'profiles.add': '新增配置',
            'profiles.edit': '編輯配置',
            'profiles.empty': '尚無配置',
            'profiles.empty_hint': '點擊「新增配置」建立您的第一個設定',
            'profiles.name': '名稱',
            'profiles.ssid': 'Wi-Fi SSID',
            'profiles.ttl': 'TTL',
            'profiles.mtu': 'MTU',
            'profiles.auto_start': '連線時自動啟動偽裝',
            'profiles.save': '儲存配置',
            'profiles.cancel': '取消',
            'profiles.delete': '刪除',
            'profiles.delete_confirm': '確定要刪除這個配置嗎？',
            'profiles.created': '配置已建立',
            'profiles.updated': '配置已更新',
            'profiles.deleted': '配置已刪除',

            // History
            'history.title': '操作歷史',
            'history.subtitle': '追蹤您的偽裝活動',
            'history.clear': '清空歷史',
            'history.clear_confirm': '確定要清空所有歷史記錄嗎？',
            'history.empty': '尚無操作記錄',
            'history.empty_hint': '您的操作將顯示在這裡',
            'history.action.start': '啟動偽裝',
            'history.action.stop': '停止偽裝',
            'history.status.success': '成功',
            'history.status.failed': '失敗',
            'history.cleared': '歷史已清空',

            // Settings
            'settings.general': '一般設定',
            'settings.auto_refresh': '自動重新整理',
            'settings.auto_refresh_desc': '每 5 秒自動更新狀態',
            'settings.dark_mode': '深色模式',
            'settings.dark_mode_desc': '切換深色主題',
            'settings.language': '語言',
            'settings.language_desc': '切換介面語言',
            'settings.about': '關於',
            'settings.version': '版本',
            'settings.description': '適用於 macOS 的網路偽裝工具',
            'settings.feature1': '即時 TTL/MTU 監控',
            'settings.feature2': '一鍵啟動/停止偽裝',
            'settings.feature3': '配置管理系統',
            'settings.feature4': '現代化響應式介面',

            // Toast Messages
            'toast.refresh': '已重新整理',
            'toast.network_error': '網路連線失敗',
            'toast.password_required': '請先儲存密碼',
            'toast.fill_required': '請填寫必填欄位',
            'toast.network_error_cloaking': '網路連線不穩定，正在確認偽裝狀態...',

            // Session Statistics (T006)
            'stats.title': '會話統計',
            'stats.subtitle': '您的偽裝活動概覽',
            'stats.total_sessions': '總會話數',
            'stats.total_time': '總時間',
            'stats.avg_duration': '平均時長',
            'stats.daily_usage': '每日使用（最近 7 天）',
            'stats.no_data': '尚無使用資料',

            // Speed Test (T005)
            'speed.title': '速度測試',
            'speed.subtitle': '檢查您的網路效能',
            'speed.run': '執行測試',
            'speed.running': '測試中...',
            'speed.no_tests': '尚無速度測試記錄',
            'speed.download': '下載',
            'speed.upload': '上傳',
            'speed.ping': '延遲',
            'speed.failed': '速度測試失敗',

            // Quick Actions
            'quick_actions.title': '快捷操作',
            'quick_actions.subtitle': '常用控制項目',
            'quick_actions.manage_profiles': '管理配置',
            'quick_actions.view_history': '檢視歷史',
            'quick_actions.scan_networks': '掃描網路',

            // Wi-Fi Detection (T004)
            'wifi.current': '目前 Wi-Fi',
            'wifi.not_connected': '未連線',
            'wifi.scan': '掃描網路',
            'wifi.available_networks': '可用網路',
            'wifi.profile_found': '找到配置',
            'wifi.no_profile': '尚無配置',
            'wifi.create_profile': '建立配置',
            'wifi.edit_profile': '編輯配置',
            'wifi.auto_start': '自動啟動',
            'wifi.signal_excellent': '訊號極佳',
            'wifi.signal_good': '訊號良好',
            'wifi.signal_fair': '訊號尚可',
            'wifi.signal_weak': '訊號微弱',
            'wifi.scanning': '正在掃描 Wi-Fi 網路...',
            'wifi.no_networks': '找不到 Wi-Fi 網路',

            // T007: Wi-Fi Auto-Detection
            'autodetect.title': 'Wi-Fi 自動偵測',
            'autodetect.subtitle': '自動監控並啟動偽裝',
            'autodetect.enable': '啟用自動偵測',
            'autodetect.enabled': '已啟用',
            'autodetect.disabled': '已停用',
            'autodetect.status': '監控狀態',
            'autodetect.active': '監控中',
            'autodetect.inactive': '未監控',
            'autodetect.auto_start': '連線時自動啟動',
            'autodetect.notification': '連線時顯示通知',

            // T008: DNS Settings
            'dns.title': 'DNS 設定',
            'dns.subtitle': '使用加密 DNS (DoH/DoT) 保護隱私',
            'dns.enable': '啟用加密 DNS',
            'dns.enabled': '已啟用',
            'dns.disabled': '已停用',
            'dns.provider': 'DNS 提供者',
            'dns.custom': '自訂 DNS',
            'dns.current_servers': '目前 DNS 伺服器',
            'dns.apply': '套用 DNS 設定',
            'dns.applied': 'DNS 設定已套用',
            'dns.cloudflare': 'Cloudflare',
            'dns.cloudflare_family': 'Cloudflare (Family)',
            'dns.google': 'Google DNS',
            'dns.quad9': 'Quad9',
            'dns.opendns': 'OpenDNS',
            'dns.servers': 'DNS 伺服器',

            // T009: Traffic Shaping
            'traffic.title': '流量整形',
            'traffic.subtitle': '控制背景應用程式網路使用',
            'traffic.enable': '啟用流量整形',
            'traffic.enabled': '已啟用',
            'traffic.disabled': '已停用',
            'traffic.rules': '流量規則',
            'traffic.add_rule': '新增規則',
            'traffic.rule_name': '規則名稱',
            'traffic.port': '連接埠',
            'traffic.protocol': '協定',
            'traffic.bandwidth': '頻寬限制 (Kbps)',
            'traffic.tcp': 'TCP',
            'traffic.udp': 'UDP',
            'traffic.no_rules': '尚無流量規則',
            'traffic.delete_confirm': '確定要刪除此規則嗎？',

            // T010: System Integration
            'system.title': '系統整合',
            'system.subtitle': '進階系統設定',
            'system.auto_launch': '開機自動啟動',
            'system.auto_launch_desc': '系統啟動時自動執行 TetherFlow',
            'system.menubar': '選單列圖示',
            'system.menubar_desc': '在選單列顯示 TetherFlow 圖示',
            'system.shortcut': '全域快捷鍵',
            'system.shortcut_desc': '快速啟動/停止偽裝',
            'system.current_shortcut': '目前快捷鍵',
            'system.press_key': '按下按鍵組合...',

            // Common
            'common.save': '儲存',
            'common.cancel': '取消',
            'common.delete': '刪除',
            'common.edit': '編輯',
            'common.close': '關閉',
            'common.refresh': '重新整理',
            'common.loading': '載入中...',
            'common.yes': '是',
            'common.no': '否',
            'common.confirm': '確認',
        },

        'en': {
            // Navigation
            'nav.dashboard': 'Dashboard',
            'nav.profiles': 'Wi-Fi Profiles',
            'nav.history': 'History',
            'nav.settings': 'Settings',

            // Page Titles
            'page.dashboard.title': 'Dashboard',
            'page.dashboard.subtitle': 'Manage your network cloaking settings',
            'page.profiles.title': 'Wi-Fi Profiles',
            'page.profiles.subtitle': 'Manage your hotspot configurations',
            'page.history.title': 'History',
            'page.history.subtitle': 'Track your cloaking activities',
            'page.settings.title': 'Settings',
            'page.settings.subtitle': 'Adjust system preferences',

            // Status Cards
            'status.ttl': 'TTL Value',
            'status.mtu': 'MTU Value',
            'status.cloak': 'Cloak Status',
            'status.cloaked': 'Cloaked',
            'status.normal': 'Normal',
            'status.checking': 'Checking...',
            'status.active': 'Active',
            'status.inactive': 'Inactive',

            // Password Section
            'password.title': 'Admin Password',
            'password.subtitle': 'Required for network modifications',
            'password.description': 'To modify system network settings, your Mac login password is required. Password is stored in memory only and never saved to disk.',
            'password.placeholder': 'Enter your Mac password...',
            'password.save': 'Save Password',
            'password.clear': 'Clear Password',
            'password.set': 'Set',
            'password.not_set': 'Not Set',
            'password.error.empty': 'Please enter your password',
            'password.success': 'Password saved! You can now control cloaking',
            'password.cleared': 'Password cleared',

            // Control Buttons
            'control.start': 'Start Cloaking',
            'control.start.subtitle': 'Set TTL=65, MTU=1400',
            'control.stop': 'Stop Cloaking',
            'control.stop.subtitle': 'Reset TTL=64, MTU=1500',
            'control.starting': 'Starting...',
            'control.stopping': 'Stopping...',

            // Profiles
            'profiles.title': 'Wi-Fi Profiles',
            'profiles.subtitle': 'Manage your hotspot settings',
            'profiles.add': 'Add Profile',
            'profiles.edit': 'Edit Profile',
            'profiles.empty': 'No Profiles',
            'profiles.empty_hint': 'Click "Add Profile" to create your first configuration',
            'profiles.name': 'Name',
            'profiles.ssid': 'Wi-Fi SSID',
            'profiles.ttl': 'TTL',
            'profiles.mtu': 'MTU',
            'profiles.auto_start': 'Auto-start cloaking on connection',
            'profiles.save': 'Save Profile',
            'profiles.cancel': 'Cancel',
            'profiles.delete': 'Delete',
            'profiles.delete_confirm': 'Are you sure you want to delete this profile?',
            'profiles.created': 'Profile created',
            'profiles.updated': 'Profile updated',
            'profiles.deleted': 'Profile deleted',

            // History
            'history.title': 'Operation History',
            'history.subtitle': 'Track your cloaking activities',
            'history.clear': 'Clear History',
            'history.clear_confirm': 'Are you sure you want to clear all history?',
            'history.empty': 'No history yet',
            'history.empty_hint': 'Your operations will appear here',
            'history.action.start': 'Start Cloaking',
            'history.action.stop': 'Stop Cloaking',
            'history.status.success': 'Success',
            'history.status.failed': 'Failed',
            'history.cleared': 'History cleared',

            // Settings
            'settings.general': 'General Settings',
            'settings.auto_refresh': 'Auto Refresh',
            'settings.auto_refresh_desc': 'Update status every 5 seconds',
            'settings.dark_mode': 'Dark Mode',
            'settings.dark_mode_desc': 'Toggle dark theme',
            'settings.language': 'Language',
            'settings.language_desc': 'Switch interface language',
            'settings.about': 'About',
            'settings.version': 'Version',
            'settings.description': 'Network cloaking utility for macOS',
            'settings.feature1': 'Real-time TTL/MTU monitoring',
            'settings.feature2': 'One-click start/stop cloaking',
            'settings.feature3': 'Profile management system',
            'settings.feature4': 'Modern responsive interface',

            // Toast Messages
            'toast.refresh': 'Refreshed',
            'toast.network_error': 'Network connection failed',
            'toast.password_required': 'Please save your password first',
            'toast.fill_required': 'Please fill in all required fields',
            'toast.network_error_cloaking': 'Network unstable, verifying cloaking status...',

            // Session Statistics (T006)
            'stats.title': 'Session Statistics',
            'stats.subtitle': 'Your cloaking activity overview',
            'stats.total_sessions': 'Total Sessions',
            'stats.total_time': 'Total Time',
            'stats.avg_duration': 'Avg Duration',
            'stats.daily_usage': 'Daily Usage (Last 7 Days)',
            'stats.no_data': 'No usage data yet',

            // Speed Test (T005)
            'speed.title': 'Speed Test',
            'speed.subtitle': 'Check your network performance',
            'speed.run': 'Run Test',
            'speed.running': 'Testing...',
            'speed.no_tests': 'No speed tests yet',
            'speed.download': 'Download',
            'speed.upload': 'Upload',
            'speed.ping': 'Ping',
            'speed.failed': 'Speed test failed',

            // Quick Actions
            'quick_actions.title': 'Quick Actions',
            'quick_actions.subtitle': 'Frequently used controls',
            'quick_actions.manage_profiles': 'Manage Profiles',
            'quick_actions.view_history': 'View History',
            'quick_actions.scan_networks': 'Scan Networks',

            // Wi-Fi Detection (T004)
            'wifi.current': 'Current Wi-Fi',
            'wifi.not_connected': 'Not Connected',
            'wifi.scan': 'Scan Networks',
            'wifi.available_networks': 'Available Networks',
            'wifi.profile_found': 'Profile Found',
            'wifi.no_profile': 'No Profile',
            'wifi.create_profile': 'Create Profile',
            'wifi.edit_profile': 'Edit Profile',
            'wifi.auto_start': 'Auto Start',
            'wifi.signal_excellent': 'Excellent',
            'wifi.signal_good': 'Good',
            'wifi.signal_fair': 'Fair',
            'wifi.signal_weak': 'Weak',
            'wifi.scanning': 'Scanning Wi-Fi networks...',
            'wifi.no_networks': 'No Wi-Fi networks found',

            // T007: Wi-Fi Auto-Detection
            'autodetect.title': 'Wi-Fi Auto-Detection',
            'autodetect.subtitle': 'Auto-monitor and start cloaking',
            'autodetect.enable': 'Enable Auto-Detection',
            'autodetect.enabled': 'Enabled',
            'autodetect.disabled': 'Disabled',
            'autodetect.status': 'Monitor Status',
            'autodetect.active': 'Active',
            'autodetect.inactive': 'Inactive',
            'autodetect.auto_start': 'Auto-start on connection',
            'autodetect.notification': 'Show notification on connect',

            // T008: DNS Settings
            'dns.title': 'DNS Settings',
            'dns.subtitle': 'Use encrypted DNS (DoH/DoT) for privacy',
            'dns.enable': 'Enable Encrypted DNS',
            'dns.enabled': 'Enabled',
            'dns.disabled': 'Disabled',
            'dns.provider': 'DNS Provider',
            'dns.custom': 'Custom DNS',
            'dns.current_servers': 'Current DNS Servers',
            'dns.apply': 'Apply DNS Settings',
            'dns.applied': 'DNS settings applied',
            'dns.cloudflare': 'Cloudflare',
            'dns.cloudflare_family': 'Cloudflare (Family)',
            'dns.google': 'Google DNS',
            'dns.quad9': 'Quad9',
            'dns.opendns': 'OpenDNS',
            'dns.servers': 'DNS Servers',

            // T009: Traffic Shaping
            'traffic.title': 'Traffic Shaping',
            'traffic.subtitle': 'Control background app network usage',
            'traffic.enable': 'Enable Traffic Shaping',
            'traffic.enabled': 'Enabled',
            'traffic.disabled': 'Disabled',
            'traffic.rules': 'Traffic Rules',
            'traffic.add_rule': 'Add Rule',
            'traffic.rule_name': 'Rule Name',
            'traffic.port': 'Port',
            'traffic.protocol': 'Protocol',
            'traffic.bandwidth': 'Bandwidth Limit (Kbps)',
            'traffic.tcp': 'TCP',
            'traffic.udp': 'UDP',
            'traffic.no_rules': 'No traffic rules yet',
            'traffic.delete_confirm': 'Are you sure you want to delete this rule?',

            // T010: System Integration
            'system.title': 'System Integration',
            'system.subtitle': 'Advanced system settings',
            'system.auto_launch': 'Auto-launch on startup',
            'system.auto_launch_desc': 'Start TetherFlow automatically on login',
            'system.menubar': 'Menu Bar Icon',
            'system.menubar_desc': 'Show TetherFlow icon in menu bar',
            'system.shortcut': 'Global Shortcut',
            'system.shortcut_desc': 'Quick start/stop cloaking',
            'system.current_shortcut': 'Current Shortcut',
            'system.press_key': 'Press key combination...',

            // Common
            'common.save': 'Save',
            'common.cancel': 'Cancel',
            'common.delete': 'Delete',
            'common.edit': 'Edit',
            'common.close': 'Close',
            'common.refresh': 'Refresh',
            'common.loading': 'Loading...',
            'common.yes': 'Yes',
            'common.no': 'No',
            'common.confirm': 'Confirm',
        }
    },

    // Initialize
    init() {
        this.updatePageLanguage();
        this.updateLanguageToggle();
    },

    // Get translation
    t(key) {
        const translation = this.translations[this.currentLang][key];
        return translation || key;
    },

    // Switch language
    switchLanguage(lang) {
        if (this.translations[lang]) {
            this.currentLang = lang;
            localStorage.setItem('language', lang);

            // Update all static i18n elements
            this.updatePageLanguage();

            // Update page title
            const currentPage = document.querySelector('.nav-active')?.dataset.page || 'dashboard';
            const pageTitle = document.getElementById('page-title');
            if (pageTitle) {
                pageTitle.textContent = this.t(`page.${currentPage}.title`);
            }

            // Update page subtitle
            const headerSubtitle = document.getElementById('page-subtitle');
            if (headerSubtitle) {
                headerSubtitle.textContent = this.t(`page.${currentPage}.subtitle`);
            }

            // Update navigation active state text
            document.querySelectorAll('.nav-item').forEach(item => {
                const page = item.dataset.page;
                const span = item.querySelector('span[data-i18n]');
                if (span && page) {
                    span.textContent = this.t(`nav.${page}`);
                }
            });

            // Update refresh button text
            const refreshBtn = document.querySelector('button[onclick="refreshAll()"] span[data-i18n]');
            if (refreshBtn) {
                refreshBtn.textContent = this.t('common.refresh');
            }

            // Update language toggle button
            this.updateLanguageToggle();

            // Re-render dynamic content
            if (typeof renderProfiles === 'function') renderProfiles();
            if (typeof renderHistory === 'function') renderHistory();
            if (typeof loadStatus === 'function') loadStatus();

            return true;
        }
        return false;
    },

    // Toggle between languages
    toggle() {
        const newLang = this.currentLang === 'zh-TW' ? 'en' : 'zh-TW';
        this.switchLanguage(newLang);
    },

    // Update all elements with data-i18n attribute
    updatePageLanguage() {
        document.querySelectorAll('[data-i18n]').forEach(element => {
            const key = element.getAttribute('data-i18n');
            const translation = this.t(key);

            // Skip elements that should keep their dynamic content (like #modal-title, #page-title)
            if (element.id === 'modal-title' || element.id === 'page-title') {
                return;
            }

            if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
                if (element.hasAttribute('placeholder')) {
                    element.placeholder = translation;
                } else {
                    element.value = translation;
                }
            } else {
                element.textContent = translation;
            }
        });

        // Update page subtitle
        const pageSubtitle = document.querySelector('#page-' + (document.querySelector('.nav-active')?.dataset.page || 'dashboard'))?.previousElementSibling;
        if (pageSubtitle && pageSubtitle.tagName === 'P') {
            const currentPage = document.querySelector('.nav-active')?.dataset.page || 'dashboard';
            pageSubtitle.textContent = this.t(`page.${currentPage}.subtitle`);
        }
    },

    // Update language toggle button state
    updateLanguageToggle() {
        const langToggle = document.getElementById('language-toggle');
        if (langToggle) {
            langToggle.textContent = this.currentLang === 'zh-TW' ? 'EN' : '中文';
            langToggle.title = this.currentLang === 'zh-TW' ? 'Switch to English' : '切換至中文';
        }
    }
};

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    i18n.init();
});
