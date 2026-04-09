# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026 Team LibreELEC (https://libreelec.tv)

import sys
import os
import xml.etree.ElementTree as ET
import xbmc
import xbmcaddon
import xbmcvfs
import xbmcgui

addon     = xbmcaddon.Addon()
data_path = xbmcvfs.translatePath(addon.getAddonInfo('profile'))
conf_path = os.path.join(data_path, 'yauiclient.conf')
ADDON_NAME = addon.getAddonInfo('name')
GUISETTINGS = xbmcvfs.translatePath('special://userdata/guisettings.xml')


def extract_kodi_audio_device():
    try:
        tree = ET.parse(GUISETTINGS)
        root = tree.getroot()
        for setting in root.iter('setting'):
            if setting.get('id') == 'audiooutput.audiodevice':
                value = setting.text or ''
                alsa_part = value.split('|')[0].strip()
                if alsa_part.startswith('ALSA:'):
                    alsa_part = alsa_part[5:]
                return alsa_part
    except Exception as e:
        xbmc.log(f'[yauiclient] guisettings.xml parse error: {e}', xbmc.LOGWARNING)
    return None


def write_conf_key(path, key, value):
    lines = []
    if os.path.exists(path):
        with open(path, 'r') as f:
            lines = f.read().splitlines()
    updated = False
    new_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith(key + '=') or stripped.startswith(key + ' ='):
            new_lines.append(f'{key}={value}')
            updated = True
        else:
            new_lines.append(line)
    if not updated:
        if new_lines and new_lines[-1] != '':
            new_lines.append('')
        new_lines.append(f'{key}={value}')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write('\n'.join(new_lines) + '\n')


def sync_audio_device():
    device = extract_kodi_audio_device()
    if not device:
        xbmcgui.Dialog().notification(
            ADDON_NAME,
            'Could not read audio device from Kodi settings',
            xbmcgui.NOTIFICATION_WARNING)
        return
    mpv_device = f'alsa/{device}'
    write_conf_key(conf_path, 'audio-device', mpv_device)
    xbmc.log(f'[yauiclient] audio_device set to {mpv_device}', xbmc.LOGINFO)
    xbmcgui.Dialog().notification(
        ADDON_NAME,
        f'Audio device: {device}',
        xbmcgui.NOTIFICATION_INFO)

def create_autostart():
    # 1. Create autostart.sh
    autostart_path = '/storage/.config/autostart.sh'
    autostart_content = '#!/bin/sh\nsystemctl start service.yauiclient\n'

    with open(autostart_path, 'w') as f:
        f.write(autostart_content)

    os.chmod(autostart_path, 0o755)

    # 2. Create or update favourites.xml
    favourites_path = '/storage/.kodi/userdata/favourites.xml'
    icon_path = '/storage/.kodi/addons/service.yauiclient/resources/icon.png'
    exec_cmd = 'System.Exec(/storage/.config/autostart.sh)'
    fav_name = 'yauiclient'

    if os.path.exists(favourites_path):
        try:
            tree = ET.parse(favourites_path)
            root = tree.getroot()
        except ET.ParseError:
            root = ET.Element('favourites')
            tree = ET.ElementTree(root)
    else:
        root = ET.Element('favourites')
        tree = ET.ElementTree(root)

    # Check if favourite already exists — don't duplicate
    for fav in root.findall('favourite'):
        if fav.get('name') == fav_name:
            return  # already exists

    # Add the new favourite
    fav = ET.SubElement(root, 'favourite')
    fav.set('name', fav_name)
    fav.set('thumb', icon_path)
    fav.text = exec_cmd

    # Write with XML declaration and indentation
    ET.indent(tree, space='    ')
    tree.write(favourites_path, encoding='unicode', xml_declaration=True)
    xbmcgui.Dialog().notification(
        ADDON_NAME,
        'Enabled autostart',
        xbmcgui.NOTIFICATION_INFO)

