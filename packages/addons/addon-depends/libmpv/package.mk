# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026 Team LibreELEC (https://libreelec.tv)

PKG_NAME="libmpv"
PKG_VERSION="0.38.0"
PKG_SHA256="86d9ef40b6058732f67b46d0bbda24a074fae860b3eaae05bab3145041303066"
PKG_LICENSE="GPL"
PKG_SITE="https://mpv.io"
PKG_URL="https://github.com/mpv-player/mpv/archive/v${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="mpv-${PKG_VERSION}"
PKG_SECTION="addon-depends"
PKG_SHORTDESC="libmpv shared library"
PKG_LONGDESC="mpv media player built as libmpv.so"
PKG_TOOLCHAIN="meson"
PKG_BUILD_FLAGS="-sysroot"

# Base dependencies common to all targets
# lua52 and libplacebo are main-tree packages and land in sysroot normally.
# libXScrnSaver, libXpresent, libglvnd, libX11 are either main-tree (sysroot)
# or addon-depends built with -sysroot; those not in sysroot are listed in
# PKG_DEPENDS_CONFIG so the build system finds their .pc files via install_pkg.
PKG_DEPENDS_TARGET="toolchain ffmpeg libass zlib alsa-lib libplacebo lua52"
PKG_DEPENDS_CONFIG="libplacebo"

# Base meson opts common to all targets
PKG_MESON_OPTS_TARGET="-Dlibmpv=true \
                        -Dcplayer=false \
                        -Dbuild-date=false \
                        -Dgpl=true \
                        -Dmanpage-build=disabled \
                        -Dhtml-build=disabled \
                        -Dalsa=enabled \
                        -Dgl=enabled \
                        -Dsdl2=disabled \
                        -Dpipewire=disabled \
                        -Djack=disabled \
                        -Dopenal=disabled \
                        -Dvdpau=disabled \
                        -Dvdpau-gl-x11=disabled \
                        -Dcoreaudio=disabled \
                        -Dwasapi=disabled \
                        -Dlua=lua52 \
                        -Djavascript=disabled \
                        -Dcplugins=disabled \
                        -Duchardet=disabled \
                        -Drubberband=disabled \
                        -Dvapoursynth=disabled \
                        -Dlibarchive=disabled \
                        -Dlibbluray=disabled \
                        -Ddvdnav=disabled \
                        -Dcdda=disabled \
                        -Ddvbin=disabled \
                        -Dshaderc=disabled \
                        -Dspirv-cross=disabled \
                        -Dvulkan=disabled \
                        -Dpulse=disabled"

if [ "${ARCH}" = "x86_64" ]; then
  if [ "${OPENGL_SUPPORT}" = "yes" ] || [ "${OPENGLES_SUPPORT}" = "yes" ] || [ "${VAAPI_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" libva"
    PKG_MESON_OPTS_TARGET+=" -Dvaapi=enabled"
  else
    PKG_MESON_OPTS_TARGET+=" -Dvaapi=disabled"
  fi

  if [ "${DISPLAYSERVER}" = "x11" ]; then
    # libXpresent is an addon-depends package built with -sysroot; list it in
    # PKG_DEPENDS_CONFIG so the build system finds its .pc via install_pkg.
    # libXScrnSaver is a main-tree sysroot package; meson finds it normally.
    # libglvnd and libX11 are main-tree sysroot packages; listed in DEPENDS_CONFIG
    # anyway so the build system wires the pkg-config search paths correctly.
    PKG_DEPENDS_TARGET+=" mesa libX11 libXScrnSaver libXpresent libglvnd"
    PKG_DEPENDS_CONFIG+=" libX11 libXpresent libglvnd"
    PKG_MESON_OPTS_TARGET+=" -Dx11=enabled \
                              -Dgl-x11=enabled \
                              -Degl-x11=enabled \
                              -Degl=enabled \
                              -Dwayland=disabled \
                              -Dgbm=disabled \
                              -Ddrm=disabled \
                              -Degl-drm=disabled \
                              -Dvaapi-drm=disabled \
                              -Dvaapi-wayland=disabled"
    if [ "${OPENGL_SUPPORT}" = "yes" ] || [ "${OPENGLES_SUPPORT}" = "yes" ] || [ "${VAAPI_SUPPORT}" = "yes" ]; then
      PKG_MESON_OPTS_TARGET+=" -Dvaapi-x11=enabled"
    else
      PKG_MESON_OPTS_TARGET+=" -Dvaapi-x11=disabled"
    fi
  else
    # x86_64 GBM path
    PKG_DEPENDS_TARGET+=" libdrm systemd mesa"
    PKG_MESON_OPTS_TARGET+=" -Dx11=disabled \
                              -Dgl-x11=disabled \
                              -Degl-x11=disabled \
                              -Dwayland=disabled \
                              -Dgbm=enabled \
                              -Ddrm=enabled \
                              -Degl=enabled \
                              -Degl-drm=enabled \
                              -Dvaapi-x11=disabled \
                              -Dvaapi-wayland=disabled"
    if [ "${OPENGL_SUPPORT}" = "yes" ] || [ "${OPENGLES_SUPPORT}" = "yes" ] || [ "${VAAPI_SUPPORT}" = "yes" ]; then
      PKG_MESON_OPTS_TARGET+=" -Dvaapi-drm=enabled"
    else
      PKG_MESON_OPTS_TARGET+=" -Dvaapi-drm=disabled"
    fi
  fi

else
  # aarch64 / arm — GBM/DRM, no VAAPI, V4L2M2M hwdec
  PKG_DEPENDS_TARGET+=" libdrm systemd mesa"
  PKG_MESON_OPTS_TARGET+=" -Dvaapi=disabled \
                            -Dvaapi-drm=disabled \
                            -Dvaapi-x11=disabled \
                            -Dvaapi-wayland=disabled \
                            -Dx11=disabled \
                            -Dgl-x11=disabled \
                            -Degl-x11=disabled \
                            -Dwayland=disabled \
                            -Dgbm=enabled \
                            -Ddrm=enabled \
                            -Degl=enabled \
                            -Degl-drm=enabled"
fi

makeinstall_target() {
  DESTDIR="${INSTALL}" meson install -C "${PKG_REAL_BUILD}"
  rm -f "${INSTALL}/usr/bin/mpv"

  mkdir -p ${SYSROOT_PREFIX}/usr/include
  cp -av ${INSTALL}/usr/include/. ${SYSROOT_PREFIX}/usr/include/

  mkdir -p ${SYSROOT_PREFIX}/usr/lib
  cp -P ${INSTALL}/usr/lib/libmpv.so* ${SYSROOT_PREFIX}/usr/lib/

  mkdir -p ${SYSROOT_PREFIX}/usr/lib/pkgconfig
  cp ${INSTALL}/usr/lib/pkgconfig/mpv.pc ${SYSROOT_PREFIX}/usr/lib/pkgconfig/
  sed -i '/^Requires/d' ${SYSROOT_PREFIX}/usr/lib/pkgconfig/mpv.pc
}

PKG_REV="1"
PKG_ADDON_NEWS=""