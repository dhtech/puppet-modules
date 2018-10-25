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

class dhmon::analytics {
  ensure_packages(['python-flask'])

  package { 'futures':
    provider => 'pip',
  }

  supervisor::register { 'analytics':
    command   => '/usr/bin/python2 /scripts/dhmon/src/analytics/analytics.py'
  }
  -> apache::proxy { 'analytics':
    url     => '/analytics',
    backend => 'http://localhost:5000',
  }
}
