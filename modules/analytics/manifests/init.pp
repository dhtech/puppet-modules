# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: analytics
#
# Simple API endpoint for dhmon (used for dhmap and buildstatus among others)
#
# === Parameters
#

class analytics {
  ensure_packages(['python3-flask'])

  package { 'futures':
    provider => 'pip',
    notify   => Exec['download-analytics'],
  }

  exec { 'download-analytics':
    command     => '/usr/bin/git clone https://github.com/dhtech/analytics /analytics',
    refreshonly =>  true,
  }

  supervisor::register { 'analytics':
    command   => '/usr/bin/python3 /analytics/analytics.py'
  }

  apache::proxy { 'analytics':
    url     => '/analytics',
    backend => 'http://localhost:5000',
  }

  cron { 'update-analytics':
    command => '/usr/bin/git --git-dir=/analytics.git --work-tree=/analytics pull',
    minute  => '*',
    require => Exec['download-analytics'],
  }
}
