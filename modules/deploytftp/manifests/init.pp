# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: deploytftp
#
# Install hooktftp in order to offer TFTP -> HTTPS proxy
# for initial boot.
#

class deploytftp {

  file { '/usr/bin/hooktftp':
    ensure => file,
    source => 'puppet:///data/hooktftp-1d238815/hooktftp',
    mode   => '0755',
  }
  -> file { '/etc/hooktftp.yml':
    ensure  => file,
    content => template('deploytftp/hooktftp.yml.erb'),
  }
  -> supervisor::register { 'hooktftp':
    command  => '/usr/bin/hooktftp',
  }
}
