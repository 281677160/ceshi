#!/bin/bash

function Package_settings() {
ZZZL_PATH="$(find "$GITHUB_WORKSPACE/openwrt/package" -type d -name "default-settings")"
if [[ -d "${ZZZL_PATH}" ]]; then
  echo "ZZZ_PATH=$(find "$GITHUB_WORKSPACE/openwrt/package" -type f -name "*-default-settings")" >> $GITHUB_ENV
else
  cp -Rf $GITHUB_WORKSPACE/openwrt/build/relevance/settings $GITHUB_WORKSPACE/openwrt/package/default-settings
  echo "ZZZ_PATH=$(find "$GITHUB_WORKSPACE/openwrt/package" -type f -name "*-default-settings")" >> $GITHUB_ENV
fi
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
    sed -i "s/${IPADDR}/${IPV4_IPADDR}/g" "${GENERATE_PATH}"
    echo "后台IP修改成功,当前IP：${IPV4_IPADDR}"
  else
    echo "IP格式不正确，使用源码默认IP：${IPADDR}"
  fi
fi

if [[ "${DELETE_LOGIN_PASSWORD}" == "1" ]]; then
  [[ -f "${ZZZ_PATH}" ]] && sed -i '/CYXluq4wUazHjmCDBCqXF/d' "${ZZZ_PATH}"
  echo "清除登录密码完成"
fi

if [[ -n "${RETAIN_DAYS}" ]]; then
  echo "RETAIN_DAYS=${RETAIN_DAYS}" >> ${GITHUB_ENV}
  echo "清除${RETAIN_DAYS}天前的Artifacts记录"
else
  echo "RETAIN_DAYS=30" >> ${GITHUB_ENV}
fi

if [[ -n "${KEEP_LATEST}" ]]; then
  echo "KEEP_LATEST=${KEEP_LATEST}" >> ${GITHUB_ENV}
  echo "保留${KEEP_LATEST}个Releases不被清理"
else
  echo "KEEP_LATEST=90" >> ${GITHUB_ENV}
fi

if [[ "${DEFAULT_CHINESE_LANGUAGE}" == "1" ]]; then
  echo "DEFAULT_CHINESE_LANGUAGE=${DEFAULT_CHINESE_LANGUAGE}" >> $GITHUB_ENV
  apptions="$(find "${HOME_PATH}/feeds" -type d -name "applications"  |grep 'luci')"
  if [[ -d "${apptions}" ]] && [[ `find "${apptions}" -type d -name "zh_Hans" |grep -c "zh_Hans"` -ge '15' ]]; then
    cp -Rf ${RELEVANCE_PATH}/zh_Hans.sh ${HOME_PATH}/zh_Hans.sh
    /bin/bash ${HOME_PATH}/zh_Hans.sh
    echo "转换插件源码语言格式为[zh_Hans]完成"
  fi
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
  sed -i "s?main.lang=.*?main.lang='zh_cn'?g" "${ZZZ_PATH}"
  echo "默认中文LUCI设置完成"
fi

make defconfig > /dev/null 2>&1
export TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' ${HOME_PATH}/.config)"
export TARGET_SUBTARGET="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' ${HOME_PATH}/.config)"
export TARGET_PROFILE_DG="$(awk -F '[="]+' '/TARGET_PROFILE/{print $2}' ${HOME_PATH}/.config)"
export FIRMWARE_PATH="${HOME_PATH}/bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}"
if [[ `grep -c 'CONFIG_TARGET_x86_64=y' ${HOME_PATH}/.config` -eq '1' ]]; then
  export TARGET_PROFILE="x86-64"
elif [[ `grep -c 'CONFIG_TARGET_x86=y' ${HOME_PATH}/.config` -eq '1' ]]; then
  export TARGET_PROFILE="x86-32"
elif [[ `grep -c 'CONFIG_TARGET_armvirt_64_Default=y' ${HOME_PATH}/.config` -eq '1' ]]; then
  export TARGET_PROFILE="Armvirt_64"
  echo "CONFIG_TARGET_ROOTFS_TARGZ=y" >> "${HOME_PATH}/.config"
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
if [[ `grep -c 'CONFIG_TARGET_armvirt_64_Default=y' ${HOME_PATH}/.config` -eq '1' ]]; then
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
TRIGGER_PROGRAM="${REPOS_ITORY}/${FOLDER_NAME}/relevance"
git clone -b main https://github.com/${GIT_REPOSITORY}.git ${REPOS_ITORY}

[[ ! -d "${TRIGGER_PROGRAM}" ]] && mkdir -p "${TRIGGER_PROGRAM}"

YML_PATH="${REPOS_ITORY}/.github/workflows/packaging.yml"
cp -Rf ${GITHUB_WORKSPACE}/.github/workflows/packaging.yml ${YML_PATH}
PATHS1="$(grep -A 5 'paths:' "${YML_PATH}" |sed 's/^[ ]*//g' |grep -v "^#" |grep -Eo "\- '.*'" |awk 'NR==1')"
PATHS2="- '${FOLDER_NAME}/relevance/start'"
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
