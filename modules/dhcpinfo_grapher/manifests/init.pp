# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dhcpinfo_grapher
#
# This package manages the web frontend of dhcp_info
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#

class dhcpinfo_grapher {

  file { '/opt/dhcpinfo/daemons':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
    path   => '/opt/dhcpinfo/daemons',
  }

  file { '/opt/dhcpinfo/daemons/grapherd.rb':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/daemons/grapherd.rb',
    source  => 'puppet:///scripts/dhcpinfo/daemons/grapherd.rb',
    require => [
      File['/opt/dhcpinfo/daemons'],
      Package['ruby-rrd'],
      Package['ruby-file-tail'],
    ],
  }

  package { 'ruby-rrd':
    ensure => 'installed',
  }

  package { 'ruby-file-tail':
    ensure => 'installed',
  }

  supervisor::register { 'dhcpinfo_grapherd':
    command   => 'ruby daemons/grapherd.rb',
    directory => '/opt/dhcpinfo',
    require   => File['/opt/dhcpinfo/daemons/grapherd.rb'],
  }

}
