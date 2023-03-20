#!/bin/bash

function Package_defaultsettings() {
ZZZL_PATH="$(find "$GITHUB_WORKSPACE/openwrt/package" -type d -name "default-settings")"
if [[ -d "${ZZZL_PATH}" ]]; then
  echo "ZZZ_PATH=$(find "$GITHUB_WORKSPACE/openwrt/package" -type f -name "*-default-settings")" >> $GITHUB_ENV
else
  cp -Rf $GITHUB_WORKSPACE/relevance/settings $GITHUB_WORKSPACE/openwrt/package/default-settings
  echo "ZZZ_PATH=$(find "$GITHUB_WORKSPACE/openwrt/package" -type f -name "*-default-settings")" >> $GITHUB_ENV
fi
GENERATE_PATH="${GITHUB_WORKSPACE}/openwrt/package/base-files/files/bin/config_generate"
echo "GENERATE_PATH=${GENERATE_PATH}" >> $GITHUB_ENV
echo "IPADDR=$(grep "ipaddr:-" "${GENERATE_PATH}" |grep -v 'addr_offset' |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")" >> $GITHUB_ENV
}


function Diy_pattsh() {
./scripts/feeds update -a > /dev/null 2>&1
[[ -f "$GITHUB_WORKSPACE/feeds.conf.default" ]] && mv -f $GITHUB_WORKSPACE/feeds.conf.default feeds.conf.default
[[ -d "$GITHUB_WORKSPACE/diy" ]] && cp -Rf $GITHUB_WORKSPACE/diy/* $GITHUB_WORKSPACE/openwrt/
[[ -d "$GITHUB_WORKSPACE/files" ]] && mv -f $GITHUB_WORKSPACE/files/* files
if [[ -d "$GITHUB_WORKSPACE/patches" ]]; then
  find "$GITHUB_WORKSPACE/patches" -type f -name '*.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "cat '%'  | patch -d './' -p1 --forward --no-backup-if-mismatch"
fi
sudo chmod +x $GITHUB_WORKSPACE/${DIY_PART_SH}
source $GITHUB_WORKSPACE/${DIY_PART_SH}
if [[ "${DIY_PART_SH}" == "1907-luci.sh" ]]; then
  cp -Rf $GITHUB_WORKSPACE/relevance/zh_Hans.sh ${HOME_PATH}/zh_Hans.sh
  sudo chmod +x ${HOME_PATH}/zh_Hans.sh
  /bin/bash ${HOME_PATH}/zh_Hans.sh
fi
echo "amlogic_model=${amlogic_model}" >> ${GITHUB_ENV}
echo "amlogic_kernel=${amlogic_kernel}" >> ${GITHUB_ENV}
echo "auto_kernel=${auto_kernel}" >> ${GITHUB_ENV}
echo "rootfs_size=${rootfs_size}" >> ${GITHUB_ENV}
echo "kernel_repo=${kernel_repo}" >> ${GITHUB_ENV}
}


function Diy_config() {
if [[ -f "$GITHUB_WORKSPACE/$CONFIG_FILE}" ]]; then
  cp -Rf $GITHUB_WORKSPACE/${CONFIG_FILE} ${HOME_PATH}/.config
fi

echo "
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_default-settings-chn=y
CONFIG_PACKAGE_default-settings=y
" >> "${HOME_PATH}/.config"

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

function Packaged_services() {
FOLDER_NAME="${GITHUB_WORKSPACE}/REPOSITORY"
TRIGGER_PROGRAM="${FOLDER_NAME}/relevance"
git clone -b main https://github.com/${GIT_REPOSITORY}.git ${FOLDER_NAME}

[[ ! -d "${TRIGGER_PROGRAM}" ]] && mkdir -p "${TRIGGER_PROGRAM}"

YML_PATH="${FOLDER_NAME}/.github/workflows/packaging.yml"
PATHS1="$(grep -A 5 'paths:' "${YML_PATH}" |sed 's/^[ ]*//g' |grep -v "^#" |grep -Eo "\- '.*'" |awk 'NR==1')"
PATHS2="- 'relevance/start'"
SOURCE_NAME1="$(grep 'SOURCE:' "${YML_PATH}"|sed 's/^[ ]*//g' |grep -v "^#" |awk 'NR==1')"
SOURCE_NAME2="SOURCE: ${SOURCE}"

if [[ -n "${PATHS1}" ]] && [[ -n "${SOURCE_NAME1}" ]]; then
  sed -i "s?${PATHS1}?${PATHS2}?g" "${YML_PATH}"
  sed -i "s?${SOURCE_NAME1}?${SOURCE_NAME2}?g" "${YML_PATH}"
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
kernel_repo="${kernel_repo}"
rootfs_size="${rootfs_size}"
SOURCE="${SOURCE}"
LUCI_VERSION="${LUCI_VERSION}"
EOF

chmod -R +x ${FOLDER_NAME}
cd ${FOLDER_NAME}
git add .
git commit -m "打包${SOURCE}-${amlogic_model}固件"
git push --force "https://${REPO_TOKEN}@github.com/${GIT_REPOSITORY}" HEAD:main
}
