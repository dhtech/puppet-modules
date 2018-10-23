# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ldapsyncprober
#
# A script to trigger a replication, so that we can check that it works.
#
# === Parameters
#
# [*trigger_interval*]
#   Interval in seconds to trigger the replication
#

class ldapsyncprober ($trigger_interval) {
  #TODO(klump) This should become a service that is triggering replication
  # quite often, at least once a second. This allows us to measure
  # replication latency in a better resolution.

  user { 'ldapsync-prober':
    ensure     => present,
    # TODO(klump) Maybe we should use a special cert here to identify the user
    # and not the machine based cert.
    groups     => ['ssl-cert'],
    membership => 'minimum',
  }

  file { 'ldapsync_prober':
    ensure => directory,
    path   => '/opt/ldapsync_prober',
    mode   => '0750',
    owner  => 'ldapsync-prober',
    group  => 'ldapsync-prober',
  }

  file { 'ldapsync_prober.sh':
    ensure => file,
    path   => '/opt/ldapsync_prober/ldapsync_prober.sh',
    mode   => '0750',
    owner  => 'ldapsync-prober',
    group  => 'ldapsync-prober',
    source => 'puppet:///modules/ldapsyncprober/ldapsync_prober.sh',
  }

  file { 'ldapsync_prober.service':
    ensure  => file,
    path    => '/etc/systemd/system/ldapsync_prober.service',
    mode    => '0644',
    content => template('ldapsyncprober/ldapsync_prober.service.erb'),
    require => [File['ldapsync_prober.sh'], User['ldapsync-prober']],
  }

  file { 'ldapsync_prober.timer':
    ensure  => file,
    path    => '/etc/systemd/system/ldapsync_prober.timer',
    mode    => '0644',
    content => template('ldapsyncprober/ldapsync_prober.timer.erb'),
    require => [File['ldapsync_prober.service']],
  }

  service { 'ldapsync_prober.timer':
    enable  => true,
    require => [File['ldapsync_prober.timer']],
  }
}
