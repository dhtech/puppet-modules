# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: autoupdate
#
# Automatic system updates.
#
# === Parameters
#
# [*blacklist*]
#   Packages that should not be updates.
#
# [*email*]
#   Send errors to this email.
#

class autoupdate ($blacklist, $email) {

  if $operatingsystem == 'Debian' or $operatingsystem == 'Ubuntu' {
    package { 'apt-listchanges':
      ensure  => installed,
    }
    package { 'unattended-upgrades':
      ensure  => installed,
    }
    file { 'apt-autoupdate':
      path    => '/etc/apt/apt.conf.d/20auto-upgrades',
      ensure  => file,
      content => template('autoupdate/debian-auto-upgrades.erb'),
    }
    file { 'apt-unattended-upgrades':
      path    => '/etc/apt/apt.conf.d/50unattended-upgrades',
      ensure  => file,
      content => template('autoupdate/debian-unattended-upgrades.erb'),
    }
  }
}
