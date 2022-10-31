#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

curl -fsSL https://raw.githubusercontent.com/281677160/openwrt-package/usb/libs/package/network/utils/iproute2/Makefile > package/network/utils/iproute2/Makefile
curl -fsSL https://raw.githubusercontent.com/281677160/openwrt-package/usb/libs/package/kernel/linux/modules/netsupport.mk > package/kernel/linux/modules/netsupport.mk
svn co https://github.com/coolsnowwolf/packages/trunk/net/kcptun feeds/packages/net/kcptun
svn co https://github.com/immortalwrt/packages/trunk/net/redsocks2  feeds/packages/net/redsocks2
git clone -b 18.06 https://github.com/281677160/luci-theme-argon package/luci-theme-argon
git clone -b master --depth 1 https://github.com/vernesong/OpenClash package/luci-app-openclash
rm -rf  feeds/packages/libs/libcap && svn co https://github.com/281677160/openwrt-package/branches/usb/libs/libcap feeds/packages/libs/libcap
