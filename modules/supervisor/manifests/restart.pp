# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# Restart a process managed by supervisord
define supervisor::restart() {
  require supervisor

  if $operatingsystem == 'OpenBSD' {
    $supervisorctl = '/usr/local/bin/supervisorctl'
  }
  else {
    $supervisorctl = '/usr/bin/supervisorctl'
  }

  exec { "supervisorctl_restart_${name}":
    command     => "${supervisorctl} restart ${name}",
    refreshonly => true,
  }

}
