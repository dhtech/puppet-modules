# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):

  current_event = lib.get_current_event()

  ldap_server = sorted(lib.get_servers_for_node('ldap', host))[0]

  info = {}
  info['current_event'] = current_event
  info['ldap_server'] = ldap_server

  return {'obsdlogin': info}
