# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026 Team LibreELEC (https://libreelec.tv)

PKG_NAME="libXpresent"
PKG_VERSION="1.0.1"
PKG_SHA256="b964df9e5a066daa5e08d2dc82692c57ca27d00b8cc257e8e960c9f1cf26231b"
PKG_LICENSE="OSS"
PKG_SITE="https://www.x.org"
PKG_URL="https://xorg.freedesktop.org/archive/individual/lib/libXpresent-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain libXext libXrandr libXfixes xorgproto"
PKG_LONGDESC="X Present extension library."
PKG_BUILD_FLAGS="-sysroot"