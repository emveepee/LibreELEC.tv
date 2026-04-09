# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

import xbmc
import xbmcaddon
import xbmcvfs
import xbmcgui
import os
import json

addon = xbmcaddon.Addon()
data_path = xbmcvfs.translatePath(addon.getAddonInfo('profile'))
config_path = os.path.join(data_path, 'yauiclient.json')

ADDON_NAME = xbmcaddon.Addon().getAddonInfo('name')

LS = xbmcaddon.Addon().getLocalizedString

class Monitor(xbmc.Monitor):

   def __init__(self, *args, **kwargs):
      xbmc.Monitor.__init__(self)

   def updateJson(self):
      host = addon.getSetting('host')
      port = addon.getSetting('server_port')
      pin = addon.getSetting('pin')
      lirc = addon.getSetting('lirc')
      deinterlace = addon.getSetting('deinterlace')
      resolution = addon.getSetting('resolution')
      shutdown = addon.getSetting('shutdown')

      config = {}
      if os.path.exists(config_path):
         try:
               with open(config_path, 'r') as f:
                  config = json.load(f)
         except Exception:
               config = {}
      changed = False

      if host and config.get('host') != host:
         config['host'] = host
         changed = True

      if port and str(config.get('server_port', '')) != port:
         config['server_port'] = int(port)
         changed = True

      if pin and config.get('pin') != pin:
         config['pin'] = pin
         if 'hashed_pin' in config:
            config['hashed_pin'] = ""
         changed = True

      deinterlace_bool = deinterlace.lower() == 'true'
      if config.get('deinterlace') != deinterlace_bool:
         config['deinterlace'] = deinterlace_bool
         changed = True

      lirc_bool = lirc.lower() == 'true'
      if config.get('lirc') != lirc_bool:
         config['lirc'] = lirc_bool
         changed = True

      if resolution and config.get('resolution') != resolution:
         config['resolution'] = resolution
         changed = True

      shutdown_bool = shutdown.lower() == 'true'
      if config.get('shutdown') != shutdown_bool:
         config['shutdown'] = shutdown_bool
         changed = True

      if changed:
         os.makedirs(data_path, exist_ok=True)
         with open(config_path, 'w') as f:
               json.dump(config, f, indent=4)

   def settingsDiffer(self):
      if not os.path.exists(config_path):
         return True
      try:
         with open(config_path, 'r') as f:
               config = json.load(f)
      except Exception:
         return True
      host = addon.getSetting('host')
      port = addon.getSetting('port')
      pin = addon.getSetting('pin')
      deinterlace = addon.getSetting('deinterlace').lower() == 'true'
      lirc = addon.getSetting('lirc').lower() == 'true'
      resolution = addon.getSetting('resolution')
      shutdown = addon.getSetting('shutdown')

      return (host != config.get('host', '') or
               port != str(config.get('server_port', '')) or
               pin != config.get('pin', '') or
               deinterlace != config.get('deinterlace', False) or
               lirc != config.get('lirc', False) or
               resolution != config.get('resolution', '') or
               shutdown != config.get('shutdown', ''))

   def onSettingsChanged(self):
      if self.settingsDiffer():
         self.updateJson()

   def syncSettingsFromJson(self):
      """Push JSON config values into Kodi addon settings on startup."""
      if not os.path.exists(config_path):
         return
      try:
         with open(config_path, 'r') as f:
               config = json.load(f)
      except Exception:
         return

      if 'host' in config:
         addon.setSetting('host', str(config['host']))
      if 'server_port' in config:
         addon.setSetting('server_port', str(config['server_port']))
      if 'pin' in config:
         addon.setSetting('pin', str(config['pin']))
      if 'resolution' in config:
         addon.setSetting('resolution', str(config['resolution']))
      if 'deinterlace' in config:
         addon.setSetting('deinterlace', 'true' if config['deinterlace'] else 'false')
      if 'lirc' in config:
         addon.setSetting('lirc', 'true' if config['lirc'] else 'false')
      if 'shutdown' in config:
         addon.setSetting('shutdown', 'true' if config['shutdown'] else 'false')

   def showMessage(self, message):
      xbmc.log(message, xbmc.LOGDEBUG)
      xbmcgui.Dialog().notification(ADDON_NAME, message, xbmcgui.NOTIFICATION_INFO)


if __name__ == "__main__":
   monitor = Monitor()
   monitor.syncSettingsFromJson()  # populate Kodi UI from JSON on startup
   monitor.waitForAbort()

