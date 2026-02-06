#!/usr/bin/env python3
"""
TetherFlow Web Server - Phase 3 Complete
Flask-based REST API for network cloaking control
Features: Auto-Detection, DoH/DoT DNS, Traffic Shaping, System Integration
"""

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import subprocess
import os
import json
import re
import time
import threading
from datetime import datetime, timedelta
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
        self.speed_test_results = []
        self.wifi_monitor_thread = None
        self.wifi_monitoring = False
        self.current_ssid = None
        self.session_stats = {
            'total_sessions': 0,
            'total_cloak_time': 0,
            'last_session_start': None
        }
        # T007: Wi-Fi 自動監控
        self.auto_detection_enabled = False
        self.last_wifi_state = None
        self.auto_start_triggered = False
        # T008: DNS 設定
        self.dns_settings = {
            'enabled': False,
            'provider': 'cloudflare',
            'custom_servers': []
        }
        # T009: 流量整形
        self.traffic_shaping = {
            'enabled': False,
            'rules': []
        }
        # T010: 系統設定
        self.system_settings = {
            'auto_launch': False,
            'menubar_enabled': False,
            'global_shortcut': 'Cmd+Shift+T'
        }
        
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
            
    def load_session_stats(self):
        """載入會話統計"""
        try:
            with open('data/session_stats.json', 'r') as f:
                self.session_stats = json.load(f)
        except:
            self.session_stats = {
                'total_sessions': 0,
                'total_cloak_time': 0,
                'last_session_start': None
            }
            
    def save_session_stats(self):
        """儲存會話統計"""
        os.makedirs('data', exist_ok=True)
        with open('data/session_stats.json', 'w') as f:
            json.dump(self.session_stats, f, indent=2)
            
    def load_dns_settings(self):
        """T008: 載入 DNS 設定"""
        try:
            with open('data/dns_settings.json', 'r') as f:
                self.dns_settings = json.load(f)
        except:
            self.dns_settings = {
                'enabled': False,
                'provider': 'cloudflare',
                'custom_servers': []
            }
            
    def save_dns_settings(self):
        """T008: 儲存 DNS 設定"""
        os.makedirs('data', exist_ok=True)
        with open('data/dns_settings.json', 'w') as f:
            json.dump(self.dns_settings, f, indent=2)
            
    def load_traffic_shaping(self):
        """T009: 載入流量整形設定"""
        try:
            with open('data/traffic_shaping.json', 'r') as f:
                self.traffic_shaping = json.load(f)
        except:
            self.traffic_shaping = {
                'enabled': False,
                'rules': []
            }
            
    def save_traffic_shaping(self):
        """T009: 儲存流量整形設定"""
        os.makedirs('data', exist_ok=True)
        with open('data/traffic_shaping.json', 'w') as f:
            json.dump(self.traffic_shaping, f, indent=2)
            
    def load_system_settings(self):
        """T010: 載入系統設定"""
        try:
            with open('data/system_settings.json', 'r') as f:
                self.system_settings = json.load(f)
        except:
            self.system_settings = {
                'auto_launch': False,
                'menubar_enabled': False,
                'global_shortcut': 'Cmd+Shift+T'
            }
            
    def save_system_settings(self):
        """T010: 儲存系統設定"""
        os.makedirs('data', exist_ok=True)
        with open('data/system_settings.json', 'w') as f:
            json.dump(self.system_settings, f, indent=2)
            
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
        
        # 更新統計
        if action == 'start_cloaking' and success:
            self.session_stats['total_sessions'] += 1
            self.session_stats['last_session_start'] = datetime.now().isoformat()
            self.save_session_stats()
        
        # 只保留最近 100 條記錄
        self.session_history = self.session_history[-100:]
        
        # 儲存到檔案
        os.makedirs('data', exist_ok=True)
        with open('data/history.json', 'w') as f:
            json.dump(self.session_history, f, indent=2)
            
    def end_session(self, success):
        """結束會話並計算時長"""
        if self.session_stats['last_session_start']:
            start_time = datetime.fromisoformat(self.session_stats['last_session_start'])
            duration = (datetime.now() - start_time).total_seconds()
            self.session_stats['total_cloak_time'] += duration
            self.session_stats['last_session_start'] = None
            self.save_session_stats()
            return duration
        return 0

