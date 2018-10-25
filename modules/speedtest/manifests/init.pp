# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: speedtest 
#
# This class manages the speedtest
#
#
# === Parameters
#

class speedtest {

  $nginx_dir = '/etc/nginx'
  $sites_dir = "${nginx_dir}/sites-enabled"
  $rc_name = 'nginx'
  $www_root = '/var/www/html'

  package { 'nginx':
    ensure => installed,
  }

  # Clone speedtest from git
  exec { 'clone git repo':
    command => "/usr/bin/git clone https://github.com/dreamhackcrew/speedtest ${www_root}/speedtest",
    creates => "${www_root}/speedtest",
    timeout => 600,
  }
  file { 'create_sparse_files':
    ensure => 'file',
    source => 'puppet:///scripts/speedtest/create_sparse_files.sh',
    path   => '/usr/local/bin/create_sparse_files.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0744', # Use 0700 if it is sensitive
  }
  exec { 'create_sparse_files':
    command => '/usr/local/bin/create_sparse_files.sh',
    creates => "${www_root}/speedtest/100M",
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure  =>absent,
    force   =>true,
    notify  =>Service['nginx'],
    require =>Package['nginx'],
  }

  file { 'speedtest-conf':
    ensure  => file,
    path    => "${sites_dir}/speedtest",
    content => template('speedtest/speedtest.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  service { 'nginx':
    ensure  => 'running',
    name    => $rc_name,
    enable  => true,
    require => Package['nginx'],
  }

}
