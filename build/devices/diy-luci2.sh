
#!/bin/bash
#======================================================
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# DIY扩展二合一了，在此处可以增加插件,可修改IP,修改源码
# diy-luci2.sh  LUCI2源码使用
#======================================================


#1. 修改固件后台IP,把'192.168.2.2'改成您想要的就行
export IPV4_IPADDR="192.168.2.2"

#2. 首次进入固件免密登录设置(填1为启用)
export DELETE_LOGIN_PASSWORD="1"

#3. 编译时改成默认中文LUCI(填1为启用)
export DEFAULT_CHINESE_LANGUAGE="0"

#4. 清理[X]天之前的Artifacts
export RETAIN_DAYS="7"

#5. 保留[X]个Releases不被删除
export KEEP_LATEST="10"


# 设置打包固件的机型和内核组合（可用内核是时时变化的,过老的内核就删除的，所以要选择什么内核请看说明）
# export amlogic_model="此内填入可用芯片，或多芯片组合。比如：s905d 或 s905d_s905x2"
# export amlogic_kernel="此内填入内核，或者多内核组合。比如：5.4.233 或 5.4.233_6.1.14"
# export auto_kernel="true" 是否自动检测最新内核来打包（true为是，false为不是）
# 自动检测最新内核,比如您写的是 5.15.25 当前最高版本为 5.15.78 的话就自动打包5.15.78的,不自动检测的话,就打包 5.15.25
# export rootfs_size="填入不低于500的数值，数值越大空间越大，一般960够了"
# export kernel_repo="上游内核存放仓库，默认是https://github.com/ophub/kernel/tree/kernel_stable/pub"
# 可用芯片如下：
# a311d,s922x,s922x-reva,s922x-ct2000,s905x3,s905x3-b,s905x2,s912,s912-m8s,tqc-a01,tanix-tx6,
# s905d,s905d-ki,s905x,s905w,s905,s905l2,s905l3,s905l3a,s905l3b,s905lb-r3300l,rock5b,
# h88k,r66s,r68s,h66k,h68k,e25,eaidk-610,king3399,tn3399,kylin3399,beikeyun,l1pro,vplus
# 对应支持什么机型，也不是所有芯片组都可以打包所有版本内核的，有个别分内核版本，请看说明
# 可选内核 （5.4.xx） （5.10.xx） （5.15.xx） （6.1.xx）

export amlogic_model="s905d"
export amlogic_kernel="5.10.01_6.1.01"
export auto_kernel="true"
export rootfs_size="960"
export kernel_repo="https://github.com/ophub/kernel/tree/kernel_stable/pub"
