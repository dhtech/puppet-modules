# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: obsdlogin
#
# Full description of class here.
#
# === Parameters
#
# [*current_event*]
#   The current event name.
#

class obsdlogin ($current_event = '', $ldap_server = '') {

  file { 'sudoers':
    ensure  => file,
    path    => '/etc/sudoers',
    content => template('obsdlogin/sudoers.erb'),
    owner   => 'root',
    group   => 'wheel',
    mode    => '0440',
    require => Package['sudo'],
  }

  file { 'openup':
    ensure  => file,
    path    => '/usr/local/sbin/openup',
    content => template('obsdlogin/openup'),
    owner   => 'root',
    group   => 'wheel',
    mode    => '0755',
  }

  file { 'sshd_config':
    ensure  => file,
    path    => '/etc/ssh/sshd_config',
    content => template('obsdlogin/sshd_config.erb'),
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    notify  => Service['sshd'],
  }

  file { 'ldap.conf':
    ensure  => file,
    path    => '/etc/openldap/ldap.conf',
    content => template('obsdlogin/ldap.conf.erb'),
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    require => Package['openldap-client'],
  }

  service { 'sshd':
    ensure => 'running',
    enable => true,
  }

  file { 'adduser.conf':
    ensure  => file,
    path    => '/etc/adduser.conf',
    content => template('obsdlogin/adduser.conf.erb'),
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
  }

  file { 'obsdlogin-create-users':
    ensure  => file,
    path    => '/usr/local/sbin/obsdlogin-create-users',
    content => template('obsdlogin/obsdlogin-create-users.erb'),
    owner   => 'root',
    group   => 'wheel',
    mode    => '0755',
  }

  package { 'openldap-client':
    ensure => installed,
  }

  package { 'sudo':
    ensure => installed,
  }

  package { 'python':
    ensure => installed,
  }

  package { 'py-ldap':
    ensure => installed,
  }

  file { '/usr/local/bin/python':
    ensure  => 'link',
    target  => '/usr/local/bin/python2.7',
    require => Package['python'],
  }

  file { '/usr/local/bin/2to3':
    ensure  => 'link',
    target  => '/usr/local/bin/python2.7-2to3',
    require => Package['python'],
  }

  file { '/usr/local/bin/python-config':
    ensure  => 'link',
    target  => '/usr/local/bin/python2.7-config',
    require => Package['python'],
  }

  file { '/usr/local/bin/pydoc':
    ensure  => 'link',
    target  => '/usr/local/bin/pydoc2.7',
    require => Package['python'],
  }

  exec { '/usr/local/sbin/obsdlogin-create-users':
    subscribe => File['obsdlogin-create-users'],
    onlyif    => '/usr/local/sbin/obsdlogin-create-users --check',
    require   => [ File['/usr/local/bin/python'], File['adduser.conf'], File['ldap.conf'], Package['py-ldap'], ]
  }
}
