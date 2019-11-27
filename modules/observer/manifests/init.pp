# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: observer
#
# DHtech Observer, end-to-end testing of DNS, DHCP, and ping
#
# === Parameters
#
# No parameters;
#

class observer($nameservers, $icmp_target, $dns_target) {

  # Create directories for observer
  file { '/opt/observer':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # Copy observer-bundle to the server and extract
  file { '/opt/observer/observer.gz':
    ensure => file,
    source => "puppet:///data/observer-d01b469.linux-${::facts['os']['architecture']}.gz",
    notify => Exec['extract-observer'],
  }
  exec { 'extract-observer':
    command     => '/usr/bin/gunzip -n /opt/observer/observer.gz',
    refreshonly => true,
    user        => 'root',
    notify      => Service['observer'],
  }

  # Observer default file
  file { '/etc/default/observer':
    ensure  => file,
    content => template('observer/observer.default.erb'),
    notify  => Service['observer'],
  }

  file { '/etc/systemd/system/observer.service':
    ensure  => file,
    content => template('observer/observer.service.erb'),
    notify  => Exec['observer-systemctl-daemon-reload'],
  }
  exec { 'observer-systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  service { 'observer':
    ensure => running,
    enable => true,
  }

}
