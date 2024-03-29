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

  ensure_packages([
      'mtr-tiny', 'rancid', 'snmp', 'dnsutils', 'nmap', 'bash-completion',
      'ndisc6', 'python3-paramiko', 'python3-requests', 'netcat', 'ipmitool',
      'prometheus-blackbox-exporter', 'python3-redis', 'python3-yaml'])

  service { 'prometheus-blackbox-exporter':
    ensure  => 'running',
    enable  => true,
    require => File['blackbox-config'],
  }

  file {
    '/usr/local/bin/access_ssh_checker.py':
      ensure  => file,
      mode    => '0755',
      source  => 'puppet:///scripts/access_ssh_checker/access_ssh_checker.py',
      require => [Package['python3-paramiko'], Package['python3-paramiko']],
  }

  file { 'dhssh':
    ensure => file,
    path   => '/usr/local/bin/dhssh.py',
    mode   => '0755',
    source => 'puppet:///scripts/dhssh/dhssh.py',
  }

  file { 'ssh_config':
    ensure => file,
    path   => '/etc/ssh/ssh_config',
    source => 'puppet:///modules/jumpgate/ssh_config',
  }

  file { 'dreamhack-profile':
    ensure => file,
    path   => '/etc/profile.d/dreamhack.sh',
    source => 'puppet:///modules/jumpgate/dreamhack.sh',
  }

  file { 'blackbox-config':
    ensure => file,
    path   => '/etc/prometheus/blackbox.yml',
    source => 'puppet:///modules/jumpgate/blackbox.yml',
    notify => Service['prometheus-blackbox-exporter'],
  }

  file { 'ipplan-completion.py':
    ensure => file,
    path   => '/usr/local/bin/ipplan-completion.py',
    mode   => '0755',
    source => 'puppet:///scripts/ipplan-completion/ipplan-completion.py',
  }

  file { 'ipplan-completion.sh':
    ensure => file,
    path   => '/etc/bash_completion.d/ipplan-completion.sh',
    source => 'puppet:///scripts/ipplan-completion/ipplan-completion.sh',
  }

  $redis_secret =  vault('provision-redis')

  file { 'deploy.yaml':
    ensure  => file,
    path    => '/etc/deploy.yaml',
    content => template('jumpgate/deploy.yaml.erb'),
  }

  file { 'deploy-vm':
    ensure => file,
    path   => '/usr/local/bin/deploy-vm',
    mode   => '0755',
    source => 'puppet:///scripts/deploy-github/utils/deploy-vm',
  }

  file { 'deploy-bay':
    ensure => file,
    path   => '/usr/local/bin/deploy-bay',
    mode   => '0755',
    source => 'puppet:///scripts/deploy-github/utils/deploy-bay',
  }
}
