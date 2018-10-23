# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dhcpinfo
#
# This package manages the common files required by all dhcpinfo
# components
#
# === Parameters
#
# [*current_event*]
#   Used for setting the name of the dhcpinfo database.
#

class dhcpinfo($current_event) {

  file { '/opt/dhcpinfo':
    path    => "/opt/dhcpinfo",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "directory",
  }

  file { '/opt/dhcpinfo/rrd':
    path    => "/opt/dhcpinfo/rrd",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "directory",
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/public':
    path    => "/opt/dhcpinfo/public",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "directory",
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/config':
    path    => "/opt/dhcpinfo/config",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "directory",
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/model':
    path    => "/opt/dhcpinfo/model",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "directory",
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/model/Active_Leases.rb':
    path    => "/opt/dhcpinfo/model/Active_Leases.rb",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "file",
    source  => "puppet:///scripts/dhcpinfo/model/Active_Leases.rb",
    require => File['/opt/dhcpinfo/model'],
  }

  file { '/opt/dhcpinfo/model/Scope.rb':
    path    => "/opt/dhcpinfo/model/Scope.rb",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "file",
    source  => "puppet:///scripts/dhcpinfo/model/Scope.rb",
    require => File['/opt/dhcpinfo/model'],
  }

  file { '/opt/dhcpinfo/model/Lease.rb':
    path    => "/opt/dhcpinfo/model/Lease.rb",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "file",
    source  => "puppet:///scripts/dhcpinfo/model/Lease.rb",
    require => File['/opt/dhcpinfo/model'],
  }

  $secret = vault("postgresql:dhcpinfo")

  $dhcpinfo_hostname = $secret['hostname']
  $dhcpinfo_username = $secret['username']
  $dhcpinfo_password = $secret['password']

  file { 'database.yml':
    path    => "/opt/dhcpinfo/config/database.yml",
    owner   => "root",
    group   => "root",
    mode    => "750",
    ensure  => "file",
    content => template('dhcpinfo/database.yml.erb'),
    require => File['/opt/dhcpinfo/config'],
  }

  package { 'netaddr':
    ensure   => 'installed',
    provider => 'gem',
  }

  package { 'ruby-activerecord':
    ensure => 'installed',
  }

  package { 'ruby-pg':
    ensure => 'installed',
  }

}
