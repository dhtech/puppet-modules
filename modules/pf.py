# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def decode_ports(ports, filter_proto):
    """Given a string like '901-902/tcp,30/udp', return a list of ports."""
    if not ports:
        return []

    results = []
    for protoport in ports.split(','):
        port, proto = protoport.split('/')
        if proto != filter_proto:
            continue
        # Expand ranges
        port_range = port.split('-')
        if len(port_range) == 2:
            results.extend(range(int(port_range[0]), int(port_range[1])+1))
        else:
            results.append(int(port))

    return results


def rule_to_dict(rule, version):
    """Given a lib.FirewallRule object,
       return a dict for the iptables module."""
    name = '%s from %s, flow %s' % (
        rule.service, rule.from_node, rule.flow)

    results = []
    for proto in ['tcp', 'udp']:
        dports = decode_ports(rule.dports, proto)
        sports = decode_ports(rule.sports, proto)

        # We need to have a port match on both sides, otherwise we
        # have the wrong protocol.
        if (rule.dports and not dports) or (rule.sports and not sports):
            continue

        dport_string = '{ '
        dport_string += ', '.join(str(port) for port in dports)
        dport_string += ' }'

        sport_string = '{ '
        sport_string += ', '.join(str(port) for port in sports)
        sport_string += ' }'

        result = {}
        result['name'] = name
        result['proto'] = proto
        src = getattr(rule, 'from_ipv%d' % version)
        if src != '::/0' and src != '0/0':
            result['src'] = src
        else:
            result['src'] = 'any'
        if rule.dports:
            result['dports'] = dport_string
        if rule.sports:
            result['sports'] = sport_string
        results.append(result)
    return results


def generate(host, *args):
    v4_rules = []
    v6_rules = []
    for rule in lib.get_firewall_rules_to(host):
        # We don't care about self-referencing rules
        if rule.from_node == host:
            continue
        if rule.from_ipv4:
            v4_rules.extend(rule_to_dict(rule, version=4))
        if rule.from_ipv6:
            v6_rules.extend(rule_to_dict(rule, version=6))

    info = {}
    info['forward_policy'] = 'accept' if 'router' in args else 'drop'
    info['rules'] = {'v4': v4_rules, 'v6': v6_rules}
    return {'pf': info}

# vim: ts=4: sts=4: sw=4: expandtab
