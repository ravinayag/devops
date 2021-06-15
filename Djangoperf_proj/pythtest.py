####
#  curl  -H "Content-Type: application/json" -X POST -d '{"name":"superman","alias":"He is SMAN"}' http://34.121.31.190:8000/heroes/?

#!/usr/bin/python
# -*- coding: utf-8 -*-

import requests
url = 'http://34.121.31.190:8001/heroes/?'

SN = 'George'
AliasN = 'president'

for i in range(50):
    SN = SN + str(i)
    AliasN = AliasN + str(i)
    print (SN, AliasN)
    payload = {'name': SN, 'alias': AliasN}
    res = requests.post(url, payload)
    SN = 'George'
    AliasN = 'president'
    print(res.text)


########################################################
#!/usr/bin/python
import urllib3
import certifi
http = urllib3.PoolManager(ca_certs=certifi.where())
url = 'http://34.121.31.190:8000/heroes/?'
data = {'name': 'JAMES', 'alias': 'WRITER'}
req = http.request('POST', url, fields={'name': 'John Doe', 'alias': 'gardener'})
print(req.data.decode('utf-8'))