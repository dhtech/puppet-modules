# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: kubernetes::worker
#
# Used for installing/setting up all dependencies for Kubernetes.
#
# === Parameters
#

class kubernetes::worker($variant, $apiserver, $cert_hash, $token) {

  file { '/etc/kubernetes/kubeadm-config.yaml':
    ensure  => 'file',
    content => template('kubernetes/join.yaml.erb'),
    notify  => Exec['join-cluster'],
    require     => [Package['kubeadm'], Exec['k8s-disable-swap']],
  }

  exec { 'join-cluster':
    command     => '/usr/bin/kubeadm join --config /etc/kubernetes/kubeadm-config.yaml',
    creates     => '/etc/kubernetes/kubelet.conf',
    refreshonly => true,
  }

}
