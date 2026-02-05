#!/usr/bin/env python3
"""
TetherFlow Web Server - 完整版
Flask-based REST API for network cloaking control
"""

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import subprocess
import os
import json
from datetime import datetime
from functools import wraps

app = Flask(__name__)
CORS(app)

# 全域狀態
class AppState:
    def __init__(self):
        self.saved_password = None
        self.session_history = []
        self.current_session = None
        self.profiles = []
        
    def load_profiles(self):
        """從檔案載入 profiles"""
        try:
            with open('data/profiles.json', 'r') as f:
                self.profiles = json.load(f)
        except:
            self.profiles = []
            
    def save_profiles(self):
        """儲存 profiles 到檔案"""
        os.makedirs('data', exist_ok=True)
        with open('data/profiles.json', 'w') as f:
            json.dump(self.profiles, f, indent=2)
            
    def add_session(self, action, success, details=None):
        """記錄會話"""
        session = {
            'id': len(self.session_history) + 1,
            'timestamp': datetime.now().isoformat(),
            'action': action,
            'success': success,
            'details': details or {}
        }
        self.session_history.append(session)
        # 只保留最近 100 條記錄
        self.session_history = self.session_history[-100:]
        
        # 儲存到檔案
        os.makedirs('data', exist_ok=True)
        with open('data/history.json', 'w') as f:
            json.dump(self.session_history, f, indent=2)

state = AppState()

