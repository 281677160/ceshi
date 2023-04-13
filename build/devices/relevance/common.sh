#!/bin/bash

function Package_settings() {
export HOME_PATH="$GITHUB_WORKSPACE/openwrt"
cp -Rf $GITHUB_WORKSPACE/build/${FOLDER_NAME} ${HOME_PATH}/build
cp -Rf ${HOME_PATH}/build/relevance/*.sh ${HOME_PATH}/build/
sudo chmod -R +x ${HOME_PATH}/build
echo "HOME_PATH=${HOME_PATH}" >> $GITHUB_ENV
echo "BUILD_PATH=${HOME_PATH}/build" >> $GITHUB_ENV
cd ${HOME_PATH}
./scripts/feeds update -a > /dev/null 2>&1

sed -i 's/root:.*/root::0:0:99999:7:::/g' ${HOME_PATH}/package/base-files/files/etc/shadow
if [[ `grep -Eoc "admin:.*" ${HOME_PATH}/package/base-files/files/etc/shadow` -eq '1' ]]; then
  sed -i 's/admin:.*/admin::0:0:99999:7:::/g' ${HOME_PATH}/package/base-files/files/etc/shadow
fi

if [[ -d "${HOME_PATH}/extra" ]]; then
  apptions="$(find "${HOME_PATH}/extra" -type d -name "applications"  |grep 'luci')"
else
  apptions="$(find "${HOME_PATH}/feeds" -type d -name "applications"  |grep 'luci')"
fi
if [[ `find "${apptions}" -type d -name "zh_Hans" |grep -c "zh_Hans"` -gt '20' ]]; then
  applica="1"
  echo "DIY_PART_SH=diy-luci2.sh" >> ${GITHUB_ENV}
else
  applica="2"
  echo "DIY_PART_SH=diy-luci1.sh" >> ${GITHUB_ENV}
fi

settingss="$(find "${HOME_PATH}/package" -type d -name "default-settings")"
if [[ ! -d "${settingss}" ]] && [[ "${applica}" == "1" ]]; then
  svn export https://github.com/281677160/common/trunk/OFFICIAL/default-settings ${HOME_PATH}/package/default-settings > /dev/null 2>&1
elif [[ ! -d "${settingss}" ]] && [[ "${applica}" == "2" ]]; then
  svn export https://github.com/281677160/common/trunk/COOLSNOWWOLF/default-settings ${HOME_PATH}/package/default-settings > /dev/null 2>&1
fi

if [[ -f "${HOME_PATH}/feeds/luci/applications/luci-app-ttyd/luasrc/controller/ttyd.lua" ]]; then
  sed -i "s/+luci-lib-base //g" ${HOME_PATH}/package/default-settings/Makefile
fi

export ZZZL_PATH="$(find ./package -type f -name "*default-settings" |grep files |cut -d '/' -f2-)"
echo "ZZZ_PATH=${HOME_PATH}/${ZZZL_PATH}" >> $GITHUB_ENV
}


