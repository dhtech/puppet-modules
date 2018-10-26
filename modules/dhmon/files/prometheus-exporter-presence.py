#!/usr/bin/python2
import sqlite3
import time


conn = sqlite3.connect('/etc/ipplan.db')
c = conn.cursor()

res = c.execute("""
  SELECT host.name, layer.value, os.value FROM host
        LEFT OUTER JOIN option AS layer ON
        host.node_id = layer.node_id AND layer.name = 'layer'
        LEFT OUTER JOIN option AS os    ON
        host.node_id = os.node_id    AND os.name = 'os'
  WHERE layer.value != '' OR os.value != ''
""")

fields = ('host', 'layer', 'os')

# for row in res:
# keys = ['%s="%s"' % x for x in zip(fields, row) if x[1]]
# print 'host_expected{' + ','.join(keys) + '} 1', int(time.time() * 1000)


res = c.execute("""
  SELECT host.name FROM host, option
        WHERE option.node_id = host.node_id AND option.name = 'silence'
""")
for row in res:
    print 'host_silenced{host="%s"} 1' % row, int(time.time() * 1000)

# vim: ts=4: sts=4: sw=4: expandtab
