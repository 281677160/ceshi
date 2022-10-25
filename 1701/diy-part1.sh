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

svn export https://github.com/Lienol/openwrt/branches/21.02/package/default-settings package/default-settings

svn export https://github.com/281677160/luci-theme-argon/branches/21.02 package/luci-theme-argon
svn export https://github.com/281677160/luci-theme-argon/branches/argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld
svn co https://github.com/immortalwrt/packages/trunk/net/redsocks2 package/redsocks2
git clone -b packages --depth 1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git clone -b luci --depth 1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
git clone -b dev --depth 1 https://github.com/vernesong/OpenClash package/luci-app-openclash


curl -fsSL https://raw.githubusercontent.com/281677160/common/main/Convert/zh_Hans.sh > zh_Hans.sh
chmod +x zh_Hans.sh
/bin/bash zh_Hans.sh
rm -rf zh_Hans.sh
