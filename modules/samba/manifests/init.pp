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

class samba($shares = []) {

  package { 'samba':
    ensure => installed,
  }

  each($shares) |$share| {
    user { $share:
      ensure     => 'present',
      managehome => true,
      shell      => '/sbin/nologin',
    }
  }

  service { 'smbd':
    ensure  => 'running',
    name    => $rc_name,
    enable  => true,
    require => Package['samba'],
  }

  service { 'nmbd':
    ensure  => 'stopped',
    name    => $rc_name,
    enable  => false,
    require => Package['samba'],
  }

}
