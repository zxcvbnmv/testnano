#!/bin/bash

clone_repo() {
  repo_url=$1
  branch_name=$2
  target_dir=$3
  git clone -b $branch_name --depth 1 $repo_url $target_dir
}

#
#latest_release="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][3-9]/p' | sed -n 1p | sed 's/.tar.gz//g')"
latest_release="v23.05.0"
openwrt_repo="https://github.com/openwrt/openwrt.git"
openwrt_pkg_repo="https://github.com/openwrt/packages.git"
openwrt_luci_repo="https://github.com/openwrt/luci.git"
immortalwrt_repo="https://github.com/immortalwrt/immortalwrt.git"
immortalwrt_pkg_repo="https://github.com/immortalwrt/packages.git"
immortalwrt_luci_repo="https://github.com/immortalwrt/luci.git"
lede_repo="https://github.com/coolsnowwolf/lede.git"
lede_luci_repo="https://github.com/coolsnowwolf/luci.git"
lede_pkg_repo="https://github.com/coolsnowwolf/packages.git"

# clone
clone_repo $openwrt_repo $latest_release openwrt &
clone_repo $openwrt_repo openwrt-23.05 openwrt_snap &
clone_repo $openwrt_repo main openwrt_main &
clone_repo $openwrt_pkg_repo master openwrt_pkg_ma &
clone_repo $openwrt_luci_repo master openwrt_luci_ma &
clone_repo $immortalwrt_repo master immortalwrt &
clone_repo $immortalwrt_repo openwrt-23.05 immortalwrt_23 &
clone_repo $immortalwrt_pkg_repo master immortalwrt_pkg &
clone_repo $immortalwrt_luci_repo master immortalwrt_luci &
clone_repo $immortalwrt_luci_repo openwrt-23.05 immortalwrt_luci_23 &
clone_repo $lede_repo master lede &
clone_repo $lede_luci_repo master lede_luci &
clone_repo $lede_pkg_repo master lede_pkg &

#
wait

#
find openwrt/package/* -maxdepth 0 ! -name 'firmware' ! -name 'kernel' ! -name 'base-files' ! -name 'Makefile' -exec rm -rf {} +
rm -rf ./openwrt_snap/package/firmware ./openwrt_snap/package/kernel ./openwrt_snap/package/base-files ./openwrt_snap/package/Makefile
cp -rf ./openwrt_snap/package/* ./openwrt/package/
cp -rf ./openwrt_snap/feeds.conf.default ./openwrt/feeds.conf.default

exit 0
