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

  $secret_db_dnsstatd = vault('postgresql:dnsstatd', {})

  ensure_packages([
    'python3-netifaces',
    'python3-psycopg2'])

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

  file { '/opt/dnsstatd':
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }

  file { '/opt/dnsstatd/dnsstatd.py':
      ensure => present,
      source => 'puppet:///repos/dnsstatd/dnsstatd.py',
      mode   => '0750',
      owner  => 'root',
      group  => 'root',
  }

  if $secret_db_dnsstatd != {} {
    file { '/opt/dnsstatd/config':
      ensure  => file,
      content => template('dnsstatd/config.erb'),
      mode    => '0600',
      notify  => Supervisor::Restart['dnsstatd'],
    }
  }

  supervisor::register { 'dnsstatd':
    command => '/opt/dnsstatd/dnsstatd.py',
  }
}
