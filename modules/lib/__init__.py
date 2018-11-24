import collections
import hvac
import socket
import sqlite3
from collections import defaultdict
# HACK: Teach Vault about our trusted CAs
import os
os.environ['REQUESTS_CA_BUNDLE'] = '/etc/ssl/certs/ca-certificates.crt'


DB_FILE = '/etc/ipplan.db'
VAULT_HOST = 'https://vault.tech.dreamhack.se:1443'

FirewallRule = collections.namedtuple('FirewallRule', (
  'from_node', 'from_ipv4', 'from_ipv6', 'to_node', 'to_ipv4', 'to_ipv6',
  'flow', 'service', 'description', 'dports', 'sports'))


class Error(Exception):
    """Base error class for this module."""


class NodeNotFoundError(Error):
    """Internal error. The node given was not found in ipplan."""


class NoDomainError(Error):
    """Internal error. No domain could be found."""


def _connect():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    return conn, c


def get_current_event():
    conn, c = _connect()
    c.execute(
      'SELECT value FROM meta_data WHERE name = "current_event"')
    res = c.fetchone()
    conn.close()
    return res[0]


def get_domain(host):
    conn, c = _connect()
    c.execute(
      'SELECT n.name FROM host h, network n WHERE h.network_id = n.node_id '
      'AND h.name = ?', (host, ))
    res = c.fetchone()
    conn.close()
    if not res:
        raise NodeNotFoundError('Node %s not found' % host)

    network = res[0]

    if '@' not in network:
        raise NoDomainError('Node %s belongs to network %s which has no domain'
                            % (host, network))

    return network.split('@')[0]


def get_environment(host):
    """Return the environment that we are using."""
    conn, c = _connect()
    c.execute(
      'SELECT o.value FROM host h, option o WHERE o.node_id = h.node_id '
      'AND o.name = "env" AND h.name = ?', (host, ))
    res = c.fetchone()
    conn.close()
    return res[0] if res else 'production'


def get_server_environments(host):
    """Return the environments that we are supporting for servers.

    The idea is that a client can talk to a server in either it's own
    environment or the production one.
    """
    environments = set(('production',))
    environments.add(get_environment(host))
    return environments


def get_nodes_with_package(package, domain=None, environments=('production',)):
    """Get nodes with a given package.

    TODO(bluecmd): This doesn't support default packages, nor network packages.

    Args:
      package: which package to find
      domain: domain to limit the nodes
      environments: list of environments that we want to include

    Returns:
      dict of options by node names that has the given package
    """
    conn, c = _connect()

    c.execute(
        'SELECT host.name, network.name, package.option, e.value FROM host, '
        'network, package LEFT OUTER JOIN option e ON e.node_id = host.node_id '
        'AND e.name = "env" WHERE package.node_id = host.node_id '
        'AND network.node_id = host.network_id '
        'AND package.name = ?', (package, ))
    packages = set(c.fetchall())
    conn.close()

    # Filter domain
    if domain:
        packages = [x for x in packages if
                    x[1].startswith(domain.upper() + '@')]

    # Replace missing environment with 'production'
    if environments:
        packages = [tuple(x[:3]) + (x[3] if x[3] else 'production',)
                    for x in packages]
        # Filter environment
        packages = [x for x in packages if x[3] in environments]

    # Assemble node dict
    nodes = collections.defaultdict(list)
    for package in packages:
        host, _, option, _ = package
        nodes[host].append(option)
    return dict(nodes)


def get_servers_for_node(
        package, host, use_domain=True, use_environments=True):
    """Convenience function for get_nodes_with_package."""
    domain = get_domain(host) if use_domain else None
    environments = get_server_environments(host) if use_environments else None
    return sorted(get_nodes_with_package(package, domain, environments).keys())


