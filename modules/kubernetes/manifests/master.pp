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

class kubernetes::master($variant, $etcd = [], $podnet = "", $servicenet = "") {

  # TODO (rctl): set vault["kubernetes_${variant}:token", {}]
  # TODO (rctl): set vault["kubernetes_${variant}:cert_hash", {}]
  # TODO (rctl): Write these files from vault:
  #   /etc/kubernetes/etcd-ca.crt
  #   /etc/kubernetes/etcd.crt
  #   /etc/kubernetes/etcd.key

  file { 'kubeadm-init-config':
    path => '/etc/kubernetes/kubeadm-config.yaml',
    ensure  => file,
    content => template('kubernetes/init.yaml.erb'),
    notify  => Exec['create-cluster'],
  }

  exec { 'create-cluster':
    command     => "/usr/bin/kubectl init --config /etc/kubernetes/kubeadm-config.yaml",
    refreshonly => true,
    require => File['kubeadm-init-config'],
  }

}
