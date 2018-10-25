# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: radiusd
#
# Installs a radiusd server with the group-based logins system for
# network equipment.
#
# === Parameters
#
# [*switch_networks*]
#   Networks that we have switches on that will be protected.
#

class radiusd ($access_ips = [], $dist_ips = [], $core_ips = [], $firewall_ips = [], $partner_ips = []) {

  $core_secret = vault('radius:core', {})
  $dist_secret = vault('radius:dist', {})
  $access_secret = vault('radius:access', {})
  $firewall_secret = vault('radius:firewall', {})
  $partner_secret = vault('radius:partner', {})

  package { 'freeradius':
    ensure => installed,
  }
  package { 'freeradius-common':
    ensure => installed,
  }

  service { 'freeradius':
    ensure     => 'running',
    name       => 'freeradius',
    enable     => true,
    hasstatus  => false,
    hasrestart => true,
    status     => 'pgrep freeradius',
  }

  package { 'python-pam':
    ensure => installed,
  }

  file { 'radius-site':
    ensure => file,
    path   => '/etc/freeradius/3.0/sites-available/default',
    source => 'puppet:///scripts/radius/sites-available/default',
    notify => Service['freeradius'],
  }

  file { 'radius-site-link':
    ensure => link,
    path   => '/etc/freeradius/3.0/sites-enabled/default',
    target => '/etc/freeradius/3.0/sites-available/default',
    notify => Service['freeradius'],
  }

  file { 'radius-module':
    ensure => file,
    path   => '/etc/freeradius/3.0/mods-available/python',
    source => 'puppet:///scripts/radius/modules/python',
    notify => Service['freeradius'],
  }

  file { 'radius-module-link':
    ensure => link,
    path   => '/etc/freeradius/3.0/mods-enabled/python',
    target => '/etc/freeradius/3.0/mods-available/python',
    notify => Service['freeradius'],
  }

  file { 'dh-radius-login':
    ensure => file,
    path   => '/usr/lib/python2.7/dh-radius-login.py',
    source => 'puppet:///scripts/radius/login.py',
    notify => Service['freeradius'],
  }


  file { 'pam.d_radiusd':
    ensure => file,
    path   => '/etc/pam.d/radiusd',
    mode   => '0644',
    source => 'puppet:///scripts/radius/pam.d_radiusd',
    notify => Service['freeradius'],
  }

  file { '/etc/freeradius/3.0/clients.conf':
    ensure  => file,
    content => template('radiusd/clients.conf.erb'),
  }

}