def get_nodes_with_layer(layer, domain=None, option=None):
    """Get nodes with a given network layer.

    Args:
      layer: which layer to find
      domain: domain to limit the nodes
      option: option name that should be present on node

    Returns:
      list of node names that is in the given network layer
    """
    conn, c = _connect()

    c.execute(
      'SELECT host.name, network.name FROM host, option, network '
      'WHERE host.node_id = option.node_id '
      'AND host.network_id = network.node_id '
      'AND option.name = "layer" '
      'AND option.value = ?', (layer,))
    nodes = set(c.fetchall())
    conn.close()

    # Filter domain
    if domain:
        nodes = [x for x in nodes if x[1].startswith(domain.upper() + '@')]

    # Filter option
    if option:
        nodes_with_option = []

        conn, c = _connect()
        for node in nodes:
            c.execute(
              'SELECT host.name FROM host, option '
              'WHERE host.name = ? '
              'AND host.node_id = option.node_id '
              'AND option.name = ? ', (node[0], option,))
            result = c.fetchone()
            if result:
                nodes_with_option.extend(result)
        conn.close()

        nodes = [x for x in nodes if x[0] in nodes_with_option]

    # Only return node names
    return [x[0] for x in nodes]


def get_networks_with_layer(layer):
    """Get <name>,<ipv4/cidr>,<ipv6/cidr> rows for networks with a given layer.

    Args:
      layer: which layer to find

    Returns:
      list of network names that is in the given network layer
    """
    conn, c = _connect()

    c.execute(
      'SELECT DISTINCT network.name, network.ipv4_txt, network.ipv6_txt '
      'FROM host, option, network '
      'WHERE host.network_id = network.node_id '
      'AND option.node_id = host.node_id '
      'AND option.name = "layer" '
      'AND option.value = ?', (layer,))
    networks = c.fetchall()
    conn.close()

    return networks


def get_layers(domain):
    """Get a list of all active layers in given domain.

    Args:
      domain: Domain filter.

    Returns:
      list of layer names in the given domain.
    """
    conn, c = _connect()

    c.execute(
      'SELECT DISTINCT network.name, option.value '
      'FROM host, option, network '
      'WHERE host.network_id = network.node_id '
      'AND option.node_id = host.node_id '
      'AND option.name = "layer"')
    layers = c.fetchall()
    conn.close()

    # Filter domain
    layers = [x[1] for x in layers if x[0].startswith(domain.upper() + '@')]
    return list(set(layers))


def get_nodes_with_option(option, domain=None, value=None):
    """Get nodes with a given ipplan option.

    Args:
      option: what option name to look for
      domain: domain to limit the nodes
      value: option value that should be set

    Returns:
      list with names of nodes that have the requested option
    """
    conn, c = _connect()

    c.execute(
      'SELECT host.name, network.name FROM host, option, network '
      'WHERE host.node_id = option.node_id '
      'AND host.network_id = network.node_id '
      'AND option.name = ? ', (option,))
    nodes = set(c.fetchall())
    conn.close()

    # Filter domain
    if domain:
        nodes = [x for x in nodes if x[1].startswith(domain.upper() + '@')]

    # Filter option value
    if value:
        nodes_with_value = []

        conn, c = _connect()
        for node in nodes:
            c.execute(
              'SELECT host.name FROM host, option '
              'WHERE host.name = ? '
              'AND host.node_id = option.node_id '
              'AND option.name = ? '
              'AND option.value = ? ', (node[0], option, value,))
            result = c.fetchone()
            if result:
                nodes_with_value.extend(result)
        conn.close()

    nodes = [x for x in nodes if x[0] in nodes_with_value]

    # Only return node names
    return [x[0] for x in nodes]


def get_node_options(node):
    """Get options for a specific node

    Args:
      node: node that you want to fetch options for

    Returns:
      a dict keyed by option name, pointing to a list of values
    """
    conn, c = _connect()

    c.execute(
      'SELECT option.name, option.value FROM host, option '
      'WHERE host.node_id = option.node_id '
      'AND host.name = ? ', (node,))
    options = c.fetchall()
    conn.close()

    option_dict = defaultdict(list)

    for name, value in options:
        option_dict[name].append(value)

    return option_dict


