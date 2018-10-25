# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: facter
#
# Class used for adding global custom facter facts.
#

class facter {

  file { '/etc/puppetlabs':
    ensure => 'directory',
    group  => 'root',
    mode   => '0655',
    owner  => 'root',
  }

  file { '/etc/puppetlabs/facter':
    ensure  => 'directory',
    group   => 'root',
    mode    => '0655',
    owner   => 'root',
    require => File['/etc/puppetlabs'],
  }

  file { '/etc/puppetlabs/facter/facts.d':
    ensure  => 'directory',
    group   => 'root',
    mode    => '0655',
    owner   => 'root',
    require => File['/etc/puppetlabs/facter'],
  }

  file { 'dh_egress_interface':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    path    => '/etc/puppetlabs/facter/facts.d/dh_egress_interface',
    content => template('facter/dh_egress_interface.erb'),
    require => File['/etc/puppetlabs/facter/facts.d'],
  }
}
