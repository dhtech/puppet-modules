# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: system
#
# System fixes and common support software and libraries.
#
# === Parameters
#
# [*ca*]
#   PEM certificate to trust.

class system($ca) {
  include stdlib::stages

  $git_binary  = '/usr/bin/git'

  $readonly = vault('source:readonly')
  $username = $readonly['username']
  $password = $readonly['password']

  class {
    'system::setup':
      stage => 'setup';
  }

  file { 'old-ca.crt':
    ensure => file,
    path   => '/usr/share/ca-certificates/dhtech-ca-r0.crt',
    source => 'puppet:///modules/system/old-ca.crt',
    notify => Exec['update-ca'],
  }
  -> file_line { 'dhtech-ca-r0.crt trust':
    path   => '/etc/ca-certificates.conf',
    line   => 'dhtech-ca-r0.crt',
    notify => Exec['update-ca'],
  }

  file { 'ca.crt':
    ensure  => file,
    path    => '/usr/share/ca-certificates/dhtech-ca.crt',
    content => $ca,
    notify  => Exec['update-ca'],
  }
  -> file_line { 'dhtech-ca.crt trust':
    path   => '/etc/ca-certificates.conf',
    line   => 'dhtech-ca.crt',
    notify => Exec['update-ca'],
  }

  # Legacy path for old CA cert
  file { '/etc/ssl/ca.crt':
    ensure => 'link',
    target => '/usr/share/ca-certificates/dhtech-ca-r0.crt',
  }
  # Current root CA from Vault
  file { '/etc/ssl/dhtech-ca.crt':
    ensure => 'link',
    target => '/usr/share/ca-certificates/dhtech-ca.crt',
  }

  # older, less clear syntax
  file { '/tmp/link-to-motd':
    ensure => symlink,
    target => '/etc/motd',
  }

  file { 'deb-extras.list':
    ensure => file,
    path   => '/etc/apt/sources.list.d/deb-extras.list',
    source => 'puppet:///modules/system/deb-extras.list',
  }

  # TODO(bluecmd): Move whatever we can from preseed to here.
  # That way all our OSes will have the same tools.
  ensure_packages([
    'apg',
    'curl',
    'git',
    'console-data',
    'python3',
    'python3-pip',
  ])

  exec { 'update-ca':
    command     => '/usr/sbin/update-ca-certificates',
    refreshonly => true,
  }

  exec {'git-scripts-checkout':
    command => "${git_binary} clone https://${username}:${password}@doc.tech.dreamhack.se/git/scripts",
    cwd     => '/',
    creates => '/scripts',
  }
  -> exec {'git-scripts-submodules':
    command => "${git_binary} submodule init && ${git_binary} submodule update --recursive --remote",
    cwd     => '/scripts/',
    creates => '/scripts/.git/modules',
  }

  if $facts['kernelrelease'] =~ /OpenNetworkLinux/ {
    package { 'snmpd':
      ensure => 'purged',
    }
    ensure_packages(['cron'])
  }
}
