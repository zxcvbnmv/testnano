#!/bin/bash
clear
# Enable O2 & optimize
sed -i 's/Os/O2/g' ./include/target.mk
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
cp -rf ../immortalwrt_23/target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch ./target/linux/generic/hack-5.15/
# mbedtls
rm -rf ./package/libs/mbedtls
cp -rf ../immortalwrt_23/package/libs/mbedtls ./package/libs/mbedtls
# ## DOH3 ##
cp -rf ../PATCH/openssl/quic/* ./package/libs/openssl/patches
rm -rf feeds/packages/libs/nghttp3
git clone https://github.com/zxcvbnmv/nghttp3-package ./package/libs/nghttp3
rm -rf feeds/packages/libs/ngtcp2
git clone https://github.com/zxcvbnmv/ngtcp2-package ./package/libs/ngtcp2
# patch BBRv3
cp -rf ../PATCH/BBRv3/* ./target/linux/generic/backport-5.15/
# patch nf_conntrack_expect_max
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
# firewall update to Git HEAD (2024-10-18)
rm -rf ./package/network/config/firewall
cp -rf ../openwrt_main/package/network/config/firewall ./package/network/config/firewall
### Fullcone-NAT ###
# Patch Kernel FullCone
cp -rf ../PATCH/firewall/952-add-net-conntrack-events-support-multiple-registrant.patch ./target/linux/generic/hack-5.15/
# ## fw4 fullcone
mkdir -p package/network/config/firewall4/patches
cp -f ../PATCH/firewall/001-fix-fw4-flow-offload.patch ./package/network/config/firewall4/patches
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches
cp -f ../PATCH/firewall/999-01-firewall4-add-fullcone-support.patch ./package/network/config/firewall4/patches
cp -f ../PATCH/firewall/999-02-firewall4-add-bcm-fullconenat-support.patch ./package/network/config/firewall4/patches
mkdir -p package/libs/libnftnl/patches
cp -f ../PATCH/firewall/001-libnftnl-add-fullcone-expression-support.patch ./package/libs/libnftnl/patches
cp -f ../PATCH/firewall/002-libnftnl-add-brcm-fullcone-support.patch ./package/libs/libnftnl/patches
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' ./package/libs/libnftnl/Makefile
mkdir -p package/network/utils/nftables/patches
cp -f ../PATCH/firewall/002-nftables-add-fullcone-expression-support.patch ./package/network/utils/nftables/patches
cp -f ../PATCH/firewall/003-nftables-add-brcm-fullconenat-support.patch ./package/network/utils/nftables/patches
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone ./package/new/nft-fullcone
# ## fw3 fullcone
mkdir -p package/network/config/firewall/patches
cp -rf ../PATCH/firewall/fullconenat.patch ./package/network/config/firewall/patches/fullconenat.patch
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
sed -i '/REQUIRE_IMAGE_METADATA/d' target/linux/rockchip/armv8/base-files/lib/upgrade/platform.sh
# intel-firmware
wget -qO - https://github.com/openwrt/openwrt/commit/9c58addc.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/64f1a657.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1
sed -i '/I915/d' target/linux/x86/64/config-5.15
# SMP
echo '
CONFIG_X86_INTEL_PSTATE=y
CONFIG_SMP=y
' >>./target/linux/x86/config-5.15
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg
### luci app ###
# btf
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/73e56799.patch | patch -p1
cp -rf ../PATCH/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch ./target/linux/generic/backport-5.15/
# bpf_loop
cp -f ../PATCH/bpf_loop/*.patch ./target/linux/generic/backport-5.15/
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
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' ./package/new/autocore/files/luci-mod-status-autocore.json
cp -rf ../PATCH/autocore ./package/new/autocore/files/autocore
sed -i '/i386 i686 x86_64/{n;n;n;d;}' package/new/autocore/Makefile
sed -i '/i386 i686 x86_64/d' package/new/autocore/Makefile
rm -rf ./feeds/luci/modules/luci-base
cp -rf ../immortalwrt_luci_23/modules/luci-base ./feeds/luci/modules/luci-base
sed -i "s,(br-lan),,g" ./feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci
rm -rf ./feeds/luci/modules/luci-mod-status
cp -rf ../immortalwrt_luci_23/modules/luci-mod-status ./feeds/luci/modules/luci-mod-status
rm -rf ./feeds/packages/utils/coremark
cp -rf ../immortalwrt_pkg/utils/coremark ./feeds/packages/utils/coremark
sed -i "s,-O3,-Ofast -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las,g" ./feeds/packages/utils/coremark/Makefile
cp -rf ../immortalwrt_23/package/utils/mhz ./package/utils/mhz
# Add R8168 driver
cp -rf ../immortalwrt/package/kernel/r8168 ./package/new/r8168
# igc-fix
cp -rf ../lede/target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-5.15/
# Golang
rm -rf ./feeds/packages/lang/golang
cp -rf ../openwrt_pkg_main/lang/golang ./feeds/packages/lang/golang
# https-dns-proxy
rm -rf ./feeds/packages/net/https-dns-proxy
git clone https://github.com/zxcvbnmv/https-dns-proxy ./feeds/packages/net/https-dns-proxy
# Arpbind
cp -rf ../immortalwrt_luci/applications/luci-app-arpbind ./feeds/luci/applications/luci-app-arpbind
ln -sf ../../../feeds/luci/applications/luci-app-arpbind ./package/feeds/luci/luci-app-arpbind
# ipv6-helper
cp -rf ../lede/package/lean/ipv6-helper ./package/new/ipv6-helper
patch -p1 < ../PATCH/1002-odhcp6c-support-dhcpv6-hotplug.patch
# Nodejs update
rm -rf feeds/packages/lang/node
git clone https://github.com/sbwml/feeds_packages_lang_node-prebuilt ./feeds/packages/lang/node
# rpcd
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js
# Translate
cp -rf ../PATCH/addition-trans-zh/ ./package/new/addition-trans-zh
# maximize_nic_rx_tx_buffers
mkdir -p ./files/etc && cp -rf ../PATCH/files/etc ./files
# Config
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' ./target/linux/generic/config-5.15
### Shortcut-FE ###
# Patch Kernel Shortcut-FE
cp -rf ../lede/target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ./target/linux/generic/hack-5.15/
cp -rf ../lede/target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-5.15/
cp -rf ../PATCH/601-netfilter-export-udp_get_timeouts-function.patch ./target/linux/generic/hack-5.15/
# SFE-switch
patch -p1 <../PATCH/firewall/luci-app-firewall_add_sfe_switch.patch
# Shortcut-FE module
mkdir ./package/lean
mkdir ./package/lean/shortcut-fe
cp -rf ../lede/package/qca/shortcut-fe/fast-classifier ./package/lean/shortcut-fe/fast-classifier
wget -qO - https://github.com/coolsnowwolf/lede/commit/331f04fb.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/232b8b43.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/ec795c96.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/789f805c.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/63981680.patch | patch -p1
cp -rf ../lede/package/qca/shortcut-fe/shortcut-fe ./package/lean/shortcut-fe/shortcut-fe
wget -qO - https://github.com/coolsnowwolf/lede/commit/0e29809a.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/eb70dada.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/7ba3ec09.patch | patch -p1
cp -rf ../lede/package/qca/shortcut-fe/simulated-driver ./package/lean/shortcut-fe/simulated-driver
# natflow
git clone https://github.com/zxcvbnmv/natflow-package.git ./package/new/natflow
mkdir ./package/new/natflow/patches
cp -rf ../PATCH/natflow_Revert.patch ./package/new/natflow/patches
patch -p1 < ../PATCH/firewall/luci-app-firewall_add_natflow_switch.patch
#LTO/GC
# Grub 2
sed -i 's,no-lto,no-lto no-gc-sections,g' package/boot/grub2/Makefile
# openssl disable LTO
sed -i 's,no-mips16 gc-sections,no-mips16 gc-sections no-lto,g' package/libs/openssl/Makefile
# libsodium
sed -i 's,no-mips16,no-mips16 no-lto,g' feeds/packages/libs/libsodium/Makefile

# ################### temporary settings ###################
# iptables-1.8.10 patch
curl -s https://raw.githubusercontent.com/openwrt/openwrt/16601bbd/package/network/utils/iptables/Makefile > package/network/utils/iptables/Makefile
rm ./package/network/utils/iptables/patches/104-nft-track-each-register-individually.patch
wget -qO - https://github.com/openwrt/openwrt/commit/d06955d2.patch | patch -p1
# luci dhcp.js rollback
curl -s https://raw.githubusercontent.com/zxcvbnmv/testnano/main/PATCH/dhcp.js > feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/dhcp.js
# fstools update
rm -rf ./package/system/fstools
git clone https://github.com/sbwml/package_system_fstools ./package/system/fstools
# ppp update
rm -rf ./package/network/services/ppp
git clone https://github.com/sbwml/package_network_services_ppp ./package/network/services/ppp
# curl update
rm -rf ./feeds/packages/net/curl
git clone https://github.com/sbwml/feeds_packages_net_curl ./feeds/packages/net/curl
# nghttp2 update
rm -rf ./feeds/packages/libs/nghttp2
cp -rf ../openwrt_pkg_main/libs/nghttp2 ./feeds/packages/libs/nghttp2
# odhcpd update
rm -rf ./package/network/services/odhcpd
cp -rf ../immortalwrt/package/network/services/odhcpd ./package/network/services/odhcpd
