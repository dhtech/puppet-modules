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
  # /opt/dhmap is symlinked into the web root below, so everything synced
  # here is publicly readable. The repository holds development and test
  # material that has no business being served, so exclude it rather than
  # relying on it being absent.
  #
  # 'local' and 'node_modules' matter most: neither is committed, but local
  # is where a real ipplan database is dropped during development, and
  # node_modules appears the moment anyone runs npm install in the checkout.
  file { '/opt/dhmap':
    ensure  => directory,
    source  => 'puppet:///repos/dhmap',
    recurse => true,
    ignore  => [
      '.git',
      '.github',
      'local',
      'node_modules',
      'test',
      'Makefile',
      'package.json',
      'package-lock.json',
      'playwright.config.js',
    ],
  }

  file { '/opt/dhmap/src/ipplan2dhmap.py':
    mode    => '0755',
    source  => 'puppet:///repos/dhmap/src/ipplan2dhmap.py',
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
