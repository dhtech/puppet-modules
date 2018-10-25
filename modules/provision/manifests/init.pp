# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: provision
#
# Install the provision daemon for the deployment system.
#
# === Parameters
#
# Document parameters here.
#
# [*vault_mount*]
#   Vault mount to write secrets to.
#
# [*esxi*]
#   ESXi servers we're handling. Default: []
#   Each element should contain: ip, fqdn, domain
#
# [*c7000*]
#   C7000 AMMCs we're handling. Default: []
#   Each element should contain: ip, fqdn, domain
#
# [*domain*]
#   Provisioning domain in use for ESXi and C7000. Default: ""
#
# [*mgmt_if*]
#   Used to set ip and prefix for the mgmt interface. Default: []
#   Object should contain: ip, prefix
#
# [*deploy_conf*]
#   Used to get what network conf to use for the internal deploy network
#   Object should contain: network, prefix
#
# [*ocp*]
#   Boolean if this node handles OCP gear. Default: false
#
# [*ocp_domain*]
#   Provisioning domain in use for OCP. Default: ""
#
# [*ocp_machines*]
#   List of {'name', 'macshort', 'mgmt-mac', 'ip'}. Default: []

class provision ($vault_mount, $esxi = [], $c7000 = [], $domain = '', $mgmt_if = {},
                $deploy_conf = {}, $ocp = false, $ocp_domain = '', $ocp_machines = []) {
  ensure_packages([
    'apg',
    'python-netsnmp',
    'python-redis',
    'python-libxml2',
    'python-yaml',
    'stunnel4',
    'lzma-dev',
    'liblzma-dev'
  ])

  $redis_secret =  vault('provision-redis')
  $esxi_secret =  vault("login:esxi-${domain}")
  $c7000_secret =  vault('login:c7000')
  $vc_secret = vault('vc.event.dreamhack.se')
  $deploy_gateway = $deploy_conf['gateway']
  $deploy_network = $deploy_conf['network']
  $deploy_prefix = $deploy_conf['prefix']

  package { 'pysphere':
    provider => 'pip',
  }
  -> package { 'pyghmi':
    provider => 'pip',
  }
  -> exec { 'install-hvac':
    creates => '/usr/local/lib/python2.7/dist-packages/hvac',
    command => '/usr/bin/pip install hvac';
  }
  -> file { 'stunnel.conf':
    ensure => file,
    path   => '/etc/stunnel/provision.conf',
    source => 'puppet:///scripts/deploy/stunnel/provision.conf',
    notify => Service['stunnel4'],
  }
  file { 'stunnel-defaults':
    ensure  => file,
    path    => '/etc/default/stunnel4',
    content => template('provision/stunnel.erb'),
    notify  => Service['stunnel4'],
  }
  -> service { 'stunnel4':
    ensure => running,
  }
  -> file { 'bin:provisiond':
    ensure => file,
    path   => '/usr/local/bin/provisiond',
    mode   => '0755',
    source => 'puppet:///scripts/deploy-github/provisiond/provisiond',
    notify => Supervisor::Restart['provisiond'],
  }
  file { 'lib:provisiond':
    path    => '/usr/local/lib/python2.7/dist-packages/provision',
    source  => 'puppet:///scripts/deploy-github/provisiond/provision',
    recurse => true,
    notify  => Supervisor::Restart['provisiond'],
  }
  -> file { 'provision-etc':
    ensure => directory,
    path   => '/etc/provision/',
  }
  -> file { 'provision.yaml':
    ensure  => file,
    path    => '/etc/provision/config.yaml',
    content => template('provision/provision.yaml.erb'),
    notify  => Supervisor::Restart['provisiond'],
  }
  -> file { 'data:vsphere_esxi.iso':
    ensure => file,
    path   => '/srv/vmware-esxi.iso',
    source => 'puppet:///data/VMware-VMvisor-Installer-6.5.0.update02-8294253.x86_64.iso',
  }
  file { 'data:vsphere_vcsa.iso':
    ensure => file,
    path   => '/srv/vmware-vcenter.iso',
    source => 'puppet:///data/VMware-VCSA-all-6.5.0-8307201.iso',
  }
  -> supervisor::register { 'provisiond':
    command     => '/usr/local/bin/provisiond',
    environment =>
      "VAULT_MOUNT=\"${vault_mount}\"," +
      "VAULT_CERT=\"/var/lib/puppet/ssl/certs/${::fqdn}.pem\"," +
      "VAULT_KEY=\"/var/lib/puppet/ssl/private_keys/${::fqdn}.pem\","
      "VMWARE_VCENTER_ISO=\"/srv/vmware-vcenter.iso\"," +
      "VMWARE_ESXI_ISO=\"/srv/vmware-esxi.iso\"",
  }

  # The idea here is that if you don't have to need for a specific interface
  # don't create the interface. If there is no interface, Puppet will not
  # provision it.

  # Optional RFC 1918/ILO/MGMT interface
  if ('ens224' in $::networking['interfaces'] and 'ip' in $mgmt_if) {
    $mgmt_ip = $mgmt_if['ip']
    $mgmt_prefix = $mgmt_if['prefix']
    file { '/etc/network/interfaces.d/provision-ens224':
      ensure  => file,
      content => template('provision/interface-ens224.erb'),
      notify  => Exec['restart-ens224'],
    }
    -> exec { 'restart-ens224':
      command     => '/sbin/ifdown ens224; /sbin/ifup ens224',
      refreshonly => true,
    }
  }

  # Optional DHCP interface
  if ('ens256' in $::networking['interfaces']) {
    file { '/etc/network/interfaces.d/provision-ens256':
      ensure  => file,
      content => template('provision/interface-ens256.erb'),
      notify  => Exec['restart-ens256'],
    }
    -> exec { 'restart-ens256':
      command     => '/sbin/ifdown ens256; /sbin/ifup ens256',
      refreshonly => true,
    }

    ensure_packages(['isc-dhcp-server', 'radvd'])

    # DHCP config
    file { '/etc/sysctl.d/provision.conf':
      ensure  => file,
      content => template('provision/provision.conf.erb'),
    }
    file { '/etc/default/isc-dhcp-server':
      ensure  => file,
      content => template('provision/isc-dhcp-server.erb')
    }

    file { '/etc/radvd.conf':
      ensure  => file,
      content => template('provision/radvd.conf.erb'),
      notify  => Service['radvd'],
    }
    service { 'radvd':
      ensure => running,
    }
    file { '/etc/dhcp/dhcpd.conf':
      ensure  => file,
      content => template('provision/dhcpd.conf.erb'),
      notify  => Service['isc-dhcp-server'],
    }
    service { 'isc-dhcp-server':
      ensure  => running,
    }

    file { '/etc/sysctl.d/dh-provision.conf':
      ensure  => 'file',
      content => 'net.ipv4.ip_forward=1',
    }
    ~> exec { 'refresh-sysctl-provision':
      command     => '/sbin/sysctl --system',
      refreshonly => true,
    }
  } else {
    # If the interface is removed (DHCP functionallity is not needed)
    # clean up and do not run the DHCP server anymore.
    package { 'isc-dhcp-server':
      ensure  => purged,
    }
  }
}
