# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
class iptables::ng::trailer (

  Boolean $log_input

) {

  if $log_input== true {

    iptables::ng::advanced_rule { 'log all':
      type  => 'both',
      order => 999,
      rule  => '-A INPUT -j LOG',
    }

  }

}
