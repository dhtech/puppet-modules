# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: colo_k8s
#
# Used for installing/setting up all dependencies for Kubernetes on colo.
#
# === Parameters
#

class colo_k8s {

  # Install basic packages
  ensure_packages([
      'apt-transport-https',
      'ca-certificates',
      'curl',
      'software-properties-common',
      'gnupg',
  ])

  # Add source and install docker
  file { 'docker-source-add':
    ensure  => file,
    path    => '/etc/apt/sources.list.d/docker.list',
    content => 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable',
    notify  => Exec['docker-source-key'],
  }
  -> exec { 'docker-source-key':
    command     => '/usr/bin/curl -fsSL https://download.docker.com/linux/ubuntu/gpg | /usr/bin/apt-key add -',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['docker-source-update'],
  }
  exec { 'docker-source-update':
    command     => '/usr/bin/apt-get update',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    require     => Package['apt-transport-https'],
  }
  package { 'docker-ce':
    ensure  => installed,
    require => [File['docker-source-add'], Exec['docker-source-key'], Exec['docker-source-update']],
  }


  # Add source for Kubernetes
  file { 'k8s-source-add':
    ensure  => file,
    path    => '/etc/apt/sources.list.d/kubernetes.list',
    content => 'deb http://apt.kubernetes.io/ kubernetes-xenial main',
    notify  => Exec['k8s-source-update'],
  }
  exec { 'k8s-source-key':
    command     => '/usr/bin/curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | /usr/bin/apt-key add -',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['k8s-source-update'],
  }
  exec { 'k8s-source-update':
    command     => '/usr/bin/apt-get update',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    require     => Package['apt-transport-https'],
  }

  # Install kubernetes modules
  package { 'kubectl':
    ensure  => installed,
    require => [File['k8s-source-add'], Exec['k8s-source-key'], Exec['k8s-source-update']],
  }
  package { 'kubeadm':
    ensure  => installed,
    require => [
      File['docker-source-add'],
      Exec['docker-source-key'],
      Exec['docker-source-update'],
      File['k8s-source-add'],
      Exec['k8s-source-key'],
      Exec['k8s-source-update'],
      Package['docker-ce'],
      Package['kubectl'],
    ],
  }

  file { '/etc/sysctl.d/dh-kubernetes.conf':
    ensure  => 'file',
    content => 'net.bridge.bridge-nf-call-iptables=1',
  }
  ~> exec { 'refresh-sysctl':
    command     => '/sbin/sysctl --system',
    refreshonly => true,
  }

  # configure cgroupfs
  exec { 'add-cgroupfs':
    command =>  '/bin/sed -i "s/--kubeconfig=\/etc\/kubernetes\/kubelet.conf/--kubeconfig=\/etc\/kubernetes\/kubelet.conf
                --cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf',
    unless  =>  '/bin/grep cgroup-driver /etc/systemd/system/kubelet.service.d/10-kubeadm.conf',
    onlyif  =>  '/usr/bin/test -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf',
  }
  ~> exec { 'systemctl-reload':
    command     =>  '/bin/systemctl daemon-reload',
    refreshonly => true,
  }
  ~> exec { 'restart-kubelet':
    command     => '/bin/systemctl restart kubelet',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
  }

}
