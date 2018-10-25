# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
class iptables::post ($log) {
  if $log == true {
    firewall {
      '999 v4 log all':
        proto      => 'all',
        jump       => 'LOG',
        log_prefix => 'iptables: ',
        before     =>  undef; # Dependency cycle avoidance
      '999 v6 log all':
        proto      => 'all',
        jump       => 'LOG',
        log_prefix => 'ip6tables: ',
        provider   => 'ip6tables',
        before     =>  undef, # Dependency cycle avoidance
    }
  }
}
