#!/bin/sh
# Description: (Before Update feeds)
#
# 本脚本在 clone 源码之后、feeds update 之前执行，工作目录 = openwrt/

set -e

# ---------------------------------------------------------------------------
# 收紧 scripts/download.pl 里 curl 的超时参数
#
# 上游原样：  curl -f --connect-timeout 20 --retry 5 --location
#
# 两个毛病：
#   1) 只有 --connect-timeout（只管建连成功与否），没有 --max-time，也没有低速
#      保护。源站接受了连接却不发数据时，curl 会一直挂着，make download 跟着
#      永久卡死。本仓库实测卡过 59 分钟。
#
#   2) 更隐蔽的是 --retry 5。curl 重试是「从头重传」，而 download.pl 是从 curl
#      的 stdout 边读边写临时文件、边算哈希的，重传的数据会直接续写进同一个
#      临时文件。实测 ftp.infradead.org 上一个 628KB 的包被写到了 2MB —— 这种
#      下载就算跑满 --max-time 也必然哈希不匹配，纯粹白等。
#
# 所以：去掉 curl 自身的重试（换源交给 download.pl 的镜像轮询去做），低速门槛
# 从 1KB/s 提到 16KB/s、判定窗口从 120s 缩到 30s，硬超时 1800s 压到 900s。
# ---------------------------------------------------------------------------
DL_OLD='curl -f --connect-timeout 20 --retry 5'
DL_NEW='curl -f --connect-timeout 15 --speed-limit 16384 --speed-time 30 --max-time 900 --retry 0'

if ! grep -qF -- "$DL_OLD" scripts/download.pl; then
	echo "ERROR: scripts/download.pl 里没找到预期的 curl 参数行。" >&2
	echo "       上游可能改过这一行，请人工确认后再更新本脚本，别让补丁静默失效。" >&2
	grep -n 'qw(curl' scripts/download.pl >&2
	exit 1
fi
sed -i "s|$DL_OLD|$DL_NEW|" scripts/download.pl
echo "download.pl curl 参数已收紧："
grep -n 'qw(curl' scripts/download.pl

# ---------------------------------------------------------------------------
# 源码包优先走官方镜像
#
# download.pl 的 localmirrors() 会把这里列的 URL 排在软件包自带 URL 之前。
# 包自带地址里有不少是 FTP 或早已无人维护的个人站（上面那个卡死的就是 FTP），
# 先走官方镜像能绕开绝大部分。全部用国际源，不放中国大陆镜像 —— GitHub runner
# 在境外，放大陆源反而更慢。
# ---------------------------------------------------------------------------
cat > scripts/localmirrors <<'EOF'
https://sources.cdn.openwrt.org
https://sources.openwrt.org
https://sources.immortalwrt.org
EOF
echo "已写入 scripts/localmirrors："
cat scripts/localmirrors


# ---------------------------------------------------------------------------
# 以下是模板自带的 feeds 定制示例，按需取消注释
# ---------------------------------------------------------------------------

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> ./feeds.conf.default
# echo "src-git small https://github.com/kenzok8/small" >> ./feeds.conf.default
