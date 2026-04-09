# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 Team LibreELEC (https://libreelec.tv)

PKG_NAME="yauiclient"
PKG_VERSION="0.2.2"
PKG_SHA256="8f19f3c1e14b577f7efbd1d49cc0753476d14f8c9636878e092573c21d153a68"
PKG_REV="2"
PKG_ARCH="x86_64 aarch64 arm"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/emveepee/yauiclient"
PKG_URL="https://github.com/emveepee/yauiclient/archive/${PKG_VERSION}.tar.gz"
PKG_SECTION="service"
PKG_SHORTDESC="yauiclient NextPVR media player"
PKG_LONGDESC="A cross-platform media player client for NextPVR using libmpv with OpenGL overlay."
PKG_TOOLCHAIN="cmake"
PKG_IS_ADDON="yes"
PKG_ADDON_NAME="yauiclient"
PKG_ADDON_TYPE="xbmc.service.library"
PKG_MAINTAINER="Pinstripe Limited"

# Core dependencies common to all targets
PKG_DEPENDS_TARGET="toolchain libmpv cpr lua52 libfmt nlohmann-json libglvnd"
if [ "${DISPLAYSERVER}" = "x11" ]; then
    PKG_DEPENDS_TARGET+=" glfw"
else
    PKG_DEPENDS_TARGET+=" glfw-plus"
fi

pre_configure_target() {
  if [ "${DISPLAYSERVER}" = "x11" ]; then
    PKG_DEPENDS_TARGET+=" x11 libXfixes"
    PKG_CMAKE_OPTS_TARGET="-DYAUICLIENT_USE_SYSTEM_MPV=ON \
                            -DYAUI_LEGL=ON \
                            -DCMAKE_BUILD_TYPE=Release \
                            -Dcpr_DIR=$(get_install_dir cpr)/usr/lib/cmake/cpr \
                            -Dglfw3_DIR=$(get_install_dir glfw)/usr/lib/cmake/glfw3"
  else
    PKG_CMAKE_OPTS_TARGET="-DYAUICLIENT_USE_SYSTEM_MPV=ON \
                            -DYAUI_LEGBM=ON \
                            -DCMAKE_BUILD_TYPE=Release \
                            -Dcpr_DIR=$(get_install_dir cpr)/usr/lib/cmake/cpr \
                            -Dglfw3_DIR=$(get_install_dir glfw-plus)/usr/lib/cmake/glfw3"
    if [ "${PROJECT}" = "RPi" ]; then
        PKG_CMAKE_OPTS_TARGET+=" -DYAUI_LEGBMPI=ON"
    fi
  fi
}

addon() {
  :
}

post_install_addon() {
  mkdir -p ${INSTALL}/bin
  mkdir -p ${INSTALL}/lbin

  # Main binary
  cp $(get_install_dir ${PKG_NAME})/usr/bin/yauiclient ${INSTALL}/bin/
  chmod +x ${INSTALL}/bin/yauiclient

  # libmpv — not in base LE image, must be bundled
  cp -P $(get_install_dir libmpv)/usr/lib/libmpv.so* ${INSTALL}/lbin/

  # libXScrnSaver and libXpresent — not in base LE image, must be bundled (x11 only)
  if [ "${DISPLAYSERVER}" = "x11" ]; then
    cp -P $(get_install_dir libXScrnSaver)/usr/lib/libXss.so* ${INSTALL}/lbin/
    cp -P $(get_install_dir libXpresent)/usr/lib/libXpresent.so* ${INSTALL}/lbin/
  fi

  # glfw is static — absorbed into yauiclient binary, nothing to bundle
  # cpr is static — absorbed into yauiclient binary, nothing to bundle

  if [ "${DISPLAYSERVER}" != "x11" ]; then
    sed -i '/Requires=windowmanager.service/d' \
        ${INSTALL}/system.d/service.yauiclient.service
    sed -i '/DISPLAY=/d' \
        ${INSTALL}/system.d/service.yauiclient.service
  fi
}