# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):

    current_event = lib.get_current_event()
    info = {}
    info['kubernetes::install'] = {}

    if 'colo' in args:
        info['colo_k8s'] = {}
    else:
        variant = args[1]
        if 'worker' in args:
            # find api server that maches the variant
            apiserver = ""
            for h, o in lib.get_nodes_with_package("kubernetes").items():
                if "control" in o and variant in o:
                    apiserver = h
            if apiserver == "":
                raise Exception("k8s apiserver missing in ipplan")      
            secretpath = '{}-services/k8s:token'.format(event)
            secrets = lib.read_secret(secretpath)
            if not secrets:
                raise Exception("Kubeadm token secret missing. Is master deployed?")
            info['kubernetes::worker'] = {
                'variant': variant,
                'apiserver': apiserver,
                'cert_hash': secrets['cert_hash'],
                'token': secrets['token']
            }
        if 'control' in args:
            # find which etcd matches this host
            etcd = []
            e = lib.get_nodes_with_package("etcd")
            for h, o in lib.get_nodes_with_package("etcd").items():
                if variant in o:
                    etcd.append(h)
            if len(etcd) == 0:
                raise Exception("No etcd nodes found")
            servicenet = lib.match_networks_name("EVENT@" + variant.upper() + ".*K8S-SVC")
            podnet = lib.match_networks_name("EVENT@" + variant.upper() + ".*K8S-POD")
            if len(servicenet) == 0 or len(podnet) == 0:
                raise Exception("service- and/or podnet not found in ipplan")      
            info['kubernetes::master'] = {
                'variant': variant,
                'etcd': etcd,
                'podnet': podnet[0],
                'servicenet': servicenet[0],
                'current_event': current_event
            }

    return info

# vim: ts=4: sts=4: sw=4: expandtab
