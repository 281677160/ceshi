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
rm -rf package/lean
svn export https://github.com/coolsnowwolf/lede/trunk/package/lean package/lean
svn export https://github.com/281677160/luci-theme-argon/branches/18.06 package/luci-theme-argon
svn export https://github.com/281677160/luci-theme-argon/branches/argon-config package/luci-app-argon-config

git clone -b master --depth 1 https://github.com/lisaac/luci-app-dockerman package/luci-app-dockerman
git clone -b packages --depth 1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git clone -b luci --depth 1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
git clone -b master --depth 1 https://github.com/vernesong/OpenClash package/luci-app-openclash
