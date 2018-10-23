# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: jumpgate
#
# Install jumpgate specific configuration, packages and utils.
#
# === Parameters
#
# No parameters.
#

class jumpgate {

  package { 'mtr-tiny':
    ensure => installed,
  }

  package { 'rancid':
    ensure => installed,
  }

  package { 'snmp':
    ensure => installed,
  }

  package { 'dnsutils':
    ensure => installed,
  }

  package { 'nmap':
    ensure => installed,
  }

  package { 'bash-completion':
    ensure => installed,
  }

  package { 'ndisc6':
    ensure => installed,
  }

  # access_ssh_checker dependencies
  package {
    [
      'python-paramiko',
      'python-requests'
    ]:
      ensure => installed,
  }

  file {
    '/usr/local/bin/access_ssh_checker.py':
      ensure => file,
      mode => '0755',
      source => 'puppet:///scripts/access_ssh_checker/access_ssh_checker.py',
      require => [Package['python-paramiko'], Package['python-paramiko']],
  }

  file { 'dhssh':
    path    => '/usr/local/bin/dhssh.py',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/dhssh/dhssh.py',
  }

  file { 'ssh_config':
    path    => '/etc/ssh/ssh_config',
    ensure  => file,
    source  => 'puppet:///modules/jumpgate/ssh_config',
  }

  file { 'dreamhack-profile':
    path    => '/etc/profile.d/dreamhack.sh',
    ensure  => file,
    source  => 'puppet:///modules/jumpgate/dreamhack.sh',
  }

  file { 'ipplan-completion.py':
    path    => '/usr/local/bin/ipplan-completion.py',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/ipplan-completion/ipplan-completion.py',
  }

  file { 'ipplan-completion.sh':
    path    => '/etc/bash_completion.d/ipplan-completion.sh',
    ensure  => file,
    source  => 'puppet:///scripts/ipplan-completion/ipplan-completion.sh',
  }

  $redis_secret =  vault("provision-redis")

  file { 'deploy.yaml':
    path => '/etc/deploy.yaml',
    ensure => file,
    content => template('jumpgate/deploy.yaml.erb'),
  }

  file { 'deploy-vm':
    path    => '/usr/local/bin/deploy-vm',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/deploy-github/utils/deploy-vm',
  }

  file { 'deploy-bay':
    path    => '/usr/local/bin/deploy-bay',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///scripts/deploy-github/utils/deploy-bay',
  }
}