# 輔助函數
def get_network_status():
    """取得目前網路狀態"""
    ttl = 64
    mtu = 1500
    
    try:
        # 取得 TTL
        result = subprocess.run(['sysctl', 'net.inet.ip.ttl'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            ttl = int(result.stdout.strip().split(':')[1].strip())
    except:
        pass
    
    # 取得 MTU
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
    
    return {'ttl': ttl, 'mtu': mtu}

def execute_sudo_command(command, password):
    """執行 sudo 指令"""
    try:
        full_command = f"echo '{password}' | sudo -S {command}"
        result = subprocess.run(full_command, shell=True, 
                              capture_output=True, text=True, timeout=10)
        return result.returncode == 0, result.stderr
    except Exception as e:
        return False, str(e)

# API 路由
@app.route('/')
def index():
    """主頁面"""
    return send_from_directory('../frontend', 'index.html')

@app.route('/<path:path>')
def static_files(path):
    """靜態檔案"""
    return send_from_directory('../frontend', path)

@app.route('/api/status')
def get_status():
    """取得目前狀態"""
    status = get_network_status()
    is_cloaked = status['ttl'] == 65 and status['mtu'] == 1400
    
    return jsonify({
        'success': True,
        'data': {
            **status,
            'is_cloaked': is_cloaked,
            'has_password': state.saved_password is not None
        }
    })

@app.route('/api/save-password', methods=['POST'])
def save_password():
    """儲存密碼（僅記憶體）"""
    data = request.get_json()
    password = data.get('password', '').strip()
    
    if not password:
        return jsonify({'success': False, 'error': '請輸入密碼'}), 400
    
    # 測試密碼是否正確
    success, error = execute_sudo_command('whoami', password)
    
    if success:
        state.saved_password = password
        return jsonify({
            'success': True,
            'message': '密碼已儲存（僅記憶體）'
        })
    else:
        return jsonify({
            'success': False,
            'error': '密碼錯誤'
        }), 401

@app.route('/api/clear-password', methods=['POST'])
def clear_password():
    """清除儲存的密碼"""
    state.saved_password = None
    return jsonify({'success': True, 'message': '密碼已清除'})

@app.route('/api/start', methods=['POST'])
def start_cloaking():
    """啟動偽裝"""
    if not state.saved_password:
        return jsonify({
            'success': False,
            'error': '請先儲存密碼'
        }), 401
    
    password = state.saved_password
    
    # 修改 TTL
    success1, error1 = execute_sudo_command('sysctl net.inet.ip.ttl=65', password)
    # 修改 MTU
    success2, error2 = execute_sudo_command('ifconfig en0 mtu 1400', password)
    
    success = success1 and success2
    
    # 記錄會話
    state.add_session('start_cloaking', success, {
        'ttl': 65 if success1 else None,
        'mtu': 1400 if success2 else None,
        'error': error1 or error2 if not success else None
    })
    
    if success:
        return jsonify({
            'success': True,
            'message': '偽裝已啟動 (TTL=65, MTU=1400)'
        })
    else:
        error_msg = error1 or error2 or '執行失敗'
        if 'incorrect password' in error_msg.lower():
            state.saved_password = None
            return jsonify({
                'success': False,
                'error': '密碼錯誤，請重新輸入'
            }), 401
        return jsonify({'success': False, 'error': error_msg}), 500

@app.route('/api/stop', methods=['POST'])
def stop_cloaking():
    """停止偽裝"""
    if not state.saved_password:
        return jsonify({
            'success': False,
            'error': '請先儲存密碼'
        }), 401
    
    password = state.saved_password
    
    # 還原 TTL
    success1, error1 = execute_sudo_command('sysctl net.inet.ip.ttl=64', password)
    # 還原 MTU
    success2, error2 = execute_sudo_command('ifconfig en0 mtu 1500', password)
    
    success = success1 and success2
    
    # 記錄會話
    state.add_session('stop_cloaking', success, {
        'ttl': 64 if success1 else None,
        'mtu': 1500 if success2 else None,
        'error': error1 or error2 if not success else None
    })
    
    if success:
        return jsonify({
            'success': True,
            'message': '已停止偽裝 (TTL=64, MTU=1500)'
        })
    else:
        error_msg = error1 or error2 or '執行失敗'
        if 'incorrect password' in error_msg.lower():
            state.saved_password = None
            return jsonify({
                'success': False,
                'error': '密碼錯誤，請重新輸入'
            }), 401
        return jsonify({'success': False, 'error': error_msg}), 500

@app.route('/api/profiles', methods=['GET'])
def get_profiles():
    """取得所有 profiles"""
    state.load_profiles()
    return jsonify({'success': True, 'data': state.profiles})

@app.route('/api/profiles', methods=['POST'])
def create_profile():
    """建立新 profile"""
    data = request.get_json()
    
    profile = {
        'id': len(state.profiles) + 1,
        'name': data.get('name', '未命名'),
        'ssid': data.get('ssid', ''),
        'ttl': data.get('ttl', 65),
        'mtu': data.get('mtu', 1400),
        'auto_start': data.get('auto_start', False),
        'created_at': datetime.now().isoformat()
    }
    
    state.profiles.append(profile)
    state.save_profiles()
    
    return jsonify({'success': True, 'data': profile})

@app.route('/api/profiles/<int:profile_id>', methods=['PUT'])
def update_profile(profile_id):
    """更新 profile"""
    data = request.get_json()
    
    for profile in state.profiles:
        if profile['id'] == profile_id:
            profile.update({
                'name': data.get('name', profile['name']),
                'ssid': data.get('ssid', profile['ssid']),
                'ttl': data.get('ttl', profile['ttl']),
                'mtu': data.get('mtu', profile['mtu']),
                'auto_start': data.get('auto_start', profile['auto_start']),
                'updated_at': datetime.now().isoformat()
            })
            state.save_profiles()
            return jsonify({'success': True, 'data': profile})
    
    return jsonify({'success': False, 'error': 'Profile 不存在'}), 404

@app.route('/api/profiles/<int:profile_id>', methods=['DELETE'])
def delete_profile(profile_id):
    """刪除 profile"""
    state.profiles = [p for p in state.profiles if p['id'] != profile_id]
    state.save_profiles()
    return jsonify({'success': True})

@app.route('/api/history')
def get_history():
    """取得操作歷史"""
    try:
        with open('data/history.json', 'r') as f:
            history = json.load(f)
    except:
        history = []
    
    return jsonify({'success': True, 'data': history[-50:]})  # 只返回最近 50 條

if __name__ == '__main__':
    print("""
╔══════════════════════════════════════════════════╗
║                                                  ║
║   🛡️  TetherFlow Web Server v2.0                ║
║                                                  ║
║   請在瀏覽器開啟:                                 ║
║   http://localhost:5000                          ║
║                                                  ║
╚══════════════════════════════════════════════════╝
    """)
    app.run(host='0.0.0.0', port=5000, debug=True)
