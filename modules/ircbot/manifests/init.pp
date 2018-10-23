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

class ircbot($admins=[]) {

  group{'ircbot':
     ensure => "present",
  }

  user {'ircbot':
    home        => '/opt/ircbot',
    managehome  => true,
    gid         => 'ircbot',
    ensure      => 'present',
  }

  file { '/opt/ircbot':
    ensure  => 'directory',
    mode    => '0750',
    owner   => 'ircbot',
    group   => 'ircbot',
  }

  file { '/opt/ircbot/run':
    path    => '/opt/ircbot/run',
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    ensure  => 'directory',
    require => File['/opt/ircbot'],
  }

  file { '/opt/ircbot/dh-syslog-ircbot.conf':
    content => template('ircbot/dh-syslog-ircbot.conf.erb'),
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    ensure  => 'file',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }

  file { '/opt/ircbot/dh-syslog-ircbot.py':
    source  => "puppet:///scripts/ircbot_syslog/dh-syslog-ircbot.py",
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    ensure  => 'file',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }

  file { '/opt/ircbot/irclib.py':
    source  => "puppet:///scripts/ircbot_syslog/irclib.py",
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    ensure  => 'file',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }

  file {'/opt/ircbot/ircbot.py':
    source  => "puppet:///scripts/ircbot_syslog/ircbot.py",
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    ensure  => 'file',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }
  
  file {'/opt/ircbot/start.py':
    source  => "puppet:///scripts/ircbot_syslog/start.py",
    owner   => 'ircbot',
    group   => 'ircbot',
    mode    => '0754',
    ensure  => 'file',
    require => File['/opt/ircbot'],
    notify  => Supervisor::Restart['ircbot'],
  }
  supervisor::register { 'ircbot':
    command     => '/opt/ircbot/dh-syslog-ircbot.py',
    directory   => '/opt/ircbot',
    stopasgroup => 'true',
    require => [ File['/opt/ircbot'],
                 File['/opt/ircbot/run'],
                 File['/opt/ircbot/dh-syslog-ircbot.conf'],
                 File['/opt/ircbot/dh-syslog-ircbot.py'],
                 File['/opt/ircbot/irclib.py'],
                 File['/opt/ircbot/ircbot.py'],
                 File['/opt/ircbot/start.py'],
               ],
  }
}
