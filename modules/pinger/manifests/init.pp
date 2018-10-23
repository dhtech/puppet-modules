# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: pinger
#
# dhmon pinger
#
# === Parameters
#

class pinger {
  require dhmon::common

  package { 'prometheus_client':
    provider => 'pip',
  }->
  dhmon::package {
    'pinger':
  }

  supervisor::register { 'pinger':
    command   => '/usr/bin/pingerd',
    require   => Package['pinger'],
  }
}
