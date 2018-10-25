#!/usr/bin/env python

"""
Script to fetch node information from PuppetDB and extract information about
the last run report.
"""

import time
import json
import urllib

PUPPETDB_URL = 'http://localhost:8080'

nodes_fh = urllib.urlopen('%s/pdb/query/v4/nodes' % PUPPETDB_URL)

nodes = json.loads(nodes_fh.read())

for node in nodes:
    # Ignore nodes without reports
    if node['report_timestamp']:
        timestamp = int(time.mktime(time.struct_time((
            int(node['report_timestamp'][0:4]),
            int(node['report_timestamp'][5:7]),
            int(node['report_timestamp'][8:10]),
            int(node['report_timestamp'][11:13]),
            int(node['report_timestamp'][14:16]),
            int(node['report_timestamp'][17:19]),
            -1,
            -1,
            -1
        ))))

        print('puppetdb_last_report_timestamp{instance="%s"} %d'
              % (node['certname'], timestamp))
        print('puppetdb_last_report_failed{instance="%s"} %d'
              % (node['certname'],
                  (1 if node['latest_report_status'] == 'failed' else 0)))
        print('puppetdb_last_report_changed{instance="%s"} %d'
              % (node['certname'],
                  (1 if node['latest_report_status'] == 'changed' else 0)))
        print('puppetdb_last_report_unchanged{instance="%s"} %d'
              % (node['certname'],
                  (1 if node['latest_report_status'] == 'unchanged' else 0)))
