# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: kubernetes::master
#
# Used for installing/setting up all dependencies for Kubernetes.
#
# === Parameters
#

class kubernetes::master($variant, $etcd = [], $podnet = "", $servicenet = "", $current_event = "") {

  # TODO (gix): use letsencrypt for kubernetes apiserver
  # TODO (rctl): set vault("kube-${variant}:apicert") with machinecert

  file { '/scripts/kubernetes/':
    ensure => directory,
  }

  file { 'kubeadm-cert-script':
    path    => '/scripts/kubernetes/upload-cert.sh',
    ensure  => file,
    content => template('kubernetes/upload-cert.sh.erb'),
    mode    => '0544',
    require => File['/scripts/kubernetes/'],
    notify  => Exec['kubeadm-cert-upload'],
  }

  exec { 'kubeadm-cert-upload':
    command     => "/scripts/kubernetes/upload-cert.sh",
    refreshonly => true,
  }

  file { 'kubeadm-init-config':
    path => '/etc/kubernetes/kubeadm-config.yaml',
    ensure  => file,
    content => template('kubernetes/init.yaml.erb'),
    require => Exec['kubeadm-cert-upload'],
    notify  => Exec['kubeadm-create-cluster'],
  }

  exec { 'kubeadm-create-cluster':
    command     => "/usr/bin/kubeadm init --config /etc/kubernetes/kubeadm-config.yaml",
    creates     => '/etc/kubernetes/admin.conf',
    refreshonly => true,
    require     => Exec['k8s-disable-swap'],
    notify      => Exec['kubeadm-token-create'],
  }

  file { 'kubeadm-token-script':
    path    => '/scripts/kubernetes/create-token.sh',
    ensure  => file,
    content => template('kubernetes/create-token.sh.erb'),
    mode    => '0544',
    require => File['/scripts/kubernetes/'],
  }

  exec { 'kubeadm-token-create':
    command     => "/scripts/kubernetes/create-token.sh",
    refreshonly => true,
    require     => Exec['kubeadm-token-script'],
  }

}
