#!/bin/bash
clear
# Enable O2 & optimize
sed -i 's/Os/O2/g' include/target.mk
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a
# LAN port IP
sed -i 's/192.168.1.1/192.168.2.10/g' package/base-files/files/bin/config_generate
# sysctl
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# TCP optimizations
cp -rf ../PATCH/backport/TCP/* ./target/linux/generic/backport-5.15/
# x86_csum
cp -rf ../PATCH/backport/x86_csum/* ./target/linux/generic/backport-5.15/
# Patch arm64 name
cp -rf ../immortalwrt/target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch ./target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# LRNG
cp -rf ../PATCH/LRNG/* ./target/linux/generic/hack-5.15/
echo '
# CONFIG_RANDOM_DEFAULT_IMPL is not set
CONFIG_LRNG=y
# CONFIG_LRNG_IRQ is not set
CONFIG_LRNG_JENT=y
CONFIG_LRNG_CPU=y
# CONFIG_LRNG_SCHED is not set
' >>./target/linux/generic/config-5.15
# mbedtls
rm -rf ./package/libs/mbedtls
cp -rf ../immortalwrt/package/libs/mbedtls ./package/libs/mbedtls
# ## DOH3 ##
rm -rf package/libs/openssl
cp -rf ../stangri/quictls package/libs/openssl
rm -rf feeds/packages/libs/nghttp3
git clone https://github.com/zxcvbnmv/nghttp3-package package/libs/nghttp3
rm -rf feeds/packages/libs/ngtcp2
git clone https://github.com/zxcvbnmv/ngtcp2-package package/libs/ngtcp2
# fstool
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
# patch BBRv3
cp -rf ../PATCH/BBRv3/* ./target/linux/generic/backport-5.15/
# patch nf_conntrack_expect_max
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
### Fullcone-NAT ###
# Patch Kernel FullCone
cp -rf ../lede/target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch ./target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch
cp -rf ../lede/target/linux/generic/hack-5.15/982-add-bcm-fullconenat-support.patch ./target/linux/generic/hack-5.15/982-add-bcm-fullconenat-support.patch
# ##FW4
mkdir -p package/network/config/firewall4/patches
cp -f ../PATCH/firewall/001-fix-fw4-flow-offload.patch ./package/network/config/firewall4/patches/001-fix-fw4-flow-offload.patch
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
cp -f ../PATCH/firewall/999-01-firewall4-add-fullcone-support.patch ./package/network/config/firewall4/patches/999-01-firewall4-add-fullcone-support.patch
mkdir -p package/libs/libnftnl/patches
cp -f ../PATCH/firewall/001-libnftnl-add-fullcone-expression-support.patch ./package/libs/libnftnl/patches/001-libnftnl-add-fullcone-expression-support.patch
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
mkdir -p package/network/utils/nftables/patches
cp -f ../PATCH/firewall/002-nftables-add-fullcone-expression-support.patch ./package/network/utils/nftables/patches/002-nftables-add-fullcone-expression-support.patch
# Nftables fullcone expression kernel module
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone package/new/nft-fullcone
# ##FW3
mkdir -p package/network/config/firewall/patches
# #lean's high connection fullconenat .fw3
cp -rf ../lede/package/network/config/firewall/patches/100-fullconenat.patch ./package/network/config/firewall/patches/100-fullconenat.patch
cp -rf ../lede/package/network/config/firewall/patches/101-bcm-fullconenat.patch ./package/network/config/firewall/patches/101-bcm-fullconenat.patch
cp -rf ../lede/package/network/utils/iptables/patches/900-bcm-fullconenat.patch ./package/network/utils/iptables/patches/900-bcm-fullconenat.patch
# iptables fullcone module
cp -rf ../PATCH/fullconenat ./package/new/fullconenat
# Patch LuCI FullCone switch
pushd feeds/luci
patch -p1 <../../../PATCH/firewall/luci-app-firewall_add_fullcone_fw3.patch
popd
### basic package ###
# Make target for support NanoPi R4S
rm -rf ./target/linux/rockchip
cp -rf ../immortalwrt_23/target/linux/rockchip ./target/linux/rockchip
cp -rf ../PATCH/rockchip-5.15/* ./target/linux/rockchip/patches-5.15/
rm -rf ./package/boot/uboot-rockchip
cp -rf ../immortalwrt_23/package/boot/uboot-rockchip ./package/boot/uboot-rockchip
rm -rf ./package/boot/arm-trusted-firmware-rockchip
cp -rf ../immortalwrt_23/package/boot/arm-trusted-firmware-rockchip ./package/boot/arm-trusted-firmware-rockchip
rm ./target/linux/rockchip/patches-5.15/992-rockchip-rk3399-overclock-to-2.2-1.8-GHz.patch
cp -f ../PATCH/766-rk3399-overclock.patch ./target/linux/rockchip/patches-5.15/
cp -f ../PATCH/249-rk3399dtsi.patch ./target/linux/rockchip/patches-5.15/
sed -i 's,DEFAULT_GOV_SCHEDUTIL,DEFAULT_GOV_PERFORMANCE,g' target/linux/rockchip/armv8/config-5.15
sed -i 's,# CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE,# CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL,g' target/linux/rockchip/armv8/config-5.15
sed -i '/CONFIG_SLUB_DEBUG/d' target/linux/rockchip/armv8/config-5.15
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/7817745a.patch | patch -p1
# intel-firmware
wget -qO - https://github.com/openwrt/openwrt/commit/9c58add.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/64f1a65.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/c21a357.patch | patch -p1
sed -i '/I915/d' target/linux/x86/64/config-5.15
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/mmc.bootscript
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg
### luci app ###
# btf
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/73e5679.patch | patch -p1
wget https://github.com/immortalwrt/immortalwrt/raw/openwrt-23.05/target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch -O target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch
# mount cgroupv2
pushd feeds/packages
patch -p1 <../../../PATCH/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ../PATCH/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ../PATCH/cgroupfs-mount/901-fix-cgroupfs-umount.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ../PATCH/cgroupfs-mount/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch ./feeds/packages/utils/cgroupfs-mount/patches/
# AutoCore & coremark
cp -rf ../immortalwrt_23/package/emortal/autocore ./package/new/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/new/autocore/files/luci-mod-status-autocore.json
cp -rf ../PATCH/autocore ./package/new/autocore/files/autocore
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
# Add R8168 driver
git clone -b master --depth 1 https://github.com/BROBIRD/openwrt-r8168.git package/new/r8168
patch -p1 <../PATCH/r8168/r8168-fix_LAN_led-for_r4s-from_TL.patch
# igc-fix
cp -rf ../lede/target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch
# Golang
rm -rf ./feeds/packages/lang/golang
cp -rf ../openwrt_pkg_ma/lang/golang ./feeds/packages/lang/golang
# Arpbind
cp -rf ../immortalwrt_luci/applications/luci-app-arpbind ./feeds/luci/applications/luci-app-arpbind
ln -sf ../../../feeds/luci/applications/luci-app-arpbind ./package/feeds/luci/luci-app-arpbind
# ipv6-helper
cp -rf ../lede/package/lean/ipv6-helper ./package/new/ipv6-helper
patch -p1 <../PATCH/1002-odhcp6c-support-dhcpv6-hotplug.patch
# Nodejs update
rm -rf feeds/packages/lang/node
git clone https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node
# rpcd
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js
# Translate
cp -rf ../PATCH/addition-trans-zh/ ./package/new/addition-trans-zh
# maximize_nic_rx_tx_buffers
mkdir -p ./files/etc && cp -rf ../PATCH/files/etc ./files
# Config
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-5.15
### Shortcut-FE ###
# Patch Kernel Shortcut-FE
cp -rf ../lede/target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ./target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
cp -rf ../lede/target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch
# SFE-switch
patch -p1 < ../PATCH/firewall/luci-app-firewall_add_sfe_switch.patch
# Shortcut-FE module
mkdir ./package/lean
mkdir ./package/lean/shortcut-fe
cp -rf ../lede/package/lean/shortcut-fe/fast-classifier ./package/lean/shortcut-fe/fast-classifier
wget -qO - https://github.com/coolsnowwolf/lede/commit/331f04f.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/232b8b4.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/ec795c9.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/789f805.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/6398168.patch | patch -p1
cp -rf ../lede/package/lean/shortcut-fe/shortcut-fe ./package/lean/shortcut-fe/shortcut-fe
wget -qO - https://github.com/coolsnowwolf/lede/commit/0e29809a.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/eb70dad.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/7ba3ec0.patch | patch -p1
cp -rf ../lede/package/lean/shortcut-fe/simulated-driver ./package/lean/shortcut-fe/simulated-driver
#LTO/GC
# Grub 2
sed -i 's,no-lto,no-lto no-gc-sections,g' package/boot/grub2/Makefile
# openssl disable LTO
sed -i 's,no-mips16 gc-sections,no-mips16 gc-sections no-lto,g' package/libs/openssl/Makefile
# libsodium
sed -i 's,no-mips16,no-mips16 no-lto,g' feeds/packages/libs/libsodium/Makefile
# ################### temporary settings ###################
# iptables-1.8.9 patch
cp -rf ../PATCH/firewall/Fix-bad-IP-address-error-reporting.patch package/network/utils/iptables/patches
# ppp update
rm -rf package/network/services/ppp
git clone https://github.com/sbwml/package_network_services_ppp package/network/services/ppp

#exit
