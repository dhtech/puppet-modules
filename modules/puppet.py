# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):
  my_environment = lib.get_environment(host)
  masters = sorted(lib.get_nodes_with_package('puppetmaster').keys())

  # Do not install client agent files on master, it's managed by SVN instead
  if host in masters:
    return {}

  ipv4, _ = lib.resolve_nodes_to_ip((host, ))[host]

  info = {}
  info['sourceaddress'] = ipv4
  info['master'] = sorted(masters)[0]
  info['environment'] = my_environment

  return {'puppet': info}
