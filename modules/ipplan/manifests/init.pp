# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ipplan
#
# Schedule download of ipplan.
#
# === Parameters
#
# No parameters!
#

class ipplan {

  # Kubernetes workloads use /etc/ipplan/ipplan.db since its nicer to
  # mount directories rather than files. To keep things similar, make sure
  # that path exists on normal VMs as well.
  file { 'ipplan-dir':
    ensure => directory,
    path   => '/etc/ipplan/',
  }
  file { 'ipplan-symlink':
    ensure => 'link',
    path   => '/etc/ipplan/ipplan.db',
    target => '/etc/ipplan.db',
  }

  file { 'ipplan-cron':
    ensure => file,
    path   => '/usr/local/bin/ipplan-cron.sh',
    mode   => '0755',
    source => 'puppet:///scripts/ipplan/ipplan-cron.sh',
  }

  cron { 'ipplan-crontab':
    command => '/usr/local/bin/ipplan-cron.sh',
    user    => root,
    minute  => '*',
    require => File['ipplan-cron'],
  }

}
