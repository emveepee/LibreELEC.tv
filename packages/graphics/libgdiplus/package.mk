# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libgdiplus"
PKG_VERSION="e15e1e00bcff4a2cb9c5135cbd43a7ffa0f13756"
PKG_LICENSE="MIT"
PKG_SHA256=""
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/mono/libgdiplus"
PKG_URL="https://github.com/mono/libgdiplus/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libjpeg-turbo cairo libexif giflib glib libpng gettext"
PKG_LONGDESC="libgdiplus is the Mono/netcore library that provides a GDI+-compatible API on non-Windows operating systems"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_HOST="--without-x11"
PKG_CONFIGURE_OPTS_TARGET="--without-x11 \
--with-libtiff=tiff \
--with-libgif=giflib \
--with-libjpeg=${SYSROOT_PREFIX}/build/libjpeg-turbo"


