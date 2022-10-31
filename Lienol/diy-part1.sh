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
rm -rf feeds/packages/libs/libcap && svn co https://github.com/281677160/openwrt-package/branches/usb/libs/libcap feeds/packages/libs/libcap