function Diy_partsh() {
[[ -f "${BUILD_PATH}/feeds.conf.default" ]] && mv -f ${BUILD_PATH}/feeds.conf.default ${HOME_PATH}/feeds.conf.default
[[ -d "${BUILD_PATH}/diy" ]] && cp -Rf ${BUILD_PATH}/diy/* ${HOME_PATH}/
[[ -d "${BUILD_PATH}/files" ]] && mv -f ${BUILD_PATH}/files ${HOME_PATH}/files
if [[ -d "${BUILD_PATH}/patches" ]]; then
  find "${BUILD_PATH}/patches" -type f -name '*.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "cat '%'  | patch -d './' -p1 --forward --no-backup-if-mismatch"
fi

source ${BUILD_PATH}/${DIY_PART_SH}

GENERATE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
IPADDR="$(grep "ipaddr:-" "${GENERATE_PATH}" |grep -v 'addr_offset' |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
if [[ -n "${IPV4_IPADDR}" ]]; then
  if [[ -n "$(echo ${IPV4_IPADDR} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")" ]]; then
    if [[ "${IPADDR}" != "${IPV4_IPADDR}" ]]; then
      sed -i "s/${IPADDR}/${IPV4_IPADDR}/g" "${GENERATE_PATH}"
      echo "IPV4_IPADDR=${IPV4_IPADDR}" >> ${GITHUB_ENV}
    else
      echo "IPV4_IPADDR=${IPADDR}" >> ${GITHUB_ENV}
    fi
  else
    echo "${IPADDR}"
    echo "IPV4_IPADDR=${IPADDR}" >> ${GITHUB_ENV}
  fi
fi

if [[ "${DELETE_LOGIN_PASSWORD}" == "1" ]] && [[ -f "${ZZZ_PATH}" ]]; then
  sed -i '/CYXluq4wUazHjmCDBCqXF/d' "${ZZZ_PATH}"
  echo "DELETE_LOGIN_PASSWORD=1" >> ${GITHUB_ENV}
else
  echo "DELETE_LOGIN_PASSWORD=0" >> ${GITHUB_ENV}
fi

if [[ -n "${RETAIN_DAYS}" ]]; then
  echo "RETAIN_DAYS=${RETAIN_DAYS}" >> ${GITHUB_ENV}
else
  echo "RETAIN_DAYS=90" >> ${GITHUB_ENV}
fi

if [[ -n "${KEEP_LATEST}" ]]; then
  echo "KEEP_LATEST=${KEEP_LATEST}" >> ${GITHUB_ENV}
else
  echo "KEEP_LATEST=199" >> ${GITHUB_ENV}
fi

if [[ "${DIY_PART_SH}" == "diy-luci2.sh" ]]; then
  cp -Rf ${BUILD_PATH}/zh_Hans.sh ${HOME_PATH}/zh_Hans.sh
  /bin/bash ${HOME_PATH}/zh_Hans.sh
fi

if [[ "${DEFAULT_CHINESE_LANGUAGE}" == "1" ]]; then
  echo "DEFAULT_CHINESE_LANGUAGE=1" >> $GITHUB_ENV
else
  echo "DEFAULT_CHINESE_LANGUAGE=0" >> $GITHUB_ENV
fi

if [[ -n "${amlogic_model}" ]]; then
  echo "amlogic_model=${amlogic_model}" >> ${GITHUB_ENV}
fi
if [[ -n "${amlogic_kernel}" ]]; then
  echo "amlogic_kernel=${amlogic_kernel}" >> ${GITHUB_ENV}
fi
if [[ -n "${auto_kernel}" ]]; then
  echo "auto_kernel=${auto_kernel}" >> ${GITHUB_ENV}
fi
if [[ -n "${rootfs_size}" ]]; then
  echo "rootfs_size=${rootfs_size}" >> ${GITHUB_ENV}
fi
if [[ -n "${kernel_repo}" ]]; then
  echo "kernel_repo=${kernel_repo}" >> ${GITHUB_ENV}
fi
}


function Diy_config() {
if [[ -f "${BUILD_PATH}/${CONFIG_FILE}" ]]; then
  cp -Rf ${BUILD_PATH}/${CONFIG_FILE} ${HOME_PATH}/.config
fi

if [[ "${DEFAULT_CHINESE_LANGUAGE}" == "1" ]]; then
  echo "CONFIG_PACKAGE_luci=y" >> ${HOME_PATH}/.config
  echo "CONFIG_PACKAGE_default-settings=y" >> ${HOME_PATH}/.config
  echo "CONFIG_PACKAGE_default-settings-chn=y" >> ${HOME_PATH}/.config
  [[ -f "${ZZZ_PATH}" ]] && sed -i "s?main.lang=.*?main.lang='zh_cn'?g" "${ZZZ_PATH}"
fi

make defconfig > /dev/null 2>&1
export TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' ${HOME_PATH}/.config)"
export TARGET_SUBTARGET="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' ${HOME_PATH}/.config)"
export TARGET_PROFILE_DG="$(awk -F '[="]+' '/TARGET_PROFILE/{print $2}' ${HOME_PATH}/.config)"
export REPAIR_PATH="${HOME_PATH}/package/base-files/files/etc/openwrt_release"
export FIRMWARE_PATH="${HOME_PATH}/bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}"
if [[ `grep -c 'CONFIG_TARGET_x86_64=y' ${HOME_PATH}/.config` -eq '1' ]]; then
  export TARGET_PROFILE="x86-64"
elif [[ `grep -c 'CONFIG_TARGET_x86=y' ${HOME_PATH}/.config` -eq '1' ]]; then
  export TARGET_PROFILE="x86-32"
elif [[ `grep -c 'CONFIG_TARGET_armvirt_64_Default=y' ${HOME_PATH}/.config` -eq '1' ]]; then
  export TARGET_PROFILE="Armvirt_64"
  echo "CONFIG_TARGET_ROOTFS_TARGZ=y" >> "${HOME_PATH}/.config"
  echo -e "\nDISTRIB_SOURCECODE='${SOURCE}_${LUCI_VERSION}'" >> "${REPAIR_PATH}" && sed -i '/^\s*$/d' "${REPAIR_PATH}"
elif [[ `grep -c "CONFIG_TARGET.*DEVICE.*=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  export TARGET_PROFILE="$(grep -Eo "CONFIG_TARGET.*DEVICE.*=y" ${HOME_PATH}/.config | sed -r 's/.*DEVICE_(.*)=y/\1/')"
else
  export TARGET_PROFILE="${TARGET_PROFILE_DG}"
fi

echo "TARGET_BOARD=${TARGET_BOARD}" >> ${GITHUB_ENV}
echo "TARGET_SUBTARGET=${TARGET_SUBTARGET}" >> ${GITHUB_ENV}
echo "TARGET_PROFILE=${TARGET_PROFILE}" >> ${GITHUB_ENV}
echo "FIRMWARE_PATH=${FIRMWARE_PATH}" >> ${GITHUB_ENV}
}

function Diy_armvirt() {
if [[ "${PACKAGING_FIRMWARE}" == "true" ]] && [[ `grep -c 'CONFIG_TARGET_armvirt_64_Default=y' ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `ls -1 |grep -v "ipk" |grep -c ".tar.gz"` -eq '1' ]]; then
    echo "FIRMWARE=*rootfs.tar.gz" >> $GITHUB_ENV
    echo "DABAO_RELEASE=${UPLOAD_RELEASE}" >> $GITHUB_ENV
    echo "UPLOAD_RELEASE=true" >> $GITHUB_ENV
    echo "FILE_TAG=targz" >> $GITHUB_ENV
    echo "FILE_NAME=armvirt-64-default-rootfs.tar.gz" >> $GITHUB_ENV
    if [[ `ls -1 | grep -c "immortalwrt"` -ge '1' ]]; then
      rename -v "s/^immortalwrt/${SOURCE}/" *
    else
      rename -v "s/^openwrt/${SOURCE}/" *
    fi
  else
    echo "PACKAGING_FIRMWARE=false" >> $GITHUB_ENV
    echo "没发现rootfs.tar.gz包存在,关闭触发Armvirt_64自动打包成img固件"
  fi
fi
}

function Packaged_services() {
REPOS_ITORY="${GITHUB_WORKSPACE}/REPOSITORY"
TRIGGER_PROGRAM="${REPOS_ITORY}/build/${FOLDER_NAME}/relevance"
git clone -b main https://github.com/${GIT_REPOSITORY}.git ${REPOS_ITORY}

[[ ! -d "${TRIGGER_PROGRAM}" ]] && mkdir -p "${TRIGGER_PROGRAM}"

YML_PATH="${REPOS_ITORY}/.github/workflows/packaging.yml"
cp -Rf ${GITHUB_WORKSPACE}/.github/workflows/packaging.yml ${YML_PATH}
PATHS1="$(grep -A 5 'paths:' "${YML_PATH}" |sed 's/^[ ]*//g' |grep -v "^#" |grep -Eo "\- '.*'" |awk 'NR==1')"
PATHS2="- 'build/${FOLDER_NAME}/relevance/start'"
SOURCE_NAME1="$(grep 'SOURCE:' "${YML_PATH}"|sed 's/^[ ]*//g' |grep -v "^#" |awk 'NR==1')"
SOURCE_NAME2="SOURCE: ${SOURCE}"
FOLDER_NE1="$(grep 'FOLDER_NAME:' "${YML_PATH}"|sed 's/^[ ]*//g' |grep -v "^#" |awk 'NR==1')"
FOLDER_NE2="FOLDER_NAME: ${FOLDER_NAME}"

if [[ -n "${PATHS1}" ]] && [[ -n "${SOURCE_NAME1}" ]] && [[ -n "${FOLDER_NE1}" ]]; then
  sed -i "s?${PATHS1}?${PATHS2}?g" "${YML_PATH}"
  sed -i "s?${SOURCE_NAME1}?${SOURCE_NAME2}?g" "${YML_PATH}"
  sed -i "s?${FOLDER_NE1}?${FOLDER_NE2}?g" "${YML_PATH}"
else
  echo "获取变量失败,请勿胡乱修改packaging.yml文件和文件名称"
  exit 1
fi

cat >"${TRIGGER_PROGRAM}/start" <<-EOF
Trigger packaging ${SOURCE} program-$(date +%Y%m%d%H%M%S)
EOF

cat >"${TRIGGER_PROGRAM}/start.ini" <<-EOF
amlogic_model="${amlogic_model}"
amlogic_kernel="${amlogic_kernel}"
auto_kernel="${auto_kernel}"
rootfs_size="${rootfs_size}"
kernel_repo="${kernel_repo}"
SOURCE="${SOURCE}"
LUCI_VERSION="${LUCI_VERSION}"
UPLOAD_FIRMWARE="${UPLOAD_FIRMWARE}"
UPLOAD_RELEASE="${DABAO_RELEASE}"
EOF

chmod -R +x ${REPOS_ITORY}
cd ${REPOS_ITORY}
git add .
git commit -m "打包${SOURCE}-${amlogic_model}固件"
git push --force "https://${REPO_TOKEN}@github.com/${GIT_REPOSITORY}" HEAD:main
}

