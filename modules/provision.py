# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, mgmt_fqdn, *args):
    """Arg format is domain:host.

    The OS of the host is used to get the backend type.
    """

    vault_prefix = ''
    if lib.get_domain(host) == 'EVENT':
        vault_prefix = '%s-' % lib.get_current_event()
    vault_mount = '%sservices' % vault_prefix

    deploy_domain = lib.get_domain(host)
    deploy_gw, _ = lib.get_network_gateway(deploy_domain+'@DEPLOY')
    deploy_networks, _ = lib.get_networks_with_name(deploy_domain+'@DEPLOY')
    deploy_network, deploy_prefix = deploy_networks.split('/', 2)
    deploy_conf = {
          'gateway': deploy_gw,
          'network': deploy_network,
          'prefix': deploy_prefix
    }

    info = {'esxi': [], 'c7000': [], 'vault_mount': vault_mount,
            'domain': lib.get_domain(host).lower(),
            'deploy_conf': deploy_conf, 'ocp': False,
            'ocp_domain': 'ocp-'+lib.get_domain(host).lower(),
            'ocp_machines': []}

    if mgmt_fqdn != 'no-rfc1918':
        mgmt_network, _ = lib.get_ipv4_network(mgmt_fqdn)
        _, mgmt_prefix = mgmt_network.split('/', 2)
        mgmt_ip = lib.resolve_nodes_to_ip([mgmt_fqdn])
        info['mgmt_if'] = {
              'ip': mgmt_ip[mgmt_fqdn][0],
              'prefix': mgmt_prefix
        }
    for arg in args:
        if arg == 'ocp':
            info['ocp'] = True
            ocp_macs = [
                {'name': 'r0a0', 'mac': 'E41D2DFC296A',
                    'mgmt-mac': 'E41D2DFC296C'},
                {'name': 'r0a1', 'mac': 'E41D2DFC2826',
                    'mgmt-mac': 'E41D2DFC2828'},
                {'name': 'r0a2', 'mac': 'E41D2DFC5F58',
                    'mgmt-mac': 'E41D2DFC5F60'},
                {'name': 'r0a3', 'mac': 'E41D2DFC4554',
                    'mgmt-mac': 'E41D2DFC4556'},
                {'name': 'r0a4', 'mac': '7CFE904142EE',
                    'mgmt-mac': '7CFE904142F0'},
                {'name': 'r0a5', 'mac': '7CFE9041826C',
                    'mgmt-mac': '7CFE9041826E'},
                {'name': 'r0a6', 'mac': '7CFE90413FE8',
                    'mgmt-mac': '7CFE90413FEA'},
                {'name': 'r0a7', 'mac': 'E41D2DD3C842',
                    'mgmt-mac': 'E41D2DD3C844'},
                {'name': 'r0a8', 'mac': 'E41D2DFC2B08',
                    'mgmt-mac': 'E41D2DFC2B0A'},
                {'name': 'r0a9', 'mac': '7CFE9041327A',
                    'mgmt-mac': '7CFE9041327C'},
                {'name': 'r0b0', 'mac': '7CFE904103EE',
                    'mgmt-mac': '7CFE904103F0'},
                {'name': 'r0b1', 'mac': 'E41D2DFC2B50',
                    'mgmt-mac': 'E41D2DFC2B52'},
                {'name': 'r0b2', 'mac': '7CFE904136A0',
                    'mgmt-mac': '7CFE904136A2'},
                {'name': 'r0b3', 'mac': 'E41D2DFC4164',
                    'mgmt-mac': 'E41D2DFC4164'},
                {'name': 'r0b4', 'mac': '7CFE90423DF2',
                    'mgmt-mac': '7CFE90423DF4'},
                {'name': 'r0b5', 'mac': '7CFE9041FE08',
                    'mgmt-mac': '7CFE9041FE0A'},
                {'name': 'r0b6', 'mac': 'E41D2DFC177C',
                    'mgmt-mac': 'E41D2DFC177E'},
                {'name': 'r0b7', 'mac': 'E41D2DFCC594',
                    'mgmt-mac': 'E41D2DFCC596'},
                {'name': 'r0b8', 'mac': 'E41D2DFC2A30',
                    'mgmt-mac': 'E41D2DFC2A32'},
                {'name': 'r0b9', 'mac': 'E41D2DFCC180',
                    'mgmt-mac': 'E41D2DFCC182'},
                {'name': 'r0c0', 'mac': 'E41D2DFCC648',
                    'mgmt-mac': 'E41D2DFCC64A'},
                {'name': 'r0c1', 'mac': '7CFE90428088',
                    'mgmt-mac': '7CFE9042808A'},
                {'name': 'r0c2', 'mac': '7CFE904182EA',
                    'mgmt-mac': '7CFE904182EC'},
                {'name': 'r0c3', 'mac': 'E41D2DFC890A',
                    'mgmt-mac': 'E41D2DFC890C'},
                {'name': 'r0c4', 'mac': '7CFE90418224',
                    'mgmt-mac': '7CFE90418226'},
                {'name': 'r0c5', 'mac': 'E41D2DFC2838',
                    'mgmt-mac': 'E41D2DFC283A'},
                {'name': 'r0c6', 'mac': '7CFE90428E98',
                    'mgmt-mac': '7CFE90428E9A'},
                {'name': 'r0c7', 'mac': '7CFE90429C60',
                    'mgmt-mac': '7CFE90429C62'},
                {'name': 'r0c8', 'mac': '7CFE90429CF0',
                    'mgmt-mac': '7CFE90429CF2'},
                {'name': 'r0c9', 'mac': '7CFE9041AAC8',
                    'mgmt-mac': '7CFE9041AACA'},
                {'name': 'r1a0', 'mac': '248A07907064',
                    'mgmt-mac': '248A07907066'},
                {'name': 'r1a1', 'mac': '7CFE9042E1B4',
                    'mgmt-mac': '7CFE9042E1B6'},
                {'name': 'r1a2', 'mac': '7CFE9041328C',
                    'mgmt-mac': '7CFE9041328E'},
                {'name': 'r1a3', 'mac': 'E41D2DFC16B6',
                    'mgmt-mac': 'E41D2DFC16B8'},
                {'name': 'r1a4', 'mac': '7CFE90423F24',
                    'mgmt-mac': '7CFE90423F26'},
                {'name': 'r1a5', 'mac': '7CFE9041CE02',
                    'mgmt-mac': '7CFE9041CE04'},
                {'name': 'r1a6', 'mac': '7CFE9041102A',
                    'mgmt-mac': '7CFE9041102C'},
                {'name': 'r1a7', 'mac': '7CFE9042C53A',
                    'mgmt-mac': '7CFE9042C53C'},
                {'name': 'r1a8', 'mac': '7CFE9042C6A2',
                    'mgmt-mac': '7CFE9042C6A4'},
                {'name': 'r1a9', 'mac': '7CFE90428E2C',
                    'mgmt-mac': '7CFE90428E2E'},
                {'name': 'r1b0', 'mac': '248A079070AC',
                    'mgmt-mac': '248A079070AE'},
                {'name': 'r1b1', 'mac': '7CFE90410ED4',
                    'mgmt-mac': '7CFE90410ED6'},
                {'name': 'r1b2', 'mac': 'E41D2DFC2BE0',
                    'mgmt-mac': 'E41D2DFC2BE2'},
                {'name': 'r1b3', 'mac': '7CFE90428F5E',
                    'mgmt-mac': '7CFE90428F60'},
                {'name': 'r1b4', 'mac': 'E41D2DFC8E86',
                    'mgmt-mac': 'E41D2DFC8E88'},
                {'name': 'r1b5', 'mac': 'E41D2DFC5100',
                    'mgmt-mac': 'E41D2DFC5102'},
                {'name': 'r1b6', 'mac': '7CFE9041FEF2',
                    'mgmt-mac': '7CFE9041FEF4'},
                {'name': 'r1b7', 'mac': '7CFE90412B3C',
                    'mgmt-mac': '7CFE90412B3E'},
                {'name': 'r1b8', 'mac': '7CFE9041045A',
                    'mgmt-mac': '7CFE9041045C'},
                {'name': 'r1b9', 'mac': '7CFE9041A516',
                    'mgmt-mac': '7CFE9041A518'},
                {'name': 'r1c0', 'mac': 'E41D2DFC2A8A',
                    'mgmt-mac': 'E41D2DFC2A8C'},
                {'name': 'r1c1', 'mac': '7CFE90410D48',
                    'mgmt-mac': '7CFE90410D4A'},
                {'name': 'r1c2', 'mac': '7CFE90424188',
                    'mgmt-mac': '7CFE9042418A'},
                {'name': 'r1c3', 'mac': 'E41D2DFCCE28',
                    'mgmt-mac': 'E41D2DFCCE2A'},
                {'name': 'r1c4', 'mac': '7CFE90422946',
                    'mgmt-mac': '7CFE90422948'},
                {'name': 'r1c5', 'mac': '7CFE9042E340',
                    'mgmt-mac': '7CFE9042E342'},
                {'name': 'r1c6', 'mac': '7CFE9041354A',
                    'mgmt-mac': '7CFE9041354C'},
                {'name': 'r1c7', 'mac': '7CFE9041AB34',
                    'mgmt-mac': '7CFE9041AB36'},
                {'name': 'r1c8', 'mac': '7CFE9042CB34',
                    'mgmt-mac': '7CFE9042CB36'},
                {'name': 'r1c9', 'mac': 'E41D2DFC2A66',
                    'mgmt-mac': 'E41D2DFC2A68'}
            ]
            # Building dhcp static lease configuration for dhcpd.
            leases = []
            lastoctet = 100

            for line in ocp_macs:
                t = iter(line['mgmt-mac'])
                mgmt_mac = ':'.join(a+b for a, b in zip(t, t))
                d = {}
                d['name'] = line['name']
                d['mac'] = line['mac']
                d['macshort'] = line['mac']
                d['mgmt-mac'] = mgmt_mac
                d['ip'] = '10.32.12.'+str(lastoctet)
                lastoctet += 1
                leases.append(d)

            info['ocp_machines'].extend(leases)

            continue
        domain, host = arg.split(':', 2)
        os = lib.get_os(host)
        ip = lib.resolve_nodes_to_ip([host])
        backend = {
          'ip': ip[host][0],
          'fqdn': host,
          'domain': domain
        }
        if os == 'vcenter' or os == 'esxi':
            info['esxi'].append(backend)
        elif os == 'c7000':
            info['c7000'].append(backend)

    return {'provision': info}

# vim: ts=4: sts=4: sw=4: expandtab
