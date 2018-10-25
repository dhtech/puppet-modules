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

class kubernetes::worker {

  $token = vault['kubernetes:token', {}]
  $master_ip = vault['kubernetes:master_ip', {}]
  $master_port = vault['kubernets:master_port', {}]
  $cert_hash = vault['kubernetes:cert_hash', {}]

  #Remove this file to run the join command again on the next puppet run.
  file { 'cluster-joined':
    ensure   => file,
    path     => '/var/tmp/cluster.joined',
    notify - => Exec['join-cluster'],
  }

  exec { 'join-cluster':
    command     => "/usr/bin/kubectl join --token ${token} ${master_ip}:${master_port} --discovery-token-ca-cert-hash sha256:${cert_hash}",
    refreshonly => true,
  }

}
