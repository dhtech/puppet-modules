# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: pinger
#
# dhmon pinger
#
# === Parameters
#

class pinger {
  package { 'prometheus-client':
    provider => 'pip',
  }

  ensure_packages(['build-essential', 'python3-dev'])

  file { '/opt/pinger.src':
    ensure  => directory,
    recurse => remote,
    source  => 'puppet:///scripts/pinger/',
  }
  ~> exec { 'make-pingerd':
    command     => '/usr/bin/make install DESTDIR=/',
    cwd         => '/opt/pinger.src/src/pinger',
    refreshonly => true,
  }
  ~> file { 'pingerd.service':
    ensure => present,
    source => '/opt/pinger.src/pingerd.service',
    path   => '/etc/systemd/system/pingerd.service',
  }

  service { 'pingerd':
    ensure    => 'running',
    enable    => true,
    subscribe => [
      File['pingerd.service'],
      Exec['make-pingerd']
    ],
    require   => [File['pingerd.service']],
  }
}
