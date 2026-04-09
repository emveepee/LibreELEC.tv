# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026 Team LibreELEC (https://libreelec.tv)

PKG_NAME="glfw"
PKG_VERSION="3.4"
PKG_SHA256=""
PKG_LICENSE="zlib"
PKG_SITE="https://github.com/glfw/glfw"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="glfw-${PKG_VERSION}"
PKG_SECTION="addon-depends"
PKG_SHORTDESC="GLFW windowing library for yauiclient"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-sysroot"

# Base cmake opts common to all targets
PKG_CMAKE_OPTS_TARGET="-DGLFW_BUILD_EXAMPLES=OFF \
                        -DGLFW_BUILD_TESTS=OFF \
                        -DGLFW_BUILD_DOCS=OFF \
                        -DBUILD_SHARED_LIBS=OFF \
                        -DCMAKE_BUILD_TYPE=Release"

pre_configure_target() {
  if [ "${DISPLAYSERVER}" = "x11" ]; then
    PKG_DEPENDS_TARGET="toolchain \
                        libX11 libxcb libXi libXrandr libXinerama \
                        libXxf86vm libXcursor xorgproto"
    PKG_CMAKE_OPTS_TARGET+=" -DGLFW_BUILD_X11=ON \
                              -DGLFW_BUILD_WAYLAND=OFF"
  else
    PKG_DEPENDS_TARGET="toolchain wayland wayland-protocols libxkbcommon"
    PKG_CMAKE_OPTS_TARGET+=" -DGLFW_BUILD_X11=OFF \
                              -DGLFW_BUILD_WAYLAND=ON"
  fi
}

makeinstall_target() {
  DESTDIR="${INSTALL}" cmake --install "${PKG_REAL_BUILD}"
}