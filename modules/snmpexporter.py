# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def parse_v3(secret):
  config = {
    'sec_level': 'authPriv',
    'version': 3
  }
  if 'aes' in secret['privtype'].lower():
    config['priv_proto'] = 'AES'
  else:
    config['priv_proto'] = 'DES'
  if 'sha' in secret['authtype'].lower():
    config['auth_proto'] = 'SHA'
  else:
    config['auth_proto'] = 'MD5'
  config['priv'] = '"' + secret['priv'].replace('"', '\\"') + '"'
  config['auth'] = '"' + secret['auth'].replace('"', '\\"') + '"'
  config['user'] = '"' + secret['user'].replace('"', '\\"') + '"'
  return config

def parse_v2(secret):
  config = {
    'version': 2,
    'community': '"' + secret['ro'].replace('"', '\\"') + '"',
  }
  return config

def generate(host):
  """Args is the layers we should probe."""
  domain = lib.get_domain(host)
  layers = lib.get_layers(domain)
  if domain == 'EVENT':
    mount = '%s-mgmt' % lib.get_current_event()
  else:
    mount = 'mgmt'

  info = {}
  info['layers'] = {}
  # Only configure layers that we should probe
  for layer in layers:
    config = {
      'port': 161,
    }
    secret = lib.read_secret('%s/%s' % (mount, 'snmpv3:%s' % layer))
    if secret:
      try:
        config.update(parse_v3(secret))
      except KeyError:
        # F-up, invalid layer config
        continue
    else:
      secret = lib.read_secret('%s/%s' % (mount, 'snmpv2:%s' % layer))
      if not secret:
        # F-up, no layer config
        continue
      config.update(parse_v2(secret))
    info['layers'][layer] = config
  return {'snmpexporter': info}
