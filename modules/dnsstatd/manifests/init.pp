# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dnsstatd
#
# dnsstatd - a DNS server statistics collector
#
# === Parameters
#
# [*current_event*]
#   Used for retrieving database credentials of the dnsstatd database.
#

class dnsstatd($current_event) {

  $secret_db_dnsstatd   = vault('postgresql:dnsstatd', {})

  ensure_packages([
    'python-netifaces',
    'python-psycopg2'])

  package { 'dnslib':
    ensure   => installed,
    provider => 'pip',
  }

  package { 'libpcap':
    ensure   => installed,
    provider => 'pip',
  }

  package { 'dpkt':
    ensure   => installed,
    provider => 'pip',
  }

  if $secret_db_dnsstatd != {} {
    file { '/scripts/dnsstatd/config':
      ensure  => file,
      content => template('dnsstatd/config.erb'),
      mode    => '0600',
      notify  => Supervisor::Restart['dnsstatd'],
    }
  }

  supervisor::register { 'dnsstatd':
    command => '/scripts/dnsstatd/dnsstatd.py',
  }
    file { '/etc/apparmor.d/usr.sbin.named':
    ensure => 'file',
    notify => Service['apparmor'],
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/dnsstatd/usr.sbin.named',
  }

  service { 'apparmor':
    ensure => 'running',
    enable => true,
  }
}
