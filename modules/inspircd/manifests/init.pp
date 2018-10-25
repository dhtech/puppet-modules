# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: inspircd
#
# Full description of class here.
#
# === Parameters
#
# Document parameters here.
#
# [*peers*]
#   List of peers that the server will connect towards.
#   This includes the variables "fqdn" and "allowmask"
#
# [*sid*]
#   String for identifying the unique irc-server
#

class inspircd ($peers, $sid) {
  $secret = vault('ircd:secret', {})
  $rocketchatsecret = vault('ircd:rocketchat', {})

  package { 'inspircd':
    ensure  => 'installed',
  }

  group { 'puppet':
    ensure => 'present',
  }

  user { 'irc':
    groups     => 'puppet',
    membership => minimum,
  }

  service {'inspircd':
    ensure  => running,
    enable  => true,
    restart => 'service inspircd reload',
    require => [
                  Package['inspircd'],
                  File['/etc/inspircd/dhtech.helpop'],
                  File['/etc/inspircd/dhtech.motd'],
                  File['/etc/inspircd/dhtech.rules'],
                  File['/etc/inspircd/inspircd.conf'],
                  File['/etc/inspircd/ssl'],
    ]
  }

  file { '/etc/inspircd':
    ensure => 'directory',
    mode   => '0750',
    owner  => 'irc',
    group  => 'irc',
  }

  file { '/etc/inspircd/dhtech.helpop':
    ensure => present,
    source => 'puppet:///modules/inspircd/dhtech.helpop',
    mode   => '0640',
    owner  => 'irc',
    group  => 'irc',
    notify => Service['inspircd'],
  }

  file { '/etc/inspircd/dhtech.motd':
    ensure => present,
    source => 'puppet:///modules/inspircd/dhtech.motd',
    mode   => '0640',
    owner  => 'irc',
    group  => 'irc',
    notify => Service['inspircd'],
  }

  file { '/etc/inspircd/dhtech.rules':
    ensure => present,
    source => 'puppet:///modules/inspircd/dhtech.rules',
    mode   => '0640',
    owner  => 'irc',
    group  => 'irc',
    notify => Service['inspircd'],
  }

  file { '/etc/inspircd/inspircd.conf':
    ensure  => present,
    content => template('inspircd/inspircd.conf.erb'),
    mode    => '0640',
    owner   => 'irc',
    group   => 'irc',
    notify  => Service['inspircd'],
  }

  file { '/etc/inspircd/modules.conf':
    ensure => present,
    source => 'puppet:///modules/inspircd/modules.conf',
    mode   => '0640',
    owner  => 'irc',
    group  => 'irc',
    notify => Service['inspircd'],
  }

  file { '/etc/inspircd/opers.conf':
    ensure  => present,
    content => template('inspircd/opers.conf.erb'),
    mode    => '0640',
    owner   => 'irc',
    group   => 'irc',
    notify  => Service['inspircd'],
  }

  file { '/etc/inspircd/links.conf':
    content => template('inspircd/links.conf.erb'),
    mode    => '0640',
    owner   => 'irc',
    group   => 'irc',
    notify  => Service['inspircd'],
  }

  file { '/etc/inspircd/bind.conf':
    content => template('inspircd/bind.conf.erb'),
    mode    => '0640',
    owner   => 'irc',
    group   => 'irc',
    notify  => Service['inspircd'],
  }

  file { '/etc/inspircd/server.conf':
    content => template('inspircd/server.conf.erb'),
    mode    => '0640',
    owner   => 'irc',
    group   => 'irc',
    notify  => Service['inspircd'],
  }

  file { '/etc/inspircd/ssl':
    ensure  => 'directory',
    source  => 'file:////var/lib/puppet/ssl',
    recurse => 'remote',
    mode    => '0640',
    owner   => 'irc',
    group   => 'irc',
    notify  => Service['inspircd'],
  }

}
