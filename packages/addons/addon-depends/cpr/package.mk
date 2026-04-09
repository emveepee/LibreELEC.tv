# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026 Team LibreELEC (https://libreelec.tv)

PKG_NAME="cpr"
PKG_VERSION="1.14.2"
PKG_SHA256=""
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/libcpr/cpr"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="cpr-${PKG_VERSION}"
PKG_DEPENDS_TARGET="toolchain curl"
PKG_SECTION="addon-depends"
PKG_SHORTDESC="C++ HTTP library (wraps libcurl) for yauiclient"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-sysroot"

PKG_CMAKE_OPTS_TARGET="-DCPR_USE_SYSTEM_CURL=ON \
                        -DCPR_ENABLE_SSL=ON \
                        -DCPR_BUILD_TESTS=OFF \
                        -DCPR_BUILD_TESTS_SSL=OFF \
                        -DCPR_GENERATE_COVERAGE=OFF \
                        -DBUILD_SHARED_LIBS=OFF \
                        -DCMAKE_BUILD_TYPE=Release"