def get_networks_with_flag(flag, domain=None, value=None):
    conn, c = _connect()

    c.execute(
      'SELECT network.name, ipv4_txt, ipv4_netmask_txt, ipv4_gateway_txt, '
      'ipv6_txt, ipv6_netmask_txt, ipv6_gateway_txt, '
      'option.value FROM network, option WHERE '
      'option.node_id = network.node_id AND option.name = ?', (flag, ))
    raw_data = set(c.fetchall())
    conn.close()

    # Filter domain
    if domain:
        raw_data = [x for x in raw_data
                    if x[0].startswith(domain.upper() + '@')]

    # Filter value
    if value is not None:
        raw_data = [x for x in raw_data if x[7] == value]

    # Structure data as:
    # (domain, network): ((v4_net, v4_mask, v4_gw), (v6_net, v6_mask, v6_gw))
    networks = {tuple(x[0].split('@')): (tuple(x[1:4]), tuple(x[4:7]))
                for x in raw_data}
    return networks


def resolve_nodes_to_ip(nodes, resolve_nat=False):
    """Translate node names to (IPv4, IPv6).

    Set resolve_nat to True to use the network's NAT address if there is one.
    """
    conn, c = _connect()

    result = {}
    for node in nodes:
        c.execute(
          'SELECT host.ipv4_addr_txt, host.ipv6_addr_txt, option.value FROM '
          'host, network LEFT OUTER JOIN option ON '
          'option.node_id = network.node_id AND option.name = "nat" '
          'WHERE network.node_id = host.network_id '
          'AND host.name = ?', (node, ))
        (v4, v6, nat) = c.fetchone()
        if resolve_nat and nat:
            # v4 only supported for NATed networks
            result[node] = (nat, None)
        else:
            result[node] = (v4, v6)
    conn.close()
    return result


def get_firewall_rules_to(host):
    """Get all firewall rules for a given host."""
    conn, c = _connect()

    c.execute('SELECT * FROM firewall_rule_ip_level WHERE to_node_name = ?',
              (host, ))
    rules = [FirewallRule(*x[2:13]) for x in c.fetchall()]
    conn.close()
    return rules


def get_ipv4_network(host):
    """Return (v4 network, v4 gateway) for a given host."""
    conn, c = _connect()

    c.execute('SELECT network.ipv4_txt, network.ipv4_gateway_txt '
              'FROM host, network WHERE network.node_id = host.network_id '
              'AND host.name = ?', (host,))
    res = c.fetchone()
    conn.close()
    return res


def get_ipv6_network(host):
    """Return (v6 network, v6 gateway) for a given host."""
    conn, c = _connect()

    c.execute('SELECT network.ipv6_txt, network.ipv6_gateway_txt '
              'FROM host, network WHERE network.node_id = host.network_id '
              'AND host.name = ?', (host,))
    res = c.fetchone()
    conn.close()
    return res


def get_os(host):
    """Return OS for a given host."""
    conn, c = _connect()

    c.execute(
      'SELECT option.value FROM host, option '
      'WHERE host.node_id = option.node_id '
      'AND option.name = "os" '
      'AND host.name = ?', (host,))

    os_query = c.fetchone()
    os = os_query[0] if os_query else None
    conn.close()
    return os


def get_networks_with_name(name):
    conn, c = _connect()

    c.execute('SELECT ipv4_txt, ipv6_txt FROM '
              'network WHERE name = ?', (name, ))
    networks = c.fetchone()
    conn.close()
    return networks

def match_networks_name(regexp):
    conn, c = _connect()

    c.execute('SELECT ipv4_txt, ipv6_txt FROM '
              'network WHERE name REGEXP ?', (regexp, ))
    networks = c.fetchone()
    conn.close()
    return networks


def get_network_gateway(name):
    """Return (v4 gateway, v6 gateway) for a given network."""
    conn, c = _connect()

    c.execute('SELECT ipv4_gateway_txt, ipv6_gateway_txt '
              'FROM network WHERE name = ?', (name, ))
    res = c.fetchone()
    conn.close()
    return res


def vault():
    fqdn = socket.getfqdn()
    cert = '/var/lib/puppet/ssl/certs/%s.pem' % fqdn
    key = '/var/lib/puppet/ssl/private_keys/%s.pem' % fqdn
    client = hvac.Client(url=VAULT_HOST, cert=(cert, key))
    client.login('/v1/auth/cert/login', json={'name': 'puppet-master'})
    return client


def save_secret(path, **kwargs):
    data = vault().write(path, **kwargs)
    return data.get('data', None) if data else None


def read_secret(path):
    data = vault().read(path)
    return data.get('data', None) if data else None

# vim: ts=4: sts=4: sw=4: expandtab
