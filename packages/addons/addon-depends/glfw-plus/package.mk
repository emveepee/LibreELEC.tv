# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026 Team LibreELEC (https://libreelec.tv)

PKG_NAME="glfw-plus"
PKG_VERSION="kmsdrm"
PKG_SHA256="8293505ef8ccb4b92c8cee7fc02a03ae397bba0e91d34a5d199ee42ec7f9b505"
PKG_LICENSE="zlib"
PKG_SITE="https://github.com/leonkasovan/glfw-plus"
PKG_URL="${PKG_SITE}/archive/refs/heads/${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="glfw-plus-${PKG_VERSION}"
PKG_SECTION="addon-depends"
PKG_SHORTDESC="GLFW-plus windowing library with KMS/DRM backend for yauiclient"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-sysroot"

pre_configure_target() {
  export CFLAGS="${CFLAGS} -I${SYSROOT_PREFIX}/usr/include/drm"
  PKG_DEPENDS_TARGET="toolchain libdrm libxkbcommon"
  PKG_CMAKE_OPTS_TARGET="-DGLFW_BUILD_EXAMPLES=OFF \
                          -DGLFW_BUILD_TESTS=OFF \
                          -DGLFW_BUILD_DOCS=OFF \
                          -DBUILD_SHARED_LIBS=OFF \
                          -DCMAKE_BUILD_TYPE=Release \
                          -DGLFW_BUILD_X11=OFF \
                          -DGLFW_BUILD_WAYLAND=OFF \
                          -DGLFW_BUILD_KMSDRM=ON"
}

makeinstall_target() {
  DESTDIR="${INSTALL}" cmake --install "${PKG_REAL_BUILD}"
}