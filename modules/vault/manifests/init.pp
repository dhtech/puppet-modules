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

  ensure_packages(['apg', 'python-setuptools', 'python-wheel'])

  package { 'hvac':
    provider => 'pip',
  }

  if $kernel == 'Linux' {
    file { 'vault':
      path    => '/usr/local/bin/vault',
      ensure  => file,
      mode    => '0755',
      source  => 'puppet:///scripts/vault/vault',
    }
    file { 'vault-profile':
      path    => '/etc/profile.d/vault.sh',
      ensure  => file,
      mode    => '0664',
      content => template('vault/profile.erb'),
    }
  }

  file { 'vault-input':
    path    => '/usr/local/bin/vault-input',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/vault/vault-input',
  }

  file { 'vault-login':
    path    => '/usr/local/bin/vault-login',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/vault/vault-login',
  }

  # remove the old file, vault altered the command to login, see above
  file { 'vault-auth':
    path    => '/usr/local/bin/vault-auth',
    ensure  => absent,
  }

  file { 'vault-machine':
    path    => '/usr/local/bin/vault-machine',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/vault/vault-machine',
  }

  file { 'dh-create-service-account':
    path    => '/usr/local/bin/dh-create-service-account',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/vault/dh-create-service-account',
  }
}