state = AppState()

# DNS 提供者設定
DNS_PROVIDERS = {
    'cloudflare': {
        'name': 'Cloudflare',
        'servers': ['1.1.1.1', '1.0.0.1'],
        'doh_url': 'https://cloudflare-dns.com/dns-query'
    },
    'cloudflare_family': {
        'name': 'Cloudflare (Family)',
        'servers': ['1.1.1.3', '1.0.0.3'],
        'doh_url': 'https://family.cloudflare-dns.com/dns-query'
    },
    'google': {
        'name': 'Google DNS',
        'servers': ['8.8.8.8', '8.8.4.4'],
        'doh_url': 'https://dns.google/dns-query'
    },
    'quad9': {
        'name': 'Quad9',
        'servers': ['9.9.9.9', '149.112.112.112'],
        'doh_url': 'https://dns.quad9.net/dns-query'
    },
    'opendns': {
        'name': 'OpenDNS',
        'servers': ['208.67.222.222', '208.67.220.220'],
        'doh_url': 'https://doh.opendns.com/dns-query'
    }
}

# 輔助函數
def get_network_status():
    """取得目前網路狀態"""
    ttl = 64
    mtu = 1500
    ssid = None
    interface = 'en0'
    dns_servers = []
    
    try:
        # 取得 TTL
        result = subprocess.run(['sysctl', 'net.inet.ip.ttl'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            ttl = int(result.stdout.strip().split(':')[1].strip())
    except:
        pass
    
    # 取得 MTU 和介面
    try:
        result = subprocess.run(['ifconfig', interface], 
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
    
    # 取得目前 Wi-Fi SSID
    try:
        result = subprocess.run(
            ['/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', '-I'],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            for line in result.stdout.split('\n'):
                if ' SSID' in line and 'BSSID' not in line:
                    match = re.search(r'SSID:\s*(.+)', line)
                    if match:
                        ssid = match.group(1).strip()
                        break
    except:
        pass
    
    # 取得目前 DNS 伺服器
    try:
        result = subprocess.run(['scutil', '--dns'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            for line in result.stdout.split('\n'):
                if 'nameserver' in line:
                    match = re.search(r'nameserver\[.+\]\s*:\s*(\d+\.\d+\.\d+\.\d+)', line)
                    if match and match.group(1) not in dns_servers:
                        dns_servers.append(match.group(1))
    except:
        pass
    
    return {
        'ttl': ttl, 
        'mtu': mtu, 
        'ssid': ssid, 
        'interface': interface,
        'dns_servers': dns_servers[:4]  # 最多 4 個
    }

def execute_sudo_command(command, password):
    """執行 sudo 指令"""
    try:
        # 使用更安全的方式執行 sudo
        import shlex
        # 構建指令：將密碼通過 stdin 傳給 sudo
        sudo_cmd = ['sudo', '-S'] + shlex.split(command)
        
        # 創建一個進程，將密碼寫入 stdin
        import subprocess
        proc = subprocess.Popen(
            sudo_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # 傳送密碼（加上換行符）
        stdout, stderr = proc.communicate(input=password + '\n', timeout=10)
        
        # 檢查是否成功
        if proc.returncode == 0:
            return True, stdout
        else:
            # 檢查是否是密碼錯誤
            if 'incorrect password' in stderr.lower() or 'sorry' in stderr.lower():
                return False, '密碼錯誤'
            return False, stderr
    except subprocess.TimeoutExpired:
        proc.kill()
        return False, '執行超時'
    except Exception as e:
        return False, str(e)

def run_speed_test():
    """執行網路速度測試"""
    try:
        # 嘗試使用 speedtest-cli
        result = subprocess.run(
            ['speedtest-cli', '--simple', '--timeout', '30'],
            capture_output=True, text=True, timeout=60
        )
        
        if result.returncode == 0:
            # 解析結果
            lines = result.stdout.strip().split('\n')
            download = 0
            upload = 0
            ping = 0
            
            for line in lines:
                if 'Download:' in line:
                    download = float(line.split()[1])
                elif 'Upload:' in line:
                    upload = float(line.split()[1])
                elif 'Ping:' in line:
                    ping = float(line.split()[1])
            
            return {
                'success': True,
                'download': download,
                'upload': upload,
                'ping': ping,
                'timestamp': datetime.now().isoformat()
            }
    except FileNotFoundError:
        # speedtest-cli 未安裝，使用替代方法
        pass
    except Exception as e:
        return {'success': False, 'error': str(e)}
    
    # 替代方法：使用 curl 測試下載速度
    try:
        start_time = time.time()
        result = subprocess.run(
            ['curl', '-s', '-o', '/dev/null', '-w', '%{speed_download}', 
             'https://speed.cloudflare.com/__down?bytes=1000000', '--max-time', '10'],
            capture_output=True, text=True, timeout=15
        )
        end_time = time.time()
        
        if result.returncode == 0:
            # speed_download 是 bytes per second
            speed_bps = float(result.stdout.strip())
            speed_mbps = (speed_bps * 8) / 1_000_000
            
            return {
                'success': True,
                'download': round(speed_mbps, 2),
                'upload': 0,  # 無法測試上傳
                'ping': round((end_time - start_time) * 1000, 2),
                'timestamp': datetime.now().isoformat(),
                'method': 'curl'
            }
    except:
        pass
    
    return {'success': False, 'error': 'Speed test not available'}

def get_matching_profile(ssid):
    """根據 SSID 尋找匹配的 Profile"""
    if not ssid:
        return None
    
    state.load_profiles()
    for profile in state.profiles:
        if profile.get('ssid') == ssid:
            return profile
    return None

# T007: Wi-Fi 背景監控執行緒
def wifi_monitor_loop():
    """背景 Wi-Fi 監控迴圈"""
    while state.wifi_monitoring:
        try:
            status = get_network_status()
            current_ssid = status.get('ssid')
            
            # 檢查 Wi-Fi 是否改變
            if current_ssid != state.last_wifi_state:
                state.last_wifi_state = current_ssid
                state.auto_start_triggered = False
                
                if current_ssid and state.auto_detection_enabled:
                    # 尋找匹配的 Profile
                    matching_profile = get_matching_profile(current_ssid)
                    
                    if matching_profile and matching_profile.get('auto_start') and not state.auto_start_triggered:
                        # 自動啟動偽裝
                        if state.saved_password:
                            password = state.saved_password
                            execute_sudo_command(f'sysctl net.inet.ip.ttl={matching_profile.get("ttl", 65)}', password)
                            execute_sudo_command(f'ifconfig en0 mtu {matching_profile.get("mtu", 1400)}', password)
                            state.add_session('auto_start_cloaking', True, {
                                'ssid': current_ssid,
                                'profile_id': matching_profile.get('id'),
                                'ttl': matching_profile.get('ttl', 65),
                                'mtu': matching_profile.get('mtu', 1400)
                            })
                            state.auto_start_triggered = True
                            
            time.sleep(5)  # 每 5 秒檢查一次
        except Exception as e:
            print(f"Wi-Fi monitor error: {e}")
            time.sleep(5)

def start_wifi_monitor():
    """啟動 Wi-Fi 監控"""
    if not state.wifi_monitoring:
        state.wifi_monitoring = True
        state.wifi_monitor_thread = threading.Thread(target=wifi_monitor_loop, daemon=True)
        state.wifi_monitor_thread.start()

def stop_wifi_monitor():
    """停止 Wi-Fi 監控"""
    state.wifi_monitoring = False

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
    
    # 檢查是否有匹配的 Profile
    matching_profile = get_matching_profile(status.get('ssid'))
    
    # 載入統計
    state.load_session_stats()
    state.load_dns_settings()
    state.load_traffic_shaping()
    state.load_system_settings()
    
    return jsonify({
        'success': True,
        'data': {
            **status,
            'is_cloaked': is_cloaked,
            'has_password': state.saved_password is not None,
            'matching_profile': matching_profile,
            'session_stats': state.session_stats,
            'auto_detection': state.auto_detection_enabled,
            'dns_settings': state.dns_settings,
            'traffic_shaping': state.traffic_shaping,
            'system_settings': state.system_settings
        }
    })

# T007: Wi-Fi 自動偵測 API
@app.route('/api/wifi/detect')
def detect_wifi():
    """偵測目前 Wi-Fi 網路"""
    status = get_network_status()
    ssid = status.get('ssid')
    
    if not ssid:
        return jsonify({
            'success': False,
            'error': '無法偵測 Wi-Fi 網路'
        }), 404
    
    # 尋找匹配的 Profile
    matching_profile = get_matching_profile(ssid)
    
    return jsonify({
        'success': True,
        'data': {
            'ssid': ssid,
            'interface': status.get('interface'),
            'matching_profile': matching_profile,
            'can_auto_start': matching_profile and matching_profile.get('auto_start', False)
        }
    })

@app.route('/api/wifi/scan')
def scan_wifi():
    """掃描可用的 Wi-Fi 網路"""
    try:
        result = subprocess.run(
            ['/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', '-s'],
            capture_output=True, text=True, timeout=10
        )
        
        if result.returncode == 0:
            networks = []
            lines = result.stdout.strip().split('\n')[1:]  # 跳過標題行
            
            for line in lines:
                parts = line.split()
                if len(parts) >= 2:
                    ssid = parts[0]
                    rssi = parts[2] if len(parts) > 2 else '0'
                    channel = parts[3] if len(parts) > 3 else '0'
                    
                    # 檢查是否有對應的 Profile
                    has_profile = any(p.get('ssid') == ssid for p in state.profiles)
                    
                    networks.append({
                        'ssid': ssid,
                        'rssi': rssi,
                        'channel': channel,
                        'has_profile': has_profile
                    })
            
            return jsonify({
                'success': True,
                'data': networks
            })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    
    return jsonify({
        'success': False,
        'error': '無法掃描 Wi-Fi'
    }), 500

@app.route('/api/wifi/auto-detection', methods=['GET', 'POST'])
def wifi_auto_detection():
    """T007: Wi-Fi 自動偵測設定"""
    if request.method == 'GET':
        return jsonify({
            'success': True,
            'data': {
                'enabled': state.auto_detection_enabled,
                'monitoring': state.wifi_monitoring
            }
        })
    
    data = request.get_json()
    enabled = data.get('enabled', False)
    
    state.auto_detection_enabled = enabled
    
    if enabled:
        start_wifi_monitor()
    else:
        stop_wifi_monitor()
    
    return jsonify({
        'success': True,
        'data': {
            'enabled': state.auto_detection_enabled,
            'monitoring': state.wifi_monitoring
        }
    })

# T008: DNS 設定 API
@app.route('/api/dns/providers')
def get_dns_providers():
    """T008: 取得 DNS 提供者列表"""
    return jsonify({
        'success': True,
        'data': DNS_PROVIDERS
    })

@app.route('/api/dns/settings', methods=['GET', 'POST'])
def dns_settings():
    """T008: DNS 設定管理"""
    if request.method == 'GET':
        state.load_dns_settings()
        return jsonify({
            'success': True,
            'data': state.dns_settings
        })
    
    data = request.get_json()
    state.dns_settings.update({
        'enabled': data.get('enabled', state.dns_settings['enabled']),
        'provider': data.get('provider', state.dns_settings['provider']),
        'custom_servers': data.get('custom_servers', state.dns_settings['custom_servers'])
    })
    state.save_dns_settings()
    
    # 如果啟用 DNS，立即套用
    if state.dns_settings['enabled'] and state.saved_password:
        password = state.saved_password
        provider = DNS_PROVIDERS.get(state.dns_settings['provider'])
        if provider:
            for server in provider['servers']:
                execute_sudo_command(f'networksetup -setdnsservers Wi-Fi {server}', password)
    
    return jsonify({
        'success': True,
        'data': state.dns_settings
    })

# T009: 流量整形 API
@app.route('/api/traffic/rules', methods=['GET', 'POST', 'DELETE'])
def traffic_rules():
    """T009: 流量整形規則管理"""
    if request.method == 'GET':
        state.load_traffic_shaping()
        return jsonify({
            'success': True,
            'data': state.traffic_shaping
        })
    
    if request.method == 'POST':
        data = request.get_json()
        rule = {
            'id': len(state.traffic_shaping['rules']) + 1,
            'name': data.get('name', '未命名規則'),
            'port': data.get('port', ''),
            'protocol': data.get('protocol', 'tcp'),
            'bandwidth': data.get('bandwidth', '1000'),  # Kbps
            'enabled': data.get('enabled', True)
        }
        state.traffic_shaping['rules'].append(rule)
        state.save_traffic_shaping()
        
        return jsonify({
            'success': True,
            'data': rule
        })
    
    if request.method == 'DELETE':
        rule_id = request.args.get('id')
        state.traffic_shaping['rules'] = [r for r in state.traffic_shaping['rules'] if str(r['id']) != str(rule_id)]
        state.save_traffic_shaping()
        
        return jsonify({
            'success': True
        })

@app.route('/api/traffic/enable', methods=['POST'])
def enable_traffic_shaping():
    """T009: 啟用/停用流量整形"""
    data = request.get_json()
    enabled = data.get('enabled', False)
    
    state.traffic_shaping['enabled'] = enabled
    state.save_traffic_shaping()
    
    # TODO: 使用 pfctl 套用規則
    
    return jsonify({
        'success': True,
        'data': state.traffic_shaping
    })

# T010: 系統設定 API
@app.route('/api/system/settings', methods=['GET', 'POST'])
def system_settings():
    """T010: 系統設定管理"""
    if request.method == 'GET':
        state.load_system_settings()
        return jsonify({
            'success': True,
            'data': state.system_settings
        })
    
    data = request.get_json()
    state.system_settings.update({
        'auto_launch': data.get('auto_launch', state.system_settings['auto_launch']),
        'menubar_enabled': data.get('menubar_enabled', state.system_settings['menubar_enabled']),
        'global_shortcut': data.get('global_shortcut', state.system_settings['global_shortcut'])
    })
    state.save_system_settings()
    
    return jsonify({
        'success': True,
        'data': state.system_settings
    })

@app.route('/api/speed-test', methods=['POST'])
def run_speed_test_endpoint():
    """執行網路速度測試"""
    result = run_speed_test()
    
    if result.get('success'):
        # 儲存結果
        state.speed_test_results.append(result)
        state.speed_test_results = state.speed_test_results[-50:]  # 保留最近 50 筆
        
        os.makedirs('data', exist_ok=True)
        with open('data/speed_tests.json', 'w') as f:
            json.dump(state.speed_test_results, f, indent=2)
    
    return jsonify(result)

@app.route('/api/speed-test/history')
def get_speed_test_history():
    """取得速度測試歷史"""
    try:
        with open('data/speed_tests.json', 'r') as f:
            history = json.load(f)
    except:
        history = []
    
    return jsonify({
        'success': True,
        'data': history[-20:]  # 返回最近 20 筆
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
    data = request.get_json() or {}
    custom_ttl = data.get('ttl', 65)
    custom_mtu = data.get('mtu', 1400)
    profile_id = data.get('profile_id')
    
    if not state.saved_password:
        return jsonify({
            'success': False,
            'error': '請先儲存密碼'
        }), 401
    
    password = state.saved_password
    
    # 修改 TTL
    success1, error1 = execute_sudo_command(f'sysctl net.inet.ip.ttl={custom_ttl}', password)
    # 修改 MTU
    success2, error2 = execute_sudo_command(f'ifconfig en0 mtu {custom_mtu}', password)
    
    success = success1 and success2
    
    # 記錄會話
    state.add_session('start_cloaking', success, {
        'ttl': custom_ttl if success1 else None,
        'mtu': custom_mtu if success2 else None,
        'profile_id': profile_id,
        'error': error1 or error2 if not success else None
    })
    
    if success:
        return jsonify({
            'success': True,
            'message': f'偽裝已啟動 (TTL={custom_ttl}, MTU={custom_mtu})',
            'data': {
                'ttl': custom_ttl,
                'mtu': custom_mtu,
                'started_at': datetime.now().isoformat()
            }
        })
    else:
        error_msg = error1 or error2 or '執行失敗'
        # 檢查是否是密碼錯誤（支援中英文）
        if 'incorrect password' in error_msg.lower() or '密碼錯誤' in error_msg:
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
    
    # 計算會話時長
    duration = state.end_session(success)
    
    # 記錄會話
    state.add_session('stop_cloaking', success, {
        'ttl': 64 if success1 else None,
        'mtu': 1500 if success2 else None,
        'duration_seconds': duration,
        'error': error1 or error2 if not success else None
    })
    
    if success:
        return jsonify({
            'success': True,
            'message': '已停止偽裝 (TTL=64, MTU=1500)',
            'data': {
                'duration_minutes': round(duration / 60, 2)
            }
        })
    else:
        error_msg = error1 or error2 or '執行失敗'
        # 檢查是否是密碼錯誤（支援中英文）
        if 'incorrect password' in error_msg.lower() or '密碼錯誤' in error_msg:
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

@app.route('/api/stats')
def get_stats():
    """取得統計資料"""
    state.load_session_stats()
    
    # 計算額外統計
    total_time = state.session_stats.get('total_cloak_time', 0)
    total_sessions = state.session_stats.get('total_sessions', 0)
    
    avg_duration = total_time / total_sessions if total_sessions > 0 else 0
    
    # 取得最近 7 天的使用情況
    daily_usage = {}
    try:
        with open('data/history.json', 'r') as f:
            history = json.load(f)
        
        for item in history:
            if item.get('action') == 'stop_cloaking' and item.get('success'):
                date = item['timestamp'][:10]
                duration = item.get('details', {}).get('duration_seconds', 0)
                daily_usage[date] = daily_usage.get(date, 0) + duration
    except:
        pass
    
    return jsonify({
        'success': True,
        'data': {
            'total_sessions': total_sessions,
            'total_cloak_time_hours': round(total_time / 3600, 2),
            'avg_session_minutes': round(avg_duration / 60, 2),
            'daily_usage': daily_usage
        }
    })

if __name__ == '__main__':
    # 初始化
    os.makedirs('data', exist_ok=True)
    state.load_profiles()
    state.load_session_stats()
    state.load_dns_settings()
    state.load_traffic_shaping()
    state.load_system_settings()
    
    print("""
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   🛡️  TetherFlow Web Server v3.0 - Phase 3 Complete             ║
║                                                                  ║
║   Phase 3 Features:                                              ║
║   • T007: Wi-Fi Auto-Detection (Background Monitoring)          ║
║   • T008: Encrypted DNS (DoH/DoT) Support ⭐                    ║
║   • T009: Traffic Shaping with pfctl                            ║
║   • T010: System Integration (Auto-launch, Menu Bar)            ║
║                                                                  ║
║   Open in browser: http://localhost:5001                         ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
    """)
    app.run(host='0.0.0.0', port=5002, debug=True)
