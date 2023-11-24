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
  # Use the rancid backup user for local health check
  $radtest_secret = vault('login:backup', {})

  ensure_packages([
    'freeradius', 'freeradius-common', 'freeradius-python3',
    'freeradius-utils'])

  service { 'freeradius':
    ensure     => 'running',
    name       => 'freeradius',
    enable     => true,
    hasstatus  => false,
    hasrestart => true,
    status     => 'pgrep freeradius',
  }

  package { 'python3-pam':
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
    path   => '/etc/freeradius/3.0/mods-available/python3',
    source => 'puppet:///scripts/radius/modules/python3',
    notify => Service['freeradius'],
  }

  file { 'radius-module-link':
    ensure => link,
    path   => '/etc/freeradius/3.0/mods-enabled/python3',
    target => '/etc/freeradius/3.0/mods-available/python3',
    notify => Service['freeradius'],
  }

  file { 'dh-radius-login':
    ensure => file,
    path   => '/usr/lib/python3/dist-packages/dh-radius-login.py',
    source => 'puppet:///scripts/radius/login.py3',
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
    ensure    => file,
    content   => template('radiusd/clients.conf.erb'),
    notify    => Service['freeradius'],
    show_diff => no,
  }

  file { '/etc/freeradius/radius-check.sh':
    ensure    => file,
    content   => template('radiusd/radius-check.sh.erb'),
    mode      => '0700',
    show_diff => no,
  }

  cron { 'prometheus-exporter-radius-check':
    command => '/etc/freeradius/radius-check.sh',
    minute  => '*',
    require => File['/etc/freeradius/radius-check.sh'],
  }

  file { '/etc/freeradius/security-auth-check.py':
    ensure    => file,
    content   => template('radiusd/security-auth-check.py.erb'),
    mode      => '0700',
  }

  cron { 'prometheus-exporter-radius-security-auth-check':
    command => '/etc/freeradius/security-auth-check.py',
    minute  => '*',
    require => File['/etc/freeradius/security-auth-check.py'],
  }
}
