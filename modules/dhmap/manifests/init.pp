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
  file { '/opt/dhmap':
    ensure  => directory,
    source  => 'puppet:///repos/dhmap',
    recurse => true,
  }

  file { '/opt/dhmap/src/ipplan2dhmap.py':
  mode    => '0755',
  require => File['/opt/dhmap'],
  }

  file { 'dhmap':
    ensure => link,
    path   => '/var/www/html/dhmap',
    target => '/opt/dhmap/',
  }

  cron { 'update-seatmap':
    command => '/opt/dhmap/src/ipplan2dhmap.py /etc/ipplan.db > /var/www/html/dhmap/data.json',
    user    => root,
    minute  => '*',
    require => File['dhmap'],
  }
}
