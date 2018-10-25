# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# Stuff that needs to be installed before everything else

class system::setup {

  if $::operatingsystem == 'Debian' and $::operatingsystemmajrelease == '8' {
    file { 'testing-preference':
      ensure  => file,
      path    => '/etc/apt/preferences.d/testing',
      content => template('system/apt.testing.pref.erb'),
      notify  => Exec['system:apt_update'],
    }
    -> file { 'testing-source':
      ensure  => file,
      path    => '/etc/apt/sources.list.d/testing.list',
      content => template('system/apt.testing.erb'),
      notify  => Exec['system:apt_update'],
    }
    exec { 'system:apt_update':
      command     => '/usr/bin/apt-get update',
      logoutput   => 'on_failure',
      refreshonly => true,
    }

    # Debian 8 requires python-requests-whl to not break pip
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=744145
    ensure_packages(['python-requests-whl'])
  }

  if $::operatingsystem == 'Debian' or $::operatingsystem == 'Ubuntu' {
    service { 'systemd-modules-load':
      provider => systemd,
    }
    file { 'modules':
      ensure  => file,
      path    => '/etc/modules-load.d/dreamhack.conf',
      content => template('system/modules.erb'),
      notify  => Service['systemd-modules-load'],
    }
  }
}
