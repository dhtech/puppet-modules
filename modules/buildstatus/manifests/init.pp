# Copyright 2019 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: buildstatus
#
# Installs the buildstatus web frontend.
#
# === Parameters
#

class buildstatus {
  exec { 'download-buildstatus':
    command => '/usr/bin/git clone https://github.com/dhtech/buildstatus /var/www/html/buildstatus',
    creates => '/var/www/html/buildstatus',
  }

  cron { 'update-buildstatus':
    command => '/usr/bin/git --git-dir=/var/www/html/buildstatus.git --work-tree=/var/www/html/buildstatus pull',
    minute  => '*',
    require => Exec['download-buildstatus'],
  }

}
