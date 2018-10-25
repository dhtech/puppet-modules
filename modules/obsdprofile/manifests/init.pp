# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: obsdprofile
#
# This module manages /etc/profile and make sure a /etc/profile.d is
# looked at inside it.
#
# === Parameters
#

class obsdprofile {

  file { 'profile':
    ensure  => file,
    path    => '/etc/profile',
    content => template('obsdprofile/profile.erb'),
    require => File['profile.d']
  }

  file { 'profile.d':
    ensure => directory,
    path   => '/etc/profile.d',
  }

}
