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

  # TODO (gix): set vault["kube-${variant}:token", {}]
  # TODO (gix): use letsencrypt for kubernetes apiserver
  # TODO (rctl): set vault("kube-${variant}:apicert") with machinecert

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