def create_x11_config():
    if not os.path.exists('/usr/bin/Xorg'):
        xbmcgui.Dialog().ok(
            'yauiclient',
            'X11 configuration is not available on this platform.'
        )
        return
    """
    Create persistent X11 configuration to prevent Xorg from consuming
    rc-core IR remote events (which are read directly by yauiclient via evdev).

    Creates three files:
      1. /storage/.config/add-xorg-configdir.sh
         Script that appends -configdir to Xorg XORG_ARGS at boot time.

      2. /storage/.config/system.d/xorg-configure@.service.d/99-configdir.conf
         systemd drop-in that runs the script after xorg-configure completes.

      3. /storage/.config/xorg.conf.d/99-ignore-ir.conf
         Xorg InputClass that tells Xorg to ignore all rc-core IR devices.

    All three are required and persistent across reboots.
    Safe to call multiple times — will not duplicate entries.
    """

    # 1. Create add-xorg-configdir.sh
    script_path = '/storage/.config/add-xorg-configdir.sh'
    script_content = (
        '#!/bin/sh\n'
        '# Appended by yauiclient addon — adds user xorg.conf.d to Xorg args\n'
        'if ! grep -q \'configdir\' /run/libreelec/xorg-settings.conf; then\n'
        '   if [ -d /storage/.config/xorg.conf.d ]; then\n'
        '       sed -i \'s|"$| -configdir /storage/.config/xorg.conf.d"|\''
        '   /run/libreelec/xorg-settings.conf\n'
        '   fi\n'
        'fi\n'
    )
    with open(script_path, 'w') as f:
        f.write(script_content)
    os.chmod(script_path, 0o755)

    # 2. Create systemd drop-in
    dropin_dir = '/storage/.config/system.d/xorg-configure@.service.d'
    os.makedirs(dropin_dir, exist_ok=True)
    dropin_path = os.path.join(dropin_dir, '99-configdir.conf')
    dropin_content = (
        '[Service]\n'
        'ExecStartPost=/storage/.config/add-xorg-configdir.sh\n'
    )
    with open(dropin_path, 'w') as f:
        f.write(dropin_content)

    # 3. Create xorg.conf.d ignore rule
    xorgconfd_dir = '/storage/.config/xorg.conf.d'
    os.makedirs(xorgconfd_dir, exist_ok=True)
    ignore_path = os.path.join(xorgconfd_dir, '99-ignore-ir.conf')
    ignore_content = (
        '# Added by yauiclient addon\n'
        '# Ignore rc-core IR remotes — yauiclient reads them directly via evdev\n'
        'Section "InputClass"\n'
        '    Identifier "Ignore IR Remote eHome"\n'
        '    MatchProduct "eHome Infrared Remote Transceiver"\n'
        '    Option "Ignore" "yes"\n'
        'EndSection\n'
        '\n'
        'Section "InputClass"\n'
        '    Identifier "Ignore IR Remote Hauppauge"\n'
        '    MatchProduct "Hauppauge"\n'
        '    Option "Ignore" "yes"\n'
        'EndSection\n'
        '\n'
        'Section "InputClass"\n'
        '    Identifier "Ignore IR Remote MCE"\n'
        '    MatchProduct "MCE"\n'
        '    Option "Ignore" "yes"\n'
        'EndSection\n'
    )
    # Only write if not already present
    if not os.path.exists(ignore_path):
        with open(ignore_path, 'w') as f:
            f.write(ignore_content)

    # 4. Reload systemd so the drop-in is active on next boot
    os.system('systemctl daemon-reload')

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else ''
    if action == 'syncaudio':
        sync_audio_device()
    elif action == 'autostart':
        create_autostart()
    elif action == 'x11config':
        create_x11_config()
    else:
        xbmc.log(f'[yauiclient] addon.py: unknown action: {action}', xbmc.LOGWARNING)