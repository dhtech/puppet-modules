class wireguard {
  # Execute 'apt-get update'
  exec { 'apt-update':                    # exec resource named 'apt-update'
    command => '/usr/bin/apt-get update'  # command this resource will run
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

  exec { 'create-privkey':
    command => '/usr/bin/wg pubkey < /etc/wireguard/privkey > /etc/wireguard/pubkey',
    unless  => '/usr/bin/ls /etc/wireguard/privkey'
  }

  exec { 'create-pubkey':
    command => '/usr/bin/wg genkey > /etc/wireguard/privkey',
    unless  => '/usr/bin/ls /etc/wireguard/privkey'
  }


  exec { 'add-key':
    command => '/usr/bin/wg set wg0 listen-port 51820 private-key /etc/wireguard/privkey',
    require => Exec['create-key'],        # require 'apt-update' before installing
  }


# Set wireguard interface IP
  exec { 'set wg interface IP':
    require => Package['wireguard'],
    command => '/usr/bin/ip address add dev wg0 77.80.229.133/25',
    unless  => '/usr/bin/ip addr show wg0 | grep 77.80.229.133/25'
  }

  file { '/tmp/wireguard/wireguard-clients.yaml':
    ensure  => directory,
    recurse => remote,
    source  => 'puppet:///svn/$::{current_event}/services/wireguard-clients.yaml',
}


# Build the wg0 config file will all clients from previous step
  file { 'setConf':
    ensure  => file,
    path    => '/etc/wireguard/wg0.conf',
    notify  => Exec[syncConf],
    content => template('wireguard/wg0.conf.erb'),
  }

# Sync changes towards the wg0 interface
  exec { 'syncConf':
    require => Package['wireguard'],
    command => '/usr/bin/wg syncconf wg0 /etc/wireguard/wg0.conf',
  }
}
