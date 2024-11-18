class wireguard {
  # Execute 'apt-get update'
  exec { 'apt-update':                    # exec resource named 'apt-update'
    command => '/usr/bin/apt-get update'  # command this resource will run
  }

  # Install wireguard package
  package { 'wireguard':
    require => Exec['apt-update'],        # require 'apt-update' before installing
    ensure  => installed,
  }

  # Create wireguard interface
  exec { 'create':
    require => Package['wireguard'],
    command => '/usr/bin/ip link add dev wg0 type wireguard',
    unless  => '/usr/bin/ip link show wg0'
  }


# Set wireguard interface IP
  exec { 'set wg interface IP':
    require => Package['wireguard'],
    command => '/usr/bin/ip address add dev wg0 77.80.200.129/25',
    unless  => '/usr/bin/ip addr show wg0 | grep 77.80.200.129/25'
  }

# Specify all clients usable IPs 77.80.200.130 - 77.80.200.254
  $clients = [
    { nick => 'felix', ip => '77.80.200.130', key => '5Dk2crqm8A51OQ1blVK701YMZj33U+GONpmLrr0LWkM=' },
    { nick => 'washington', ip => '77.80.200.131', key => 'Z8aCXv4ydIhUEtvH+NJv39mAMGiS8uF8oNgCoIByAFI=' },
  ]


# Build the wg0 config file will all clients from previous step
  file { 'setConf':
    ensure  => file,
    path    => "/etc/wireguard/wg0.conf",
    notify  => Exec[syncConf],
    content => template('wireguard/templates/wg0.conf.erb'),
  }

# Sync changes towards the wg0 interface
  exec { 'syncConf':
    require => Package['wireguard'],
    command => '/usr/bin/wg syncconf wg0 /etc/wireguard/wg0.conf',
  }
}