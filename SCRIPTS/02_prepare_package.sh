#!/bin/bash
clear

### 基础部分 ###
# 使用 O2 级别的优化
sed -i 's/Os/O2/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
# 默认开启 Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# 移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
# 维多利亚的秘密
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf

### 必要的 Patches ###
# TCP optimizations
cp -rf ../PATCH/backport/TCP/* ./target/linux/generic/backport-5.15/
# x86_csum
cp -rf ../PATCH/backport/x86_csum/* ./target/linux/generic/backport-5.15/
# Patch arm64 型号名称
cp -rf ../immortalwrt/target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch ./target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch

# LRNG
cp -rf ../PATCH/LRNG/* ./target/linux/generic/hack-5.15/
echo '
CONFIG_LRNG=y
' >>./target/linux/generic/config-5.15
# SSL
rm -rf ./package/libs/mbedtls
cp -rf ../immortalwrt/package/libs/mbedtls ./package/libs/mbedtls
# fstool
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1


### Fullcone-NAT 部分 ###
# Patch Kernel 以解决 FullCone 冲突
cp -rf ../lede/target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch ./target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch
cp -rf ../lede/target/linux/generic/hack-5.15/982-add-bcm-fullconenat-support.patch ./target/linux/generic/hack-5.15/982-add-bcm-fullconenat-support.patch
# Patch FireWall 以增添 FullCone 功能
# FW4
rm -rf ./package/network/config/firewall4
cp -rf ../immortalwrt/package/network/config/firewall4 ./package/network/config/firewall4
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
cp -f ../PATCH/firewall/001-fix-fw4-flow-offload.patch ./package/network/config/firewall4/patches/001-fix-fw4-flow-offload.patch
rm -rf ./package/libs/libnftnl
cp -rf ../immortalwrt/package/libs/libnftnl ./package/libs/libnftnl
rm -rf ./package/network/utils/nftables
cp -rf ../immortalwrt/package/network/utils/nftables ./package/network/utils/nftables
# FW3
# iptables
cp -rf ../lede/package/network/utils/iptables/patches/900-bcm-fullconenat.patch ./package/network/utils/iptables/patches/900-bcm-fullconenat.patch
# network
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
# Patch LuCI 以增添 FullCone 开关
pushd feeds/luci
wget -qO- https://github.com/openwrt/luci/commit/471182b2.patch | patch -p1
popd
# FullCone PKG
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone package/new/nft-fullcone
cp -rf ../Lienol/package/network/utils/fullconenat ./package/new/fullconenat

### 获取额外的基础软件包 ###
# 更换为 ImmortalWrt Uboot 以及 Target
rm -rf ./target/linux/rockchip
cp -rf ../immortalwrt_23/target/linux/rockchip ./target/linux/rockchip
cp -rf ../PATCH/rockchip-5.15/* ./target/linux/rockchip/patches-5.15/
rm -rf ./package/boot/uboot-rockchip
cp -rf ../immortalwrt_23/package/boot/uboot-rockchip ./package/boot/uboot-rockchip
rm -rf ./package/boot/arm-trusted-firmware-rockchip
cp -rf ../immortalwrt_23/package/boot/arm-trusted-firmware-rockchip ./package/boot/arm-trusted-firmware-rockchip
#intel-firmware
wget -qO - https://github.com/openwrt/openwrt/commit/9c58add.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/64f1a65.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1
sed -i '/I915/d' target/linux/x86/64/config-5.15
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/mmc.bootscript
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg


### 获取额外的 LuCI 应用、主题和依赖 ###
# xdp
wget -qO - https://github.com/openwrt/openwrt/commit/47ea58b.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/ce3082d.patch | patch -p1
wget https://github.com/immortalwrt/immortalwrt/raw/openwrt-23.05/target/linux/generic/hack-5.15/901-debloat_sock_diag.patch -O target/linux/generic/hack-5.15/901-debloat_sock_diag.patch
# btf
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/73e5679.patch | patch -p1
wget https://github.com/immortalwrt/immortalwrt/raw/openwrt-23.05/target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch -O target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch
# mount cgroupv2
pushd feeds/packages
patch -p1 <../../../PATCH/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ../PATCH/cgroupfs-mount/900-add-cgroupfs2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
# AutoCore
cp -rf ../immortalwrt_23/package/emortal/autocore ./package/new/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/new/autocore/files/luci-mod-status-autocore.json
cp -rf ../OpenWrt-Add/autocore/files/x86/autocore ./package/new/autocore/files/autocore
sed -i '/i386 i686 x86_64/{n;n;n;d;}' package/new/autocore/Makefile
sed -i '/i386 i686 x86_64/d' package/new/autocore/Makefile
rm -rf ./feeds/luci/modules/luci-base
cp -rf ../immortalwrt_luci_23/modules/luci-base ./feeds/luci/modules/luci-base
sed -i "s,(br-lan),,g" feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci
rm -rf ./feeds/luci/modules/luci-mod-status
cp -rf ../immortalwrt_luci_23/modules/luci-mod-status ./feeds/luci/modules/luci-mod-status
rm -rf ./feeds/packages/utils/coremark
cp -rf ../immortalwrt_pkg/utils/coremark ./feeds/packages/utils/coremark
sed -i "s,-O3,-Ofast -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las,g" feeds/packages/utils/coremark/Makefile
cp -rf ../immortalwrt_23/package/utils/mhz ./package/utils/mhz

# luci-app-irqbalance
cp -rf ../OpenWrt-Add/luci-app-irqbalance ./package/new/luci-app-irqbalance

# R8168驱动
git clone -b master --depth 1 https://github.com/BROBIRD/openwrt-r8168.git package/new/r8168
patch -p1 <../PATCH/r8168/r8168-fix_LAN_led-for_r4s-from_TL.patch
# R8152驱动
cp -rf ../immortalwrt/package/kernel/r8152 ./package/new/r8152
# r8125驱动
git clone https://github.com/sbwml/package_kernel_r8125 package/new/r8125
# igc-fix
cp -rf ../lede/target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch
# MAC 地址与 IP 绑定
cp -rf ../immortalwrt_luci/applications/luci-app-arpbind ./feeds/luci/applications/luci-app-arpbind
ln -sf ../../../feeds/luci/applications/luci-app-arpbind ./package/feeds/luci/luci-app-arpbind

# Dnsproxy
cp -rf ../OpenWrt-Add/luci-app-dnsproxy ./package/new/luci-app-dnsproxy
# Edge 主题
git clone -b master --depth 1 https://github.com/kiddin9/luci-theme-edge.git package/new/luci-theme-edge
# FRP 内网穿透
rm -rf ./feeds/luci/applications/luci-app-frps
rm -rf ./feeds/luci/applications/luci-app-frpc
rm -rf ./feeds/packages/net/frp
rm -f ./package/feeds/packages/frp
cp -rf ../lede_luci/applications/luci-app-frps ./package/new/luci-app-frps
cp -rf ../lede_luci/applications/luci-app-frpc ./package/new/luci-app-frpc
cp -rf ../lede_pkg/net/frp ./package/new/frp

# IPv6 兼容助手
cp -rf ../lede/package/lean/ipv6-helper ./package/new/ipv6-helper

# rpcd
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js
# 翻译及部分功能优化
cp -rf ../OpenWrt-Add/addition-trans-zh ./package/new/addition-trans-zh
sed -i 's,iptables-mod-fullconenat,iptables-nft +kmod-nft-fullcone,g' package/new/addition-trans-zh/Makefile

# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-5.15

### Shortcut-FE 部分 ###
# Patch Kernel 以支持 Shortcut-FE
cp -rf ../lede/target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ./target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
cp -rf ../lede/target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch
# Patch LuCI 以增添 Shortcut-FE 开关
patch -p1 < ../PATCH/firewall/luci-app-firewall_add_sfe_switch.patch
# Shortcut-FE 相关组件
mkdir ./package/lean
mkdir ./package/lean/shortcut-fe
cp -rf ../lede/package/lean/shortcut-fe/fast-classifier ./package/lean/shortcut-fe/fast-classifier
wget -qO - https://github.com/coolsnowwolf/lede/commit/331f04f.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/232b8b4.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/ec795c9.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/789f805.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/6398168.patch | patch -p1
cp -rf ../lede/package/lean/shortcut-fe/shortcut-fe ./package/lean/shortcut-fe/shortcut-fe
wget -qO - https://github.com/coolsnowwolf/lede/commit/0e29809.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/eb70dad.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/7ba3ec0.patch | patch -p1
cp -rf ../lede/package/lean/shortcut-fe/simulated-driver ./package/lean/shortcut-fe/simulated-driver

#exit 0
