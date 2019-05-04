# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: asterisktftp
#
# TFTP boot content and application deploy module
#
# === Parameters
#
# [*current_event*]
#   The current event, used to decide the name of the dhcpinfo database
#

class asterisktftp($current_event) {
  package { 'python-jinja2':
    ensure => installed,
  }
  file { '/srv/asterisk_bootfiles':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///svn/allevents/tftpboot',
  }
  file { '/srv/tftp/':
    ensure => directory,
  }
  file { '/etc/asterisk':
    ensure => directory,
  }
  exec { 'merge_tftpboot_tree':
    refreshonly => true,
    command     => 'cp /tmp/hardwareconfigs/* /srv/asterisk_bootfiles/* /srv/tftp/',
    path        => '/usr/bin:/bin',
    require     => [File['/srv/tftp'], File['/srv/asterisk_bootfiles'], File['/etc/asterisk']],
  }
  exec { 'update_configuration_files':
    notify      => Exec['merge_tftpboot_tree'],
    refreshonly => true,
    command     => 'python run.py /etc/voipplan',
    cwd         => '/scripts/voip-parse',
    path        => '/usr/bin/:/bin/',
  }
  file { '/etc/voipplan':
    notify => Exec['update_configuration_files'],
    mode   => '0644',
    owner  => 'tftp',
    group  => 'tftp',
    source => 'puppet:///svn/allevents/services/voipplan',
  }
}
