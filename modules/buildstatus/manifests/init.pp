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
  file { 'webmon':
    path    => '/var/www/html/webmon',
    source  => 'puppet:///scripts/webmon',
    recurse => true,
  }

}
