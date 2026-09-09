#!/bin/sh
# Description: (After Update feeds)

# 默认 LAN IP
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# 主机名
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# DHCP 地址池
sed -i "s/option start.*/option start '100'/g" package/network/services/dnsmasq/files/dhcp.conf
sed -i "s/option limit.*/option limit '150'/g" package/network/services/dnsmasq/files/dhcp.conf
