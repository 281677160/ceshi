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

git clone -b packages --depth 1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git clone -b luci --depth 1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
git clone -b master --depth 1 https://github.com/vernesong/OpenClash package/luci-app-openclash
