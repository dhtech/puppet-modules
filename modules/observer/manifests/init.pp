# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: observer
#
# DHtech Observer, end-to-end testing of DNS, DHCP, and ping
#
# === Parameters
#
# No parameters;
#

class observer($nameservers, $icmp_target, $dns_target) {

  # Create directories for observer
  file { '/opt/observer':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  file { '/home/tech/icooktacos/helloworld.txt':
    ensure => present,
    content => 'Hello World!',
  }

}
