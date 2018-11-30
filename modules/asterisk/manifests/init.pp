# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: asterisk
#
# Asterisk deployment and configuration module
#
# === Parameters
#
# [*current_event*]
#   The current event, used to decide the name of the dhcpinfo database
#

class asterisk($current_event) {
  $iax_secret = vault('asterisk:iax2', {})

  package { 'asterisk':
    ensure  => installed,
  }
  package { 'python-jinja2':
    ensure  => installed,
  }
  service { 'asterisk':
    ensure  => running,
    require => Package['asterisk'],
    enable  => true,
  }
  file { '/etc/voipplan':
    notify => Exec['update_configuration_files'],
    mode   => '0644',
    owner  => 'asterisk',
    group  => 'asterisk',
    source => 'puppet:///svn/allevents/services/voipplan',
  }
  file { '/etc/asterisk/iax.conf':
    ensure  => file,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0644',
    content => template('asterisk/iax.conf.erb'),
    require => Package['asterisk'],
    notify  => Exec['reload_asterisk'],
  }
  exec { 'allow_obelix_ipv4':
    command => 'iptables -A INPUT -s obelix.tech.dreamhack.se -m comment --comment "allow obelix communication" -j ACCEPT',
    path    => '/usr/bin:/bin/:/sbin:/usr/sbin',
    unless  => 'iptables-save | grep "allow obelix communication" >/dev/null 2>&1',
  }
  exec { 'allow_obelix_ipv6':
    command => 'ip6tables -A INPUT -s obelix.tech.dreamhack.se -m comment --comment "allow obelix communication" -j ACCEPT',
    path    => '/usr/bin:/bin/:/sbin:/usr/sbin',
    unless  => 'ip6tables-save | grep "allow obelix communication" >/dev/null 2>&1',
  }
  exec { 'allow_udp_sip':
    command => 'iptables -A INPUT -s 77.80.128.0/17 -m multiport --dports 5060 -m comment --comment "allow sip udp" -j ACCEPT',
    path    => '/usr/bin:/bin/:/sbin:/usr/sbin',
    unless  => 'iptables-save | grep "allow sip udp" >/dev/null 2>&1',
  }
  exec { 'allow_tcp_sip':
    command => 'iptables -A INPUT -s 77.80.128.0/17 -m multiport --dports 5060 -m comment --comment "allow sip tcp" -j ACCEPT',
    path    => '/usr/bin:/bin/:/sbin:/usr/sbin',
    unless  => 'iptables-save | grep "allow sip tcp" >/dev/null 2>&1',
  }

  file { '/etc/asterisk/manager.conf':
    ensure  => file,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0644',
    content => template('asterisk/manager.conf.erb'),
    require => Package['asterisk'],
    notify  => Exec['reload_asterisk'],
  }
  exec { 'reload_asterisk':
    command     => 'service asterisk reload',
    refreshonly => true,
    path        => '/usr/bin:/bin/:/sbin:/usr/sbin',
  }

  exec { 'update_configuration_files':
    notify      => Exec['reload_asterisk'],
    refreshonly => true,
    command     => 'python run.py /etc/voipplan',
    cwd         => '/scripts/voip-parse',
    path        => '/usr/bin/:/bin/',
  }
}
