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

  file { 'kubeadm-init-config':
    path => '/etc/kubernetes/kubeadm-config.yaml',
    ensure  => file,
    content => template('kubernetes/init.yaml.erb'),
    notify  => Exec['kubeadm-create-cluster'],
  }

  exec { 'kubeadm-create-cluster':
    command     => "/usr/bin/kubeadm init --config /etc/kubernetes/kubeadm-config.yaml",
    refreshonly => true,
    require     => File['kubeadm-init-config'],
    notify      => Exec['kubeadm-token-create'],
  }

  file { 'kubeadm-token-script':
    path    => '/scripts/kubernetes/create-token.sh',
    ensure  => file,
    content => template('kubernetes/create-token.sh.erb'),
    mode    => '0544',
    notify  => Exec['kubeadm-token-create'],
  }

  exec { 'kubeadm-token-create':
    command     => "/scripts/kubernetes/create-token.sh",
    refreshonly => true,
    require     => [
      Exec['kubeadm-create-cluster'],
      File['kubeadm-token-script'],
    ],
  }

}
