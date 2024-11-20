class wireguard($current_event, $tunnelip) {

  if !($current_event =~ String[1]) {
      #Pull down FW rules from SVN
      file { '/etc/iptables/rules.v4':
        ensure  => file,
        recurse => remote,
        source  => "puppet:///svn/${current_event}/services/rules.v4",
      }
    }

  #Apply FW rules 
  exec { 'fw-rules':
    command => '/usr/sbin/iptables-restore /etc/iptables/rules.v4',
    require => File['/etc/iptables/rules.v4'],
  }

  # Execute 'apt-get update'
  exec { 'apt-update':
    command => '/usr/bin/apt-get update',
  }

  # Install wireguard package
  package { 'wireguard':
    ensure  => installed,
    require => Exec['apt-update'],
  }

  #Create wireguard dir
  file{ '/etc/wireguard':
    ensure  =>  directory,
    mode    =>  '0600',
    require => Package['wireguard'],
  }

  # Enable IPv4 Forwardning
  exec { 'enable-forward':
    command => '/usr/sbin/sysctl -w net.ipv4.ip_forward=1',
    unless  => '/usr/sbin/sysctl net.ipv4.ip_forward | grep 0',
    require => File['/etc/wireguard'],
  }

  # Create wireguard privkey
  exec { 'create-privkey':
    command => '/usr/bin/wg genkey > /etc/wireguard/privkey',
    creates => '/etc/wireguard/privkey',
    require => Exec['enable-forward'],
  }

  # Create wireguard pubkey
  exec { 'create-pubkey':
    command => '/usr/bin/wg pubkey < /etc/wireguard/privkey > /etc/wireguard/pubkey',
    creates => '/etc/wireguard/pubkey',
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
  
  if !($tunnelip =~ String[1]) {
    #Set tunnel IP
    exec { 'set-IP':
      require => Exec['link-up'],
      command => "/usr/bin/ip address add dev wg0 ${tunnelip}",
      unless  => "/usr/bin/ip addr show wg0 | grep ${tunnelip}"
    }
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

  #Append config file to tunnel config
  exec { 'syncConf':
    require => File['/etc/wireguard/wg0.conf'],
    command => '/usr/bin/wg addconf wg0 /etc/wireguard/wg0.conf',
  }
}