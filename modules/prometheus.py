# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib
import urlparse
import yaml


MANIFEST_PATH = '/etc/manifest'
HTTP_BASIC_AUTH = None


def blackbox(name, backend, targets, params,
             target='target', path='/probe', labels=None):
    labels = {} if labels is None else labels
    # Strip banned OSes
    banned_oses = ['debian']
    filtered_targets = [x for x in targets if lib.get_os(x) not in banned_oses]
    return {
      'job_name': name,
      'metrics_path': path,
      'params': params,
      'static_configs': [{
          'targets': sorted(filtered_targets),
          'labels': labels
      }],
      'relabel_configs': [{
        'source_labels': ['__address__'],
        'regex': '(.*)(:80)?',
        'target_label': '__param_%s' % target,
        'replacement': '${1}',
      }, {
        'source_labels': ['__param_%s' % target],
        'regex': '(.*)',
        'target_label': 'instance',
        'replacement': '${1}',
      }, {
        'source_labels': [],
        'regex': '.*',
        'target_label': '__address__',
        'replacement': backend,
      }]
    }


def generate_backend(host, local_services):
    scrape_configs = []
    scrape_configs.extend(local_services)
    domain = lib.get_domain(host)

    basic_auth = lib.read_secret('services/monitoring:login')

    # Find services that wants to be monitored
    manifest = yaml.load(file(MANIFEST_PATH).read())
    for package, spec in manifest['packages'].iteritems():
        if spec is None or 'monitor' not in spec:
            continue

        urls = (spec['monitor']['url']
                if isinstance(spec['monitor']['url'], dict) else
                {None: spec['monitor']['url']})
        for url_id, url_str in urls.iteritems():
            url = urlparse.urlparse(url_str)
            targets = []
            for target in sorted(
                    lib.get_nodes_with_package(package, domain).keys()):
                    targets.append(target if url.port is None else '%s:%d' % (
                        target, url.port))
            scrape_config = {
              'job_name': package + ('-%s' % url_id if url_id else ''),
              'metrics_path': url.path,
              'scheme': url.scheme,
              'static_configs': [
                  {'targets': sorted(targets)}
              ],
            }
            if 'interval' in spec['monitor']:
                scrape_config['scrape_interval'] = spec['monitor']['interval']
            if 'labels' in spec['monitor']:
                scrape_config['static_configs'][0]['labels'] = spec['monitor']['labels']
            # Only allow authentication over https
            if spec['monitor'].get('auth', False) and url.scheme == 'https':
                scrape_config['basic_auth'] = basic_auth
            scrape_configs.append(scrape_config)

    # Layer specific monitoring
    layers = lib.get_layers(domain)

    nodes = {}
    all_nodes = set()
    for layer in layers:
        hosts = lib.get_nodes_with_layer(layer, domain)
        mute = lib.get_nodes_with_layer(layer, domain, 'no-snmp')
        nodes[layer] = list(set(hosts) - set(mute))
        all_nodes.update(nodes[layer])

    # ICMP everything
    # TODO(bluecmd): if we want to use this, enable this.
    # icmp = blackbox('icmp', '127.0.0.1:1234', '
    #                 'all_nodes, {'modules': ['icmp']})
    # scrape_configs.append(icmp)

    # SNMP
    for layer in layers:
        # TODO(bluecmd): Use options for this
        if layer == 'access':
            host = 'snmp2.event.dreamhack.se'
        else:
            host = 'snmp1.event.dreamhack.se'
        snmp = blackbox(
                'snmp_%s' % layer, host,
                nodes[layer], {'layer': [layer]}, labels={
                    'layer': layer})
        snmp['scrape_interval'] = '30s'
        snmp['scrape_timeout'] = '30s'
        scrape_configs.append(snmp)

    # Add external service-discovery
    external = {
      'job_name': 'external',
      'file_sd_configs': [{
          'files': ['/etc/prometheus/external/*.yaml'],
      }],
    }
    scrape_configs.append(external)

    return {'scrape_configs': scrape_configs}


def requires(host, *args):
    return ['apache(ldap)']


def generate(host, *args):
    info = {}
    local_targets = []
    local_targets.append({
        'job_name': 'prometheus',
        'metrics_path': '/metrics',
        'scheme': 'http',
        'static_configs': [{'targets': ['localhost:9090']}]})
    info['prometheus'] = generate_backend(host, local_targets)

    return info

# vim: ts=4: sts=4: sw=4: expandtab