function Diy_xinxi() {
CPU_MODEL="$(cat /proc/cpuinfo |grep 'model name' |gawk -F : '{print $2}' |uniq -c |sed 's/^ \+[0-9]\+ //g' |sed 's/^[ ]*//g')"
TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' ${HOME_PATH}/.config)"
KERNEL_PATCH="$(grep "KERNEL_PATCHVER" "${HOME_PATH}/target/linux/${TARGET_BOARD}/Makefile" |grep -Eo "[0-9.]+")"
KERNEL_CONFIG="kernel-${KERNEL_PATCH}"
if [[ -f "${HOME_PATH}/include/${KERNEL_CONFIG}" ]]; then
  LINUX_KERNEL="$(grep "LINUX_KERNEL_HASH" "${HOME_PATH}/include/${KERNEL_CONFIG}" |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")"
  [[ -z ${LINUX_KERNEL} ]] && LINUX_KERNEL="nono"
else
  LINUX_KERNEL="$(grep "LINUX_KERNEL_HASH" "${HOME_PATH}/include/kernel-version.mk" |grep -Eo "${KERNEL_PATCH}\.[0-9]+")"
  [[ -z ${LINUX_KERNEL} ]] && LINUX_KERNEL="nono"
fi
echo
echo -e "\033[32m 源码链接: ${REPO_URL} \033[0m"
echo -e "\033[32m 源码分支: ${REPO_BRANCH} \033[0m"
echo -e "\033[32m 应用文件: ${FOLDER_NAME} \033[0m"
echo -e "\033[32m 配置文件: $(echo "${CONFIG_FILE}" |cut -d"/" -f2) \033[0m"
echo -e "\033[32m 扩展文件: ${DIY_PART_SH} \033[0m"
echo -e "\033[32m 编译机型: ${TARGET_PROFILE} \033[0m"
if [[ "${PACKAGING_FIRMWARE}" == "true" ]] && [[ "${TARGET_PROFILE}" == "Armvirt_64" ]]; then
  echo -e "\033[32m 内核版本: 以打包内核为准 \033[0m"
  echo
  echo -e "\033[34m amlogic_model: ${amlogic_model} \033[0m"
  echo -e "\033[34m amlogic_kernel: ${amlogic_kernel} \033[0m"
  echo -e "\033[34m auto_kernel: ${auto_kernel} \033[0m"
  echo -e "\033[34m rootfs_size: ${rootfs_size} \033[0m"
  echo -e "\033[34m kernel_repo: ${kernel_repo} \033[0m"
