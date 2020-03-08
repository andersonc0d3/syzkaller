#!/bin/bash

set -eux

[ -z "${CC}" ] && echo 'Please set $CC to point to the compiler!' && exit
[ -z "${KERNEL_SOURCE}" ] && echo 'Please set $KERNEL_SOURCE to point to the kernel tree!' && exit
[ -z "${DISTRO_CONFIG}" ] && echo 'Please set $DISTRO_CONFIG to point to the base distro config!' && exit

THIS_DIR=`cd $(dirname $0); pwd`
. ${THIS_DIR}/util.sh

OUTPUT_CONFIG=${THIS_DIR}/dev-ubuntu.config
DISTRO_CONFIG=${THIS_DIR}/${DISTRO_CONFIG}

cd ${KERNEL_SOURCE}

make ${MAKE_VARS} defconfig
make ${MAKE_VARS} kvmconfig

cat $DISTRO_CONFIG | grep -E '=y' > /tmp/distro-config-y
./scripts/kconfig/merge_config.sh -m .config /tmp/distro-config-y
make ${MAKE_VARS} olddefconfig

sed -i "s#=m\$#=n#g" .config
make ${MAKE_VARS} olddefconfig

util_add_syzbot_bits
util_add_syzbot_extra_bits

# Support older compilers.
scripts/config -d CONFIG_KCOV_ENABLE_COMPARISONS

# Enable network driver.
scripts/config -e CONFIG_E1000

cp .config ${OUTPUT_CONFIG}
