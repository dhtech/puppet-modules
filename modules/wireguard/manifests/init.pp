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

  # Create wireguard interface
  exec { 'create':
    require => Package['wireguard'],
    command => '/usr/bin/ip link add dev wg0 type wireguard',
    unless  => '/usr/bin/ip link show wg0'
  }

  file{"/etc/wireguard":
    ensure  =>  directory,
    mode    =>  0600,
    require => File["/etc/wireguard"],
  }

  # Create wireguard privkey
  exec { 'create-privkey':
    command => '/usr/bin/wg pubkey < /etc/wireguard/privkey > /etc/wireguard/pubkey',
    unless  => '/usr/bin/ls /etc/wireguard/privkey',
    require => Exec['create'],
  }
}