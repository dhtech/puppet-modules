# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: gitlab_runner
#
# Full description of class here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#

class gitlab_runner {

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
  }
  -> exec { 'docker-source-key':
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

  # Add source and install gitlab_runner
  file { 'gitlab_runner-source-add':
    ensure  => file,
    path    => '/etc/apt/sources.list.d/gitlab_runner.list',
    content => 'deb https://packages.gitlab.com/runner/gitlab-runner/debian/ buster main',
    notify  => Exec['gitlab_runner-source-key'],
  }
  -> exec { 'gitlab_runner-source-key':
    command     => '/usr/bin/curl -fsSL https://packages.gitlab.com/runner/gitlab-runner/gpgkey | /usr/bin/apt-key add -',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['gitlab_runner-source-update'],
  }
  exec { 'gitlab_runner-source-update':
    command     => '/usr/bin/apt-get update',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    require     => Package['apt-transport-https'],
  }
  package { 'gitlab-runner':
    ensure  => installed,
    require => [File['gitlab_runner-source-add'], Exec['docker-source-key'], Exec['docker-source-update']],
  }

  file { '/etc/apt/preferences.d/pin-gitlab-runner.pref':
    ensure  => file,
    content => template('gitlab_runner/pin-gitlab-runner.erb'),
  }
}
