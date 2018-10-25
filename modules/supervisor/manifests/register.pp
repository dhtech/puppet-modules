# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# Let other modules add things supervisord should run
define supervisor::register($command, $user='', $directory='', $autostart='', $stopasgroup='', $environment='') {
  require supervisor

  if $::operatingsystem == 'OpenBSD' {
    $include_dir = '/etc/supervisord.d'
    $supervisorctl = '/usr/local/bin/supervisorctl'
  }
  else {
    $include_dir = '/etc/supervisor/conf.d'
    $supervisorctl = '/usr/bin/supervisorctl'
  }

  exec { "supervisorctl_update_${name}":
    command     => "${supervisorctl} reread && ${supervisorctl} update",
    refreshonly => true,
  }

  file { $name:
    ensure  => file,
    path    => "${include_dir}/${name}.ini",
    content => template('supervisor/include.ini.erb'),
    require => Package['supervisor'],
    notify  => Exec["supervisorctl_update_${name}"],
  }

  # Make it possible for classes to notify supervisor::restart.
  supervisor::restart { $name: }
}
