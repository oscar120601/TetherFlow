#!/usr/bin/env python3
#
# TetherFlow Web Server with UI Password Input
# 瀏覽器版控制介面 - 支援 UI 輸入密碼
#

import http.server
import socketserver
import subprocess
import json
import os
import sys
from urllib.parse import urlparse, parse_qs

PORT = 8082

HTML_PAGE = """
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TetherFlow - 網路偽裝控制面板</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 500px;
            width: 100%;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        
        .header p {
            color: #666;
            font-size: 1.1em;
        }
        
        .status-card {
            background: #f8f9fa;
            border-radius: 15px;
            padding: 25px;
            margin-bottom: 25px;
        }
        
        .status-title {
            font-size: 1.2em;
            font-weight: 600;
            margin-bottom: 15px;
            color: #333;
        }
        
        .status-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .status-item:last-child {
            border-bottom: none;
        }
        
        .status-label {
            color: #666;
            font-weight: 500;
        }
        
        .status-value {
            font-weight: 600;
            font-size: 1.1em;
        }
        
        .status-normal {
            color: #dc3545;
        }
        
        .status-cloaked {
            color: #28a745;
        }
        
        .password-section {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .password-section h3 {
            color: #856404;
            margin-bottom: 12px;
            font-size: 1em;
        }
        
        .password-section p {
            color: #856404;
            font-size: 0.9em;
            margin-bottom: 12px;
        }
        
        .password-input-group {
            display: flex;
            gap: 10px;
        }
        
        .password-input {
            flex: 1;
            padding: 12px 15px;
            border: 2px solid #ffc107;
            border-radius: 8px;
            font-size: 1em;
            outline: none;
            transition: border-color 0.3s;
        }
        
        .password-input:focus {
            border-color: #667eea;
        }
        
        .btn-save-password {
            padding: 12px 20px;
            background: #ffc107;
            color: #856404;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .btn-save-password:hover {
            background: #e0a800;
        }
        
        .password-saved {
            background: #d4edda;
            border-color: #28a745;
        }
        
        .password-saved h3,
        .password-saved p {
            color: #155724;
        }
        
        .button-group {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .btn {
            flex: 1;
            padding: 18px 24px;
            border: none;
            border-radius: 12px;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .btn:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.2);
        }
        
        .btn:active {
            transform: translateY(0);
        }
        
        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }
        
        .btn-start {
            background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
            color: white;
        }
        
        .btn-stop {
            background: linear-gradient(135deg, #dc3545 0%, #fd7e14 100%);
            color: white;
        }
        
        .btn-refresh {
            background: #6c757d;
            color: white;
            padding: 12px 20px;
            font-size: 1em;
        }
        
        .info-box {
            background: #e7f3ff;
            border-left: 4px solid #0066cc;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
        }
        
        .info-box h3 {
            color: #0066cc;
            margin-bottom: 8px;
        }
        
        .info-box p {
            color: #555;
            line-height: 1.6;
            font-size: 0.95em;
        }
        
        .toast {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 25px;
            border-radius: 10px;
            color: white;
            font-weight: 500;
            opacity: 0;
            transform: translateY(-20px);
            transition: all 0.3s ease;
            z-index: 1000;
            max-width: 350px;
            word-wrap: break-word;
        }
        
        .toast.show {
            opacity: 1;
            transform: translateY(0);
        }
        
        .toast.success {
            background: #28a745;
        }
        
        .toast.error {
            background: #dc3545;
        }
        
        .toast.warning {
            background: #ffc107;
            color: #856404;
        }
        
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255,255,255,.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .checkbox-wrapper {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 10px;
            font-size: 0.9em;
            color: #666;
        }
        
        .checkbox-wrapper input[type="checkbox"] {
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
        
        footer {
            text-align: center;
            margin-top: 25px;
            color: #999;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ TetherFlow</h1>
            <p>智能網路偽裝控制面板</p>
        </div>
        
        <div class="status-card">
            <div class="status-title">📊 目前狀態</div>
            <div class="status-item">
                <span class="status-label">TTL 值</span>
                <span class="status-value" id="ttl-value">檢測中...</span>
            </div>
            <div class="status-item">
                <span class="status-label">MTU 值</span>
                <span class="status-value" id="mtu-value">檢測中...</span>
            </div>
            <div class="status-item">
                <span class="status-label">偽裝狀態</span>
                <span class="status-value" id="cloak-status">檢測中...</span>
            </div>
        </div>
        
        <div class="password-section" id="password-section">
            <h3>🔐 管理員密碼設定</h3>
            <p>為了修改系統網路設定，需要您的 Mac 登入密碼</p>
            <div class="password-input-group">
                <input 
                    type="password" 
                    id="password-input" 
                    class="password-input" 
                    placeholder="請輸入您的 Mac 密碼..."
                >
                <button class="btn-save-password" onclick="savePassword()">
                    💾 儲存
                </button>
            </div>
            <div class="checkbox-wrapper">
                <input type="checkbox" id="show-password" onchange="togglePasswordVisibility()">
                <label for="show-password">顯示密碼</label>
            </div>
        </div>
        
        <div class="button-group">
            <button class="btn btn-start" id="btn-start" onclick="startCloaking()" disabled>
                🟢 啟動偽裝
            </button>
            <button class="btn btn-stop" id="btn-stop" onclick="stopCloaking()" disabled>
                🔴 停止偽裝
            </button>
        </div>
        
        <button class="btn btn-refresh" onclick="refreshStatus()">
            🔄 重新整理狀態
        </button>
        
        <div class="info-box">
            <h3>ℹ️ 使用說明</h3>
            <p>
                <strong>1.</strong> 在上方輸入您的 Mac 登入密碼並儲存<br>
                <strong>2.</strong> 點擊「啟動偽裝」將 TTL 設為 65，MTU 設為 1400<br>
                <strong>3.</strong> 點擊「停止偽裝」還原為預設值<br>
                <strong>安全提醒：</strong>密碼僅儲存在瀏覽器記憶體中，不會傳送到伺服器儲存
            </p>
        </div>
        
        <footer>
            TetherFlow v3.0 | Phase 3 Complete
        </footer>
    </div>
    
    <div class="toast" id="toast"></div>
    
    <script>
        let savedPassword = '';
        
        // 頁面載入時自動重新整理狀態
        window.onload = function() {
            refreshStatus();
            checkPasswordSaved();
        };
        
        // 每 5 秒自動重新整理狀態
        setInterval(refreshStatus, 5000);
        
        function showToast(message, type = 'success') {
            const toast = document.getElementById('toast');
            toast.textContent = message;
            toast.className = 'toast ' + type;
            toast.classList.add('show');
            
            setTimeout(() => {
                toast.classList.remove('show');
            }, 3000);
        }
        
        function togglePasswordVisibility() {
            const passwordInput = document.getElementById('password-input');
            const showPassword = document.getElementById('show-password');
            passwordInput.type = showPassword.checked ? 'text' : 'password';
        }
        
        function savePassword() {
            const passwordInput = document.getElementById('password-input');
            const password = passwordInput.value.trim();
            
            if (!password) {
                showToast('請輸入密碼', 'error');
                return;
            }
            
            savedPassword = password;
            
            // 更新 UI
            const section = document.getElementById('password-section');
            section.classList.add('password-saved');
            section.querySelector('h3').textContent = '✅ 密碼已設定';
            section.querySelector('p').textContent = '密碼已儲存，可以開始使用';
            
            // 啟用按鈕
            document.getElementById('btn-start').disabled = false;
            document.getElementById('btn-stop').disabled = false;
            
            showToast('密碼已儲存！現在可以啟動/停止偽裝');
            
            // 清空輸入框
            passwordInput.value = '';
        }
        
        function checkPasswordSaved() {
            const hasPassword = !!savedPassword;
            document.getElementById('btn-start').disabled = !hasPassword;
            document.getElementById('btn-stop').disabled = !hasPassword;
        }
        
        function refreshStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    // 更新 TTL
                    const ttlElement = document.getElementById('ttl-value');
                    ttlElement.textContent = data.ttl;
                    ttlElement.className = 'status-value ' + (data.ttl === 65 ? 'status-cloaked' : 'status-normal');
                    
                    // 更新 MTU
                    const mtuElement = document.getElementById('mtu-value');
                    mtuElement.textContent = data.mtu;
                    mtuElement.className = 'status-value ' + (data.mtu === 1400 ? 'status-cloaked' : 'status-normal');
                    
                    // 更新狀態
                    const statusElement = document.getElementById('cloak-status');
                    if (data.ttl === 65 && data.mtu === 1400) {
                        statusElement.textContent = '🟢 偽裝中';
                        statusElement.className = 'status-value status-cloaked';
                    } else {
                        statusElement.textContent = '🔴 正常模式';
                        statusElement.className = 'status-value status-normal';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                });
        }
        
        function startCloaking() {
            if (!savedPassword) {
                showToast('請先輸入並儲存密碼', 'warning');
                return;
            }
            
            const btn = document.getElementById('btn-start');
            btn.innerHTML = '<span class="loading"></span> 處理中...';
            btn.disabled = true;
            
            fetch('/api/start', { 
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ password: savedPassword })
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showToast('✅ 偽裝已啟動！TTL=65, MTU=1400');
                        refreshStatus();
                    } else {
                        showToast('❌ ' + data.error, 'error');
                        // 只有明確的密碼錯誤才清空密碼
                        if (data.error.includes('密碼錯誤')) {
                            savedPassword = '';
                            document.getElementById('password-section').classList.remove('password-saved');
                            document.getElementById('password-section').querySelector('h3').textContent = '🔐 管理員密碼設定';
                            document.getElementById('password-section').querySelector('p').textContent = '密碼錯誤，請重新輸入';
                            checkPasswordSaved(); // 更新按鈕狀態
                        }
                    }
                })
                .catch(error => {
                    showToast('❌ 發生錯誤', 'error');
                })
                .finally(() => {
                    btn.innerHTML = '🟢 啟動偽裝';
                    btn.disabled = false;
                    checkPasswordSaved();
                });
        }
        
        function stopCloaking() {
            if (!savedPassword) {
                showToast('請先輸入並儲存密碼', 'warning');
                return;
            }
            
            const btn = document.getElementById('btn-stop');
            btn.innerHTML = '<span class="loading"></span> 處理中...';
            btn.disabled = true;
            
            fetch('/api/stop', { 
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ password: savedPassword })
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showToast('✅ 已停止偽裝！TTL=64, MTU=1500');
                        refreshStatus();
                    } else {
                        showToast('❌ ' + data.error, 'error');
                        // 只有明確的密碼錯誤才清空密碼
                        if (data.error.includes('密碼錯誤')) {
                            savedPassword = '';
                            document.getElementById('password-section').classList.remove('password-saved');
                            document.getElementById('password-section').querySelector('h3').textContent = '🔐 管理員密碼設定';
                            document.getElementById('password-section').querySelector('p').textContent = '密碼錯誤，請重新輸入';
                            checkPasswordSaved(); // 更新按鈕狀態
                        }
                    }
                })
                .catch(error => {
                    showToast('❌ 發生錯誤', 'error');
                })
                .finally(() => {
                    btn.innerHTML = '🔴 停止偽裝';
                    btn.disabled = false;
                    checkPasswordSaved();
                });
        }
    </script>
</body>
</html>
"""

class TetherFlowHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode('utf-8'))
            
        elif parsed_path.path == '/api/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            # 取得 TTL
            ttl = 64
            try:
                result = subprocess.run(['sysctl', 'net.inet.ip.ttl'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    ttl = int(result.stdout.strip().split(':')[1].strip())
            except:
                pass
            
            # 取得 MTU
            mtu = 1500
            try:
                result = subprocess.run(['ifconfig', 'en0'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    for line in result.stdout.split('\n'):
                        if 'mtu' in line:
                            parts = line.split()
                            for i, part in enumerate(parts):
                                if part == 'mtu' and i + 1 < len(parts):
                                    mtu = int(parts[i + 1])
                                    break
            except:
                pass
            
            response = {'ttl': ttl, 'mtu': mtu}
            self.wfile.write(json.dumps(response).encode())
            
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        parsed_path = urlparse(self.path)
        
        # 讀取請求內容
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        try:
            data = json.loads(post_data) if post_data else {}
            password = data.get('password', '')
        except:
            password = ''
        
        if parsed_path.path == '/api/start':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            if not password:
                response = {'success': False, 'error': '請提供密碼'}
                self.wfile.write(json.dumps(response).encode())
                return
            
            # 啟動偽裝
            try:
                import pexpect
                
                # 修改 TTL
                child = pexpect.spawn('sudo -S sysctl net.inet.ip.ttl=65', timeout=10)
                child.expect('Password:')
                child.sendline(password)
                child.expect(pexpect.EOF)
                ttl_result = child.exitstatus
                
                # 修改 MTU
                child = pexpect.spawn('sudo -S ifconfig en0 mtu 1400', timeout=10)
                child.expect('Password:')
                child.sendline(password)
                child.expect(pexpect.EOF)
                mtu_result = child.exitstatus
                
                if ttl_result == 0 and mtu_result == 0:
                    response = {'success': True}
                else:
                    # 檢查是否是密碼錯誤
                    is_password_error = (ttl_result == 1 or mtu_result == 1)
                    if is_password_error:
                        response = {'success': False, 'error': '密碼錯誤，請重新輸入'}
                    else:
                        response = {'success': False, 'error': '執行指令失敗，請檢查系統設定'}
                    
            except ImportError:
                # 如果沒有 pexpect，使用替代方法
                try:
                    # 使用 echo 傳遞密碼
                    cmd1 = f"echo '{password}' | sudo -S sysctl net.inet.ip.ttl=65"
                    cmd2 = f"echo '{password}' | sudo -S ifconfig en0 mtu 1400"
                    
                    result1 = subprocess.run(cmd1, shell=True, capture_output=True, text=True, timeout=10)
                    result2 = subprocess.run(cmd2, shell=True, capture_output=True, text=True, timeout=10)
                    
                    if result1.returncode == 0 and result2.returncode == 0:
                        response = {'success': True}
                    else:
                        error_msg = ''
                        if 'incorrect password' in result1.stderr.lower() or 'incorrect password' in result2.stderr.lower():
                            error_msg = '密碼錯誤'
                        elif result1.stderr:
                            error_msg = result1.stderr.strip()
                        elif result2.stderr:
                            error_msg = result2.stderr.strip()
                        else:
                            error_msg = '執行失敗，請檢查密碼'
                        response = {'success': False, 'error': error_msg}
                except Exception as e:
                    response = {'success': False, 'error': str(e)}
            except Exception as e:
                response = {'success': False, 'error': str(e)}
            
            self.wfile.write(json.dumps(response).encode())
            
        elif parsed_path.path == '/api/stop':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            if not password:
                response = {'success': False, 'error': '請提供密碼'}
                self.wfile.write(json.dumps(response).encode())
                return
            
            # 停止偽裝
            try:
                # 使用 echo 傳遞密碼
                cmd1 = f"echo '{password}' | sudo -S sysctl net.inet.ip.ttl=64"
                cmd2 = f"echo '{password}' | sudo -S ifconfig en0 mtu 1500"
                
                result1 = subprocess.run(cmd1, shell=True, capture_output=True, text=True, timeout=10)
                result2 = subprocess.run(cmd2, shell=True, capture_output=True, text=True, timeout=10)
                
                if result1.returncode == 0 and result2.returncode == 0:
                    response = {'success': True}
                else:
                    error_msg = ''
                    if 'incorrect password' in result1.stderr.lower() or 'incorrect password' in result2.stderr.lower():
                        error_msg = '密碼錯誤'
                    else:
                        error_msg = result1.stderr.strip() or result2.stderr.strip() or '執行失敗'
                    response = {'success': False, 'error': error_msg}
            except Exception as e:
                response = {'success': False, 'error': str(e)}
            
            self.wfile.write(json.dumps(response).encode())
            
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_message(self, format, *args):
        # 簡化日誌輸出
        pass

def main():
    # 檢查並安裝 pexpect（如果可用）
    try:
        import pexpect
    except ImportError:
        print("正在安裝必要套件...")
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'pexpect', '-q'])
        print("✅ 套件安裝完成")
    
    with socketserver.TCPServer(("", PORT), TetherFlowHandler) as httpd:
        print(f"""
╔══════════════════════════════════════════════════╗
║                                                  ║
║   🛡️  TetherFlow Web Server v3.0 - Phase 3     ║
║                                                  ║
║   請在瀏覽器開啟:                                 ║
║   http://localhost:{PORT}                        ║
║                                                  ║
║   💡 新功能：現在可以在網頁上直接輸入密碼！       ║
║                                                  ║
║   按 Ctrl+C 結束                                 ║
║                                                  ║
╚══════════════════════════════════════════════════╝
        """)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n伺服器已結束")

if __name__ == '__main__':
    main()
