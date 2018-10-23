# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: syslog
#
# This package manages our syslog clients.
#
# === Parameters
#
# Document parameters here.
#
# [*syslog_servers*]
#   The syslog servers the clients will send all log messages to.
#

class syslog ($syslog_servers = '') {

  if $operatingsystem == 'OpenBSD' {
    $service = 'syslogd'
    $conf_file = 'syslog.conf'
    $conf_dir = '/etc'
  }
  else {
    $service = 'rsyslog'
    $conf_file = 'dh-rsyslog-client.conf'
    $conf_dir = '/etc/rsyslog.d'
  }

  service { 'syslog':
    name => $service,
    ensure => 'running',
    enable => true,
  }

  file { 'syslog.conf':
    path    => "$conf_dir/$conf_file",
    ensure  => file,
    content => template("syslog/$conf_file.erb"),
    notify  => Service["syslog"],
  }
}
