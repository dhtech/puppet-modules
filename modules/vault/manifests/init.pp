# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: vault
#
# Install client vault binary
#
# === Parameters
#
# No parameters
#

class vault {

  ensure_packages(['apg', 'python-setuptools', 'python-wheel-common'])

  package { 'hvac':
    provider => 'pip',
  }

  if $::kernel == 'Linux' {
    file { 'vault':
      ensure => file,
      path   => '/usr/local/bin/vault',
      mode   => '0755',
      source => 'puppet:///scripts/vault/vault',
    }
    file { 'vault-profile':
      ensure  => file,
      path    => '/etc/profile.d/vault.sh',
      mode    => '0664',
      content => template('vault/profile.erb'),
    }
  }

  if $::operatingsystem == 'Debian' and $::operatingsystemmajrelease >= '11' {
    file { 'vault-input':
      ensure => file,
      path   => '/usr/local/bin/vault-input',
      mode   => '0755',
      source => 'puppet:///scripts/vault/vault-input.py3',
    }
  }
  else {
    file { 'vault-input':
      ensure => file,
      path   => '/usr/local/bin/vault-input',
      mode   => '0755',
      source => 'puppet:///scripts/vault/vault-input',
    }
  }

  file { 'vault-login':
    ensure => file,
    path   => '/usr/local/bin/vault-login',
    mode   => '0755',
    source => 'puppet:///scripts/vault/vault-login',
  }

  # remove the old file, vault altered the command to login, see above
  file { 'vault-auth':
    ensure => absent,
    path   => '/usr/local/bin/vault-auth',
  }

  if $::operatingsystem == 'Debian' and $::operatingsystemmajrelease >= '11' {
    file { 'vault-machine':
      ensure => file,
      path   => '/usr/local/bin/vault-machine',
      mode   => '0755',
      source => 'puppet:///scripts/vault/vault-machine-v2',
    }
  }
  else {
    file { 'vault-machine':
      ensure => file,
      path   => '/usr/local/bin/vault-machine',
      mode   => '0755',
      source => 'puppet:///scripts/vault/vault-machine',
    }
  }

  if $::operatingsystem == 'Debian' and $::operatingsystemmajrelease >= '11' {
    file { 'dh-create-service-account':
      ensure => file,
      path   => '/usr/local/bin/dh-create-service-account',
      mode   => '0755',
      source => 'puppet:///scripts/vault/dh-create-service-account.py3',
    }
  }
  else {
    file { 'dh-create-service-account':
      ensure => file,
      path   => '/usr/local/bin/dh-create-service-account',
      mode   => '0755',
      source => 'puppet:///scripts/vault/dh-create-service-account',
    }
  }
}
