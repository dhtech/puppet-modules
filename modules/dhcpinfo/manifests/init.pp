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
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
    path   => '/opt/dhcpinfo',
  }

  file { '/opt/dhcpinfo/rrd':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/rrd',
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/public':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/public',
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/config':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/config',
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/model':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/model',
    require => File['/opt/dhcpinfo'],
  }

  file { '/opt/dhcpinfo/model/Active_Leases.rb':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/model/Active_Leases.rb',
    source  => 'puppet:///scripts/dhcpinfo/model/Active_Leases.rb',
    require => File['/opt/dhcpinfo/model'],
  }

  file { '/opt/dhcpinfo/model/Scope.rb':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/model/Scope.rb',
    source  => 'puppet:///scripts/dhcpinfo/model/Scope.rb',
    require => File['/opt/dhcpinfo/model'],
  }

  file { '/opt/dhcpinfo/model/Lease.rb':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/model/Lease.rb',
    source  => 'puppet:///scripts/dhcpinfo/model/Lease.rb',
    require => File['/opt/dhcpinfo/model'],
  }

  $secret = vault('postgresql:dhcpinfo')

  $dhcpinfo_hostname = $secret['hostname']
  $dhcpinfo_username = $secret['username']
  $dhcpinfo_password = $secret['password']

  file { 'database.yml':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/config/database.yml',
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
