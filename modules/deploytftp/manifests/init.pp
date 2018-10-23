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
    source   => 'puppet:///data/hooktftp-1d238815/hooktftp',
    ensure   => file,
    mode     => '0755',
  }->
  file { '/etc/hooktftp.yml':
    content  => template('deploytftp/hooktftp.yml.erb'),
    ensure   => file,
  }->
  supervisor::register { 'hooktftp':
    command  => '/usr/bin/hooktftp',
  }
}
