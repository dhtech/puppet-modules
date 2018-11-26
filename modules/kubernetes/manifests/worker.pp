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

class kubernetes::worker($variant, $apiserver) {

  $token = vault["kubernetes_${variant}:token", {}]
  $hash = vault["kubernetes_${variant}:cert_hash", {}]

  file { '/etc/kubernetes/kubeadm-config.yaml':
    ensure  => 'file',
    content => template('kubernetes/join.yaml.erb'),
    notify  => Exec['join-cluster'],
  }

  exec { 'join-cluster':
    command     => "/usr/bin/kubectl join --config /etc/kubernetes/kubeadm-config.yaml",
    refreshonly => true,
  }

}
