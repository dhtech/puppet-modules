# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dhmap
#
# Static HTML for dhmap
#
# === Parameters
#

class dhmap {

  file { 'dhmap':
    ensure => link,
    path   => '/var/www/html/dhmap',
    target => '/scripts/dhmap/',
  }

  cron { 'update-seatmap':
    command => '/scripts/dhmap/src/ipplan2dhmap.py /etc/ipplan.db > /var/www/html/dhmap/data.json',
    user    => root,
    minute  => '*',
    require => File['dhmap'],
  }
}
