# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ircbot
#
# Installs and manages the ircbot 
#
# === Parameters
#
# [*admins*]
#   Defines the admins of the bot, based on nicknames. 
#

class ircbot($ircserver, $admins = []) {

  group{'ircbot':
    ensure => 'present',
  }

  user {'ircbot':
    ensure     => 'present',
    managehome => true,
    gid        => 'ircbot',
    home       => '/opt/ircbot',
  }

  file { '/opt/ircbot':
    ensure => 'directory',
    mode   => '0750',
    owner  => 'ircbot',
    group  => 'ircbot',
  }

  file { '/opt/ircbot/run':
    ensure  => 'directory',
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    path    => '/opt/ircbot/run',
    require => File['/opt/ircbot'],
  }

  file { '/opt/ircbot/dh-syslog-ircbot.conf':
    ensure  => 'file',
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    content => template('ircbot/dh-syslog-ircbot.conf.erb'),
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }

  file { '/opt/ircbot/dh-syslog-ircbot.py':
    ensure  => 'file',
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    source  => 'puppet:///scripts/ircbot_syslog/dh-syslog-ircbot.py',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }

  file { '/opt/ircbot/irclib.py':
    ensure  => 'file',
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    source  => 'puppet:///scripts/ircbot_syslog/irclib.py',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }

  file {'/opt/ircbot/ircbot.py':
    ensure  => 'file',
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    source  => 'puppet:///scripts/ircbot_syslog/ircbot.py',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }

  file {'/opt/ircbot/start.py':
    ensure  => 'file',
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    source  => 'puppet:///scripts/ircbot_syslog/start.py',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }
  supervisor::register { 'ircbot':
    command     => '/opt/ircbot/dh-syslog-ircbot.py',
    directory   => '/opt/ircbot',
    stopasgroup => true,
    require     => [
      File['/opt/ircbot'],
      File['/opt/ircbot/run'],
      File['/opt/ircbot/dh-syslog-ircbot.conf'],
      File['/opt/ircbot/dh-syslog-ircbot.py'],
      File['/opt/ircbot/irclib.py'],
      File['/opt/ircbot/ircbot.py'],
      File['/opt/ircbot/start.py'],
    ],
  }
}
