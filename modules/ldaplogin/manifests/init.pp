# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ldaplogin
#
# Enable system login using LDAP.
#
# === Parameters
#
# [*ca*]
#   SSH CA to trust for user authentication.
#
# [*login*]
#   Groups that are allowed to logon, in the format [group, location]
#
# [*sudo*]
#   Groups that are allowed to use sudo
#
# [*ldap*]
#   LDAP settings:
#     mount: where to mount (usually /ldap)
#     base: base DN for ldap
#     servers: ldap server DNS names
#     servers_ip: {dns: (ipv4, ipv6) tuple for the server DNS name}
#
# [*ssh_ports*]
#   What ports to listen on for ssh connections
#
# [*panic_users*]
#   Users allowed to act as the panic user 'dhtech'
#
# [*use_otp*]
#   Allow the usage of OTPs (default false)
#
# [*gitshell*]
#   Match pattern of users to put in git-shell (default '' = not active)
#
# [*host_cert*]
#   Host certificate if present (default '' = not active)

class ldaplogin ($ca, $logon, $sudo, $ldap, $ssh_ports, $panic_users,
                $use_otp = false, $gitshell = '', $host_cert = '') {

  service { 'sssd':
    ensure  => 'running',
    name    => 'sssd',
    enable  => true,
    require => Package['sssd'],
  }
  
  service { ['sssd-nss.socket', 'sssd-autofs.socket', 'sssd-pac.socket',
             'sssd-pam-priv.socket', 'sssd-ssh.socket', 'sssd-sudo.socket']:
    ensure => 'disable',
    provider => 'systemd',
 }

  service { 'openssh-server':
    ensure => 'running',
    name   => 'ssh',
    enable => true,
  }

  if $use_otp {
    package { 'libpam-google-authenticator':
      ensure => installed,
    }
  }

  # TODO(bluecmd): host only supports one family:
  # https://projects.puppetlabs.com/issues/8940
  each($ldap['servers']) |$srv| {
    host { "ldap-host-v4-${srv}":
      name => $srv,
      ip   => $ldap['servers_ip'][$srv][0],
    }
  }

  ensure_packages([
    'sudo',
    'sssd-tools',
    'libpam-sss',
    'libnss-sss'])

  package { 'nscd':
    ensure => purged,
  }

  file { 'access.conf':
    ensure  => file,
    path    => '/etc/security/access.conf',
    content => template('ldaplogin/access.conf.erb'),
  }

  file { 'sssd.conf':
    ensure  => file,
    path    => '/etc/sssd/sssd.conf',
    content => template('ldaplogin/sssd.conf.erb'),
    notify  => Service['sssd'],
    require => Package['sssd'],
    mode    => '0600',
  }

  file { 'ldap.conf':
    ensure  => file,
    path    => '/etc/ldap/ldap.conf',
    content => template('ldaplogin/ldap.conf.erb'),
  }

  file { 'dreamhack.issue':
    ensure  => file,
    path    => '/etc/dreamhack',
    content => template('ldaplogin/issue.erb'),
  }

  file { 'motd':
    ensure  => file,
    path    => '/etc/motd',
    content => '',
  }

  file { 'motd.tail':
    ensure  => file,
    path    => '/etc/motd.tail',
    content => '',
  }

  file { 'sshd_config':
    ensure  => file,
    path    => '/etc/ssh/sshd_config',
    content => template('ldaplogin/sshd_config.erb'),
    notify  => Service['openssh-server'],
  }

  file { 'ssh_known_hosts':
    ensure  => file,
    path    => '/etc/ssh/ssh_known_hosts',
    content => template('ldaplogin/ssh_known_hosts.erb'),
  }

  file { '/etc/ssh/authorized_keys':
    ensure => 'directory',
    mode   => '0755',
  }

  if $host_cert != '' {
    file { 'ssh_host_ecdsa_key.crt':
      ensure  => 'present',
      path    => '/etc/ssh/ssh_host_ecdsa_key.crt',
      content => $host_cert,
      mode    => '0644',
      notify  => Service['openssh-server'],
    }
  }

  file { 'ssh_ca.pub':
    ensure  => 'present',
    path    => '/etc/ssh/ssh_ca.pub',
    content => $ca,
    mode    => '0644',
  }

  file { 'common-account':
    ensure  => file,
    path    => '/etc/pam.d/common-account',
    content => template('ldaplogin/common-account.erb'),
    require => Package['libpam-sss'],
  }

  file { 'common-session':
    ensure  => file,
    path    => '/etc/pam.d/common-session',
    content => template('ldaplogin/common-session.erb'),
    require => Package['libpam-sss'],
  }

  file { 'common-auth':
    ensure  => file,
    path    => '/etc/pam.d/common-auth',
    content => template('ldaplogin/common-auth.erb'),
    require => Package['libpam-sss'],
  }

  file { 'pam-sshd':
    ensure  => file,
    path    => '/etc/pam.d/sshd',
    content => template('ldaplogin/sshd.erb'),
  }

  file { 'sudoers':
    ensure  => file,
    path    => '/etc/sudoers.d/dreamhack',
    mode    => '0440',
    content => template('ldaplogin/sudoers.erb'),
    require => Package['sudo'],
  }

  file { 'dh-principals':
    ensure => file,
    path   => '/sbin/dh-principals',
    mode   => '0755',
    source => 'puppet:///modules/ldaplogin/dh-principals.sh',
  }

  # Don't replace /etc/panic.users if it exists but $panic_users is empty
  # because that is most likely a mistake: there should always be at least
  # 1 panic user.
  if size($panic_users) > 0 {
    $panic_user_replace = true
  } else {
    $panic_user_replace = false
  }

  file { 'panic-users':
    ensure  => file,
    path    => '/etc/panic.users',
    replace => $panic_user_replace,
    content => template('ldaplogin/panic.users.erb'),
  }

  user { 'dhtech-user':
    name           => 'dhtech',
    forcelocal     => yes,
    home           => '/home/dhtech',
    password       => '*',
    purge_ssh_keys => true,
    shell          => '/bin/bash',
  }
  -> file { '/home/dhtech':
    ensure => 'directory',
    owner  => 'dhtech',
    group  => 'dhtech',
    mode   => '0700',
  }
  -> file { '/home/dhtech/.bash_aliases':
    ensure  => file,
    content => template('ldaplogin/panic.bash_aliases.erb'),
  }

  if $::operatingsystem == 'Debian' and $::operatingsystemmajrelease == '8' {
    # SSSD in Debian 8 is not able to read our sshPublicKeys for some reason
    # so we take it from testing. openssh-server doesn't work with *that*
    # sssd version, so we take that one from testing also.
    exec { '/usr/bin/apt-get -y -t testing install openssh-server sssd libc6-dev > /var/tmp/new-ssh':
      creates => '/var/tmp/new-ssh',
    }
    -> package { 'sssd':
        ensure => installed,
    }
  } elsif $::operatingsystem == 'Debian' and $::operatingsystemmajrelease == '7' {
    ensure_packages([
      'python-fuse',
      'python-yaml',
      'python-ldap'])

    file { 'ldapfuse.py':
      ensure  => file,
      path    => '/usr/bin/ldapfuse.py',
      mode    => '0755',
      source  => 'puppet:///scripts/ldapfuse/ldapfuse.py',
      require => [Package['python-ldap'], Package['python-yaml']],
    }

    file { 'ldap-mount-point':
      ensure => directory,
      path   => $ldap['mount'],
    }

    mount { 'ldapfuse':
      ensure   => mounted,
      name     => $ldap['mount'],
      device   => "ldapfuse.py#ldaps://${ldap['server']}/${ldap['base']}",
      fstype   => 'fuse',
      remounts => false,
      options  => 'noauto,allow_other',
      require  => [File['ldap-mount-point'], File['ldapfuse.py']],
    }

    $escaped_mount = regsubst($ldap['mount'], '\/', '\\/', 'G')
    exec { 'boot-ldap':
      command => "/bin/sed -i 's/^exit 0/mount ${escaped_mount}\\nexit 0/' /etc/rc.local",
      unless  => "/bin/grep -q 'mount ${ldap['mount']}' /etc/rc.local",
    }
  } elsif $::operatingsystem == 'Debian' or $::operatingsystem == 'Ubuntu' {
    package {
      'sssd':
        ensure => installed,
    }
  }
}