else
  echo -e "\033[32m 内核版本: ${LINUX_KERNEL} \033[0m"
fi
echo
echo -e "\033[35m 服务器CPU: ${CPU_MODEL} \033[0m"
echo
if [[ "${UPLOAD_FIRMWARE}" == "true" ]]; then
  echo -e "\033[33m 上传固件在Artifacts: 开启 \033[0m"
else
  echo -e "\033[31m 上传固件在Artifacts: 关闭 \033[0m"
fi
if [[ "${UPLOAD_RELEAS}" == "true" ]]; then
  echo -e "\033[33m 发布固件(Releases): 开启 \033[0m"
else
  echo -e "\033[31m 发布固件(Releases): 关闭 \033[0m"
fi
if [[ "${CACHEWRTBUILD_SWITCH}" == "true" ]]; then
  echo -e "\033[33m 是否开启缓存加速: 开启 \033[0m"
else
  echo -e "\033[31m 是否开启缓存加速: 关闭 \033[0m"
fi
if [[ "${PACKAGING_FIRMWARE}" == "true" ]]; then
  echo -e "\033[33m Armvirt_64自动打包成img固件: 开启 \033[0m"
else
  echo -e "\033[31m Armvirt_64自动打包成img固件: 关闭 \033[0m"
fi
echo
echo -e "\033[33m 后台IP：${IPV4_IPADDR} \033[0m"
if [[ "${DELETE_LOGIN_PASSWORD}" == "1" ]]; then
  echo -e "\033[33m 首次进入固件免密登录设置: 开启 \033[0m"
else
  echo -e "\033[31m 首次进入固件免密登录设置: 关闭 \033[0m"
fi
if [[ "${DEFAULT_CHINESE_LANGUAGE}" == "1" ]]; then
  echo -e "\033[33m 编译时改成默认中文LUCI: 开启 \033[0m"
else
  echo -e "\033[31m 编译时改成默认中文LUCI: 关闭 \033[0m"
fi
echo -e "\033[33m 清理[X]天之前的Artifacts: ${RETAIN_DAYS}天 \033[0m"
echo -e "\033[33m 保留[X]个Releases不被删除: ${KEEP_LATEST}个 \033[0m"
echo
}
