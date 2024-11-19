class wireguard($current_event) {
  # Execute 'apt-get update'
  exec { 'apt-update':                    # exec resource named 'apt-update'
    command => '/usr/bin/apt-get update',  # command this resource will run
  }

  # Install wireguard package
  package { 'wireguard':
    ensure  => installed,
    require => Exec['apt-update'],        # require 'apt-update' before installing
  }
}