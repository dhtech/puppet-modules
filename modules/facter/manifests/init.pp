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
    owner   => "root",
    group   => "root",
    mode    => "655",
    ensure  => "directory",
  }

  file { '/etc/puppetlabs/facter':
    owner   => "root",
    group   => "root",
    mode    => "655",
    ensure  => "directory",
    require => File['/etc/puppetlabs'],
  }

  file { '/etc/puppetlabs/facter/facts.d':
    owner   => "root",
    group   => "root",
    mode    => "655",
    ensure  => "directory",
    require => File['/etc/puppetlabs/facter'],
  }

  file { 'dh_egress_interface':
    path    => "/etc/puppetlabs/facter/facts.d/dh_egress_interface",
    owner   => "root",
    group   => "root",
    mode    => "755",
    ensure  => "file",
    content => template('facter/dh_egress_interface.erb'),
    require => File['/etc/puppetlabs/facter/facts.d'],
  }
}
