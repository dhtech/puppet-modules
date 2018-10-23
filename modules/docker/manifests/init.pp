# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: docker
#
# Installs docker and updates daemon.json from template.
#
# === Parameters
#

class docker {

  # Install basic packages
  ensure_packages([
      'apt-transport-https',
      'ca-certificates',
      'curl',
      'software-properties-common',
      'gnupg',
  ])

  # Add source and install docker
  file { 'docker-source-add':
    ensure  => file,
    path    => '/etc/apt/sources.list.d/docker.list',
    content => 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable',
    notify  => Exec['docker-source-key'],
  }->
  exec { 'docker-source-key':
    command     => '/usr/bin/curl -fsSL https://download.docker.com/linux/ubuntu/gpg | /usr/bin/apt-key add -',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['docker-source-update'],
  }
  exec { 'docker-source-update':
    command     => '/usr/bin/apt-get update',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    require     => Package['apt-transport-https'],
  }
  package { 'docker-ce':
    ensure  => installed,
    require => [File['docker-source-add'], Exec['docker-source-key'], Exec['docker-source-update']],
  }

  # Update sysctl to handle forwarding
  file { '/etc/sysctl.d/dh-docker.conf':
    ensure  => 'file',
    content => 'net.bridge.bridge-nf-call-iptables=1',
  }~>
  exec { 'refresh-sysctl':
    command     => '/sbin/sysctl --system',
    refreshonly => true,
  }

  file { '/etc/docker':
      ensure => directory,
  }

  file { '/etc/docker/daemon.json':
     ensure  => file,
     content => template('docker/daemon.json.erb'),
     notify  => Package['docker-ce'],
  }

}
