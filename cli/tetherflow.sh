#!/bin/bash
# TetherFlow CLI 工具

echo "TetherFlow CLI"
echo "1. 啟動偽裝"
echo "2. 停止偽裝"
echo "3. 檢查狀態"
read -p "選擇: " choice

case $choice in
    1)
        read -sp "輸入密碼: " pwd
        echo
        echo "$pwd" | sudo -S sysctl net.inet.ip.ttl=65
        echo "$pwd" | sudo -S ifconfig en0 mtu 1400
        echo "偽裝已啟動"
        ;;
    2)
        read -sp "輸入密碼: " pwd
        echo
        echo "$pwd" | sudo -S sysctl net.inet.ip.ttl=64
        echo "$pwd" | sudo -S ifconfig en0 mtu 1500
        echo "已停止偽裝"
        ;;
    3)
        sysctl net.inet.ip.ttl
        ifconfig en0 | grep mtu
        ;;
esac
