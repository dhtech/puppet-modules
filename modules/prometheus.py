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

    snmp_nodes = {}
    ssh_nodes = {}
    for layer in layers:
        hosts = lib.get_nodes_with_layer(layer, domain)
        snmp_mute = lib.get_nodes_with_layer(layer, domain, 'no-snmp')
        ssh_mute = lib.get_nodes_with_layer(layer, domain, 'no-ssh')
        snmp_nodes[layer] = list(set(hosts) - set(snmp_mute))
        ssh_nodes[layer] = [x+':22' for x in set(hosts) - set(ssh_mute)]

    # SNMP
    for layer in layers:
        # TODO(bluecmd): Use options for this
        if layer == 'access':
            host = 'snmp2.event.dreamhack.se'
        else:
            host = 'snmp1.event.dreamhack.se'
        snmp = blackbox(
                'snmp_%s' % layer, host,
                snmp_nodes[layer], {'layer': [layer]}, labels={
                    'layer': layer})
        snmp['scrape_interval'] = '30s'
        snmp['scrape_timeout'] = '30s'
        scrape_configs.append(snmp)

    # SSH
    for layer in layers:
        for host in ['jumpgate1', 'jumpgate2', 'rancid']:
            fqdn = host + '.event.dreamhack.se:9115'
            ssh = blackbox(
                   'ssh_%s_%s' % (layer, host), fqdn,
                   ssh_nodes[layer], {'module': ['ssh_banner']}, labels={'layer': layer})
            ssh['scrape_interval'] = '30s'
            ssh['scrape_timeout'] = '30s'
            scrape_configs.append(ssh)

    # Add external service-discovery
    external = {
      'job_name': 'external',
      'file_sd_configs': [{
          'files': ['/etc/prometheus/external/*.yaml'],
      }],
    }
    scrape_configs.append(external)

    if host.endswith('event.dreamhack.se'):
        # Event should scrape puppet.tech.dreamhack.se to get information about
        # puppet runs
        puppet = {
          'job_name': 'puppet_runs',
          'metrics_path': '/metrics',
          'scrape_interval': '60s',
          'scrape_timeout': '55s',
          'static_configs': [{
              'targets': ['puppet.tech.dreamhack.se:9100'],
          }],
        }
        scrape_configs.append(puppet)

    vcenter = {
      'job_name': 'vmware_vcenter',
      'metrics_path': '/metrics',
      'scrape_interval': '60s',
      'scrape_timeout': '55s',
      'static_configs': [{
          'targets': ['provision.event.dreamhack.se:9272'],
      }],
    }
    scrape_configs.append(vcenter)

    # Make sure that all metrics have a host label.
    # This rule uses the existing host label if there is one,
    # stripping of the port (which shouldn't be part of the host label anyway)
    # *or* if that label does not exist it uses the instance label
    # (again stripping of the port)
    relabel = {
        'regex': r':?([^:]*):?.*',
        'separator': ':',
        'replacement': '${1}',
        'source_labels': ['host', 'instance'],
        'target_label': 'host',
    }

    mrc = 'metric_relabel_configs'
    for scrape in scrape_configs:
        if mrc in scrape:
            scrape[mrc].append(relabel)
        else:
            scrape[mrc] = [relabel]
    return {'scrape_configs': scrape_configs}


def requires(host, *args):
    return ['apache(ldap)']


def generate(host, *args):
    info = {}
    local_targets = []
    local_targets.append({
        'job_name': 'prometheus',
        'scheme': 'http',
        'static_configs': [{'targets': ['localhost:9090']}]})
    info['prometheus'] = generate_backend(host, local_targets)

    return info

# vim: ts=4: sts=4: sw=4: expandtab
