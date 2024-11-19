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

  file{ '/etc/wireguard':
    ensure  =>  directory,
    mode    =>  '0600',
    require => Package['wireguard'],
  }

  # Create wireguard privkey
  exec { 'create-privkey':
    command => '/usr/bin/wg genkey > /etc/wireguard/privkey',
    unless  => '/usr/bin/ls /etc/wireguard/privkey',
    require => File['/etc/wireguard'],
  }

  # Create wireguard pubkey
  exec { 'create-pubkey':
    command => '/usr/bin/wg pubkey < /etc/wireguard/privkey > /etc/wireguard/pubkey',
    unless  => '/usr/bin/ls /etc/wireguard/pubkey',
    require => Exec['create-privkey'],
  }

  # Create wireguard interface
  exec { 'create-interface':
    require => Exec['create-pubkey'],
    command => '/usr/bin/ip link add dev wg0 type wireguard',
    unless  => '/usr/bin/ip link show wg0'
  }

  #Pull the tunnel up
  exec { 'link-up':
    require => Exec['create-interface'],
    command => '/usr/bin/ip link set up dev wg0',
    unless  => '/usr/bin/ip link show wg0 | grep UP'
  }

  #Set tunnel IP
  exec { 'set-IP':
    require => Exec['link-up'],
    command => '/usr/bin/ip address add dev wg0 77.80.229.133/25',
    unless  => '/usr/bin/ip addr show wg0 | grep 77.80.229.133/25'
  }

  #Set port and privkey
  exec { 'add-key':
    command => '/usr/bin/wg set wg0 listen-port 51820 private-key /etc/wireguard/privkey',
    require => Exec['set-IP'],
    unless  => '/usr/bin/wg | grep 51820'
  }

  #Pull down clients
  file { '/etc/wireguard/wg0.conf':
    ensure  => file,
    require => Exec['set-IP'],
    recurse => remote,
    source  => "puppet:///svn/${current_event}/services/wireguard-clients.txt",
  }

  #Sync config file to tunnel config
  exec { 'syncConf':
    require => File['/etc/wireguard/wg0.conf'],
    command => '/usr/bin/wg addconf wg0 /etc/wireguard/wg0.conf',
  }
}

