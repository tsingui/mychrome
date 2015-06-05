#!/usr/bin/env python3
# -*- coding: cp936 -*-

import random, os, sys, time
import configparser, re
import encodings.idna
from concurrent.futures import ThreadPoolExecutor
import threading
from ipaddress import IPv4Network
from dnslib.dns import DNSRecord, DNSQuestion, QTYPE
import socket, ssl
import socks # https://pypi.python.org/pypi/PySocks/ or https://github.com/Anorov/PySocks
import urllib.request
import winreg, win32api
import win32api

max_ip_num = 5
max_threads = 10

domains = [
    'google.com', 'google.com.hk', 'google.lt', 'google.es', 'google.co.zm',
    'google.bs', 'google.sn', 'google.hu', 'google.com.kw',
    'google.com.tr', 'google.com.om', 'google.rs', 'google.sh',
    'google.co.ma', 'google.co.ve', 'google.be', 'google.co.zw',
    'google.com.mx', 'google.ag', 'google.bj', 'google.ca',
    'google.co.je', 'google.co.jp', 'google.co.uk', 'google.com.tw',
    'google.hn', 'google.ne.jp', 'google.jp', 'google.nl', 'gstatic.com',
    'google.com.mt', 'google.rw', 'google.com.br', 'google.com.et', 'google.mv'
]

dns_servers = '''\
8.8.8.8
8.8.4.4
208.67.222.222
208.67.220.220
212.200.81.1
101.255.16.226
212.181.124.8
190.128.242.206
213.154.81.99
109.236.123.130
82.209.18.102
37.75.163.227
201.227.172.226
219.86.166.31
187.115.128.64
120.146.195.117
177.38.203.54
200.88.127.22
89.18.199.70
87.249.4.10
114.130.11.66
108.47.214.11
94.255.122.42
212.181.116.234
80.71.54.18
78.29.14.127
68.198.35.79
193.238.223.91
187.115.128.64
212.75.211.2
195.177.122.222
91.122.208.159
200.88.127.22
83.142.9.30
95.66.182.191
82.114.92.226
62.38.107.152
82.209.18.102
188.235.4.55
212.200.81.1
178.168.19.55
201.227.172.226
24.42.48.51
89.18.199.70
202.29.94.172
177.38.203.54
82.153.92.178
200.49.160.35
94.255.122.42
216.143.135.11
63.238.52.1
190.128.242.206
211.224.66.119
85.204.57.156
37.75.163.227
221.163.86.113
210.210.219.62
212.25.44.52
220.87.177.141
96.231.165.226
121.163.48.231
82.102.93.139
94.230.183.229
222.99.144.128
185.6.126.66
41.77.130.138
103.29.30.187
108.47.214.11
77.252.83.83
199.103.16.5
118.35.78.70
61.93.207.178
121.176.120.78
123.100.73.185
121.158.228.158
190.26.104.209
91.222.216.98
93.177.147.240
37.98.241.171
37.77.130.250
209.191.129.1
173.237.124.156
115.125.115.199
85.125.59.26
109.236.123.130
210.113.60.121
92.39.60.203
101.255.16.226
74.98.197.3
80.71.54.18
66.163.0.173
213.154.81.99
203.126.117.82
193.180.20.142
219.86.166.31
219.92.247.161
197.92.10.9
120.146.195.117
210.110.3.90
194.32.87.98
190.152.89.229
122.154.151.59
216.185.192.1
176.97.40.78
135.0.79.214
112.168.221.215
84.245.216.180
188.129.7.129
173.193.245.53
113.61.145.10
91.140.198.213
112.145.91.223
222.122.156.117
195.78.239.35
122.34.125.15
195.93.203.221
61.253.150.42
110.173.233.215
200.25.221.29
212.73.69.6
92.105.208.118
213.165.176.156
61.220.40.118
204.13.112.79
208.110.140.33
46.14.254.27
177.104.250.129
84.253.19.21
84.245.192.146
161.53.203.203
188.168.157.108
106.247.238.10
181.143.153.30\
'''
dns_servers = set(dns_servers.split())

inactive_servers = set()
default_servers = set()
ini_file = ''
config = configparser.ConfigParser()
#config.optionxform = str # 区分大小写
# {ip1:time1, ip2:time2, ...}
google_com = {}
# [host with wild card, host, [time,ip], [time,ip],...],
# ex: ['*.google.com.*', 'google.com', [0.1, '216.58.216.3']]
host_map = []
tested_ips = set()
good_ips = set()
ip_is_enough = False
start_time= time.time()
interactive = False
check_inifile = False
lock = threading.RLock()

proxy = None # None - SYSTEM PROXY, [PROTOCOL, SERVER, PORT]
orig_socket = socket.socket
ssl._create_default_https_context = ssl._create_unverified_context # ignore ssl certificate error

def groupip(ip):  ## ip = [time, ip, [domains]]
    global check_inifile, ini_file, config, host_map, google_com, max_ip_num
    configchanged = False
    if len(google_com) < max_ip_num and ip[1] not in google_com.keys():
        if 'www.google.com' in ip[2] or 'google.com' in ip[2] or '*.google.com' in ip[2]:
            google_com[ip[1]] = ip[0]
            if len(google_com) == 1 and check_inifile:
                config.set('IPLookup', 'google_com', ip[1])
                configchanged = True
    if check_inifile and len(host_map):
        for i in host_map:
            if (len(i)-2) >= 3: continue
            for dname in ip[2]:
                if i[0] in dname or i[1] in dname:
                    if len(i) < 3:
                        i.append(ip[0:2])
                        config.set('HostMap', i[0], ip[1])
                        configchanged = True
                    elif ip[1] not in [j[1] for j in i[2:]]:
                        i.append(ip[0:2])
                    break
    if check_inifile and configchanged:
        with open(ini_file, 'w') as f:
            config.write(f)

def nslookup(domain, nservers=['8.8.8.8', '114.114.114']):
    global tested_ips, ip_is_enough, inactive_servers

    if ip_is_enough: return
    try:
        q = DNSRecord(q=DNSQuestion(domain, getattr(QTYPE,'A')))
        a_pkt = q.send(nservers[0], 53, tcp=False, timeout=2)
        a = DNSRecord.parse(a_pkt)
        if a.header.tc:
            # Truncated - retry in TCP mode
            a_pkt = q.send(nservers[0], 53, tcp=True, timeout=2)
            a = DNSRecord.parse(a_pkt)
        a = a.short()
        if not a:
            raise Exception('no response.')
    except Exception as e:
        with lock:
            if nservers[0] not in inactive_servers:
                inactive_servers.add(nservers[0])
                #print(inactive_servers)
            if interactive:
                print('dns error: ', domain, nservers[0], e)
        return
    a = a.split('\n')

    if nservers[0] in inactive_servers:
        inactive_servers.remove(nservers[0])
    for ip in a:
        if ip[-1] != '.':  ##  maybe CNAME
            with lock:
                if ip_is_enough:
                    break
                if ip in tested_ips:
                    continue
                tested_ips.add(ip)
            checkip(ip, domain)


def get_dnsserver_list():
    '''
    based on goagent

    '''
    import os
    if os.name == 'nt':
        import ctypes, ctypes.wintypes, struct, socket
        DNS_CONFIG_DNS_SERVER_LIST = 6
        buf = ctypes.create_string_buffer(2048)
        ctypes.windll.dnsapi.DnsQueryConfig(DNS_CONFIG_DNS_SERVER_LIST,
            0, None, None, ctypes.byref(buf), ctypes.byref(ctypes.wintypes.DWORD(len(buf))))
        ipcount = struct.unpack('I', buf[0:4])[0]
        iplist = [socket.inet_ntoa(buf[i:i+4]) for i in range(4, ipcount*4+4, 4)]
        return iplist
    elif os.path.isfile('/etc/resolv.conf'):
        with open('/etc/resolv.conf', 'rb') as fp:
            return re.findall(r'(?m)^nameserver\s+(\S+)', fp.read())
    else:
        print("get_dnsserver_list failed: unsupport platform '%s'", os.name)
        return []

def checkip(ip, domain):
    global ip_is_enough, tested_ips, good_ips, interactive, start_time
    with lock:
        if ip_is_enough:
            return False
        if ip not in tested_ips:
            tested_ips.add(ip)

    tempsocks = socket.socket
    socket.socket = orig_socket
    for chance in range(2):
        result = []
        dnames = []
        port = 80
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            if chance == 1:
                context = ssl.SSLContext(ssl.PROTOCOL_TLSv1)
                context.verify_mode = ssl.CERT_REQUIRED
                context.load_default_certs()
                sock = context.wrap_socket(sock)
                port = 443
            sock.settimeout(3)
            sock.connect((ip, port))
            st = time.time()
            sock.send(bytes("GET / HTTP/1.1\r\n\r\n", "utf-8"))
            data = sock.recv(128)
            en = time.time()
            data = data.decode('utf-8', 'ignore')
            code = data.split(maxsplit=2)
            if len(code) < 2 or int(code[1]) >= 400:
                break
            result = [round(en-st, 3), ip]
            if chance == 1:
                cert = sock.getpeercert()
                for i in cert['subject']:
                    if 'commonName' in i[0]:
                        dnames.append(i[0][1])
                for i in cert['subjectAltName']:
                    dnames.append(i[1])
        except:
            break
        finally:
            if sock: sock.close()
    if len(dnames):  ## check host
        result.append(dnames)
    socket.socket = tempsocks

    isgoodip = False
    with lock:
        if not ip_is_enough:
            if len(result) >= 3:  ## [response time, ip, [commonName + subjectAltName]]
                if domain in result[2]:
                    isgoodip = True
                good_ips.add(result[1])
                if interactive:
                    print(ip, domain, '## good ip, tested %d good %d elapsed %.1fs'
                        % (len(tested_ips), len(good_ips), time.time()-start_time))
                else:
                    groupip(result)
            elif interactive:
                print(ip, domain, '## bad ip, tested %d good %d elapsed %.1fs'
                      % (len(tested_ips), len(good_ips), time.time()-start_time))
    return isgoodip

##  check if any threads is alive
def thread_alive(tasks):
    for task in tasks:
        if not task.done():
            return True
    return False

def checkini(threads_num):
    global ini_file, config, dns_servers, default_servers, inactive_servers, tested_ips, good_ips
    global host_map, ip_is_enough, max_ip_num, google_com, max_threads, st

    start_time= time.time()

    config.read(ini_file)
    if not config.has_section('IPLookup'):
        config['IPLookup'] = {'google_com':'', 'InactiveServers':'', 'MapHost':1}
        with open(ini_file, 'w') as f:
            config.write(f)

    s = config.get('IPLookup', 'InactiveServers') if config.has_option('IPLookup', 'InactiveServers') else ''
    if s:
        inactive_servers_0 = set(s.split('|'))
        inactive_servers = set(s.split('|'))
    else:
        inactive_servers_0 = set()
        inactive_servers = set()
    servers = dns_servers - inactive_servers
    if len(servers) < 20:
        servers = set(random.sample(dns_servers, 40))
    servers = servers|default_servers

    map_host = config.getint('IPLookup', 'MapHost') if config.has_option('IPLookup', 'MapHost') else 0
    if map_host:
        try:
            for k, v in config.items('HostMap'):
                if re.match('^[\d\.\|]+$', v) or not v:
                    d = re.sub('^[\.*]+|[\.*]+$', '', k)  ##  remove leading trailing . and * if any
                    host_map.append([k, d])
        except:
            pass

    print('check google ips from inifile...')
    with ThreadPoolExecutor(max_workers=threads_num) as executor:
        v = config.get('IPLookup', 'google_com') if config.has_option('IPLookup', 'google_com') else ''
        if v:
            for ip in v.split('|'):
                if ip not in tested_ips:
                    executor.submit(checkip, ip, 'google.com')
        for hostpair in host_map:
            v = config.get('HostMap', hostpair[0])
            if v:
                for ip in v.split('|'):
                    if ip not in tested_ips:
                        executor.submit(checkip, ip, hostpair[1])

    templist = sorted(google_com.items(), key=lambda d:d[1])
    config.read(ini_file)
    config.set('IPLookup', 'google_com', '|'.join(i[0] for i in templist))
    if len(host_map):
        for hostpair in host_map:
            if len(hostpair) < 3:
                config.set('HostMap', hostpair[0], '')
            else:
                config.set('HostMap', hostpair[0], '|'.join(i[1] for i in sorted(hostpair[2:])))
    with open(ini_file, 'w') as f:
        config.write(f)

    if len(google_com) >= max_ip_num:
        ip_is_enough = True
    else:
        print('nslookup google.com via different servers...')
        for chance in range(2):
            sdomains = random.sample(domains, 4)  ## pick part domains randomly
            q = set()
            with ThreadPoolExecutor(max_workers=threads_num) as executor:
                for domain in sdomains:
                    for nameserver in servers:
                        q.add(executor.submit(nslookup, domain, [nameserver]))

                while thread_alive(q):
                    time.sleep(0.1)
                    if len(google_com) >= max_ip_num:
                        ip_is_enough = True
                        print('google ip is enough! wait until all threads complete...')
                        executor.shutdown()
                        break
            if ip_is_enough: break
            servers = set(random.sample(dns_servers, 40))  ##  another try with other servers
        if inactive_servers != inactive_servers_0:
            print(inactive_servers)
            config.set('IPLookup', 'InactiveServers', '|'.join(i for i in inactive_servers))
            with open(ini_file, 'w') as f:
                config.write(f)

    if not ip_is_enough:
        print('extra search in some ranges...')
        iprange = []
        if len(good_ips):
            for i in good_ips:
                r = ".".join(i.split('.')[0:3])+'.0/24'
                if r not in iprange:
                    iprange.append(r)
        else:
             for i in tested_ips:
                r = ".".join(i.split('.')[0:3])+'.0/24'
                if r not in iprange:
                    iprange.append(r)
                    if len(iprange) >= 3:
                        break
        q = set()
        with ThreadPoolExecutor(max_workers=threads_num) as executor:
            for l in iprange:
                for ip in IPv4Network(l).hosts():
                    ip = str(ip)
                    if ip not in tested_ips:
                        q.add(executor.submit(checkip, ip, 'google.com'))
            while thread_alive(q):
                time.sleep(0.1)
                if len(google_com) >= max_ip_num:
                    ip_is_enough = True
                    print('google ip is enough! wait until all threads complete...')
                    executor.shutdown()
                    break

    print('save config...')
    templist = sorted(google_com.items(), key=lambda d:d[1])
    config.read(ini_file)
    config.set('IPLookup', 'google_com', '|'.join(i[0] for i in templist))
    if len(host_map):
        for hostpair in host_map:
            if len(hostpair) < 3:
                config.set('HostMap', hostpair[0], '')
            else:
                config.set('HostMap', hostpair[0], '|'.join(i[1] for i in sorted(hostpair[2:])))
    with open(ini_file, 'w') as f:
        config.write(f)

    print('check other domains for HostMap...')
    ip_is_enough = False
    q = set()
    with ThreadPoolExecutor(max_workers=threads_num) as executor:
        for hostpair in host_map:
            if len(hostpair) < 3:
                for nameserver in servers:
                    # try twice
                    q.add(executor.submit(nslookup, hostpair[0], [nameserver]))
                    q.add(executor.submit(nslookup, hostpair[1], [nameserver]))
        while thread_alive(q):
            time.sleep(0.1)
            enough = True
            for hostpair in host_map:
                if len(hostpair) < 3:
                    enough = False
                    break
            ip_is_enough = enough
            if ip_is_enough:
                print('ip is enough! wait until all threads complete...')
                executor.shutdown()
                break

    print('save config...')
    templist = sorted(google_com.items(), key=lambda d:d[1])
    config.read(ini_file)
    config.set('IPLookup', 'google_com', '|'.join(i[0] for i in templist))
    if len(host_map):
        for hostpair in host_map:
            if len(hostpair) < 3:
                config.set('HostMap', hostpair[0], '')
            else:
                config.set('HostMap', hostpair[0], '|'.join(i[1] for i in sorted(hostpair[2:])))
    with open(ini_file, 'w') as f:
        config.write(f)

def lookupinteractive(domain, nservers, threads_num, ipnum):
    global dns_servers, default_servers
    global tested_ips, good_ips, ip_is_enough, start_time

    start_time= time.time()
    for chance in range(2):
        if len(nservers):
            servers = nservers
        else:
            servers = default_servers
            if len(servers) < 40:
                servers = servers|set(random.sample((dns_servers-servers), 40-len(servers)))

        q = set()
        with ThreadPoolExecutor(max_workers=threads_num) as executor:
            for nameserver in servers:
                q.add(executor.submit(nslookup, domain, [nameserver]))
            while thread_alive(q):
                try:
                    time.sleep(0.1)
                except KeyboardInterrupt:
                    ip_is_enough = True
                    print('user interrupt. wait until all threads complete...')
                    executor.shutdown()
                    break
                if len(good_ips) >= ipnum:
                    ip_is_enough = True
                    print('ip is enough! wait until all threads complete...')
                    executor.shutdown()
                    break
        if ip_is_enough: break

    if not ip_is_enough:
        print('%d ips found so far.\nwould you like to try extra search?' % len(good_ips))
        a = input('type "y" to continue or otherwise to skip : ')
        if a == 'y':
            print('extra search in some ranges...')
            iprange = []
            if len(good_ips):
                for i in good_ips:
                    r = ".".join(i.split('.')[0:3])+'.0/24'
                    if r not in iprange:
                        iprange.append(r)
            else:
                 for i in tested_ips:
                    r = ".".join(i.split('.')[0:3])+'.0/24'
                    if r not in iprange:
                        iprange.append(r)
                        if len(iprange) >= 4:
                            break
            q = set()
            with ThreadPoolExecutor(max_workers=threads_num) as executor:
                for l in iprange:
                    for ip in IPv4Network(l).hosts():
                        ip = str(ip)
                        if ip not in tested_ips:
                            q.add(executor.submit(checkip, ip, domain))
                while thread_alive(q):
                    try:
                        time.sleep(0.1)
                    except KeyboardInterrupt:
                        ip_is_enough = True
                        print('user interrupt. wait until all threads complete...')
                        executor.shutdown()
                        break
                    if len(good_ips) >= ipnum:
                        ip_is_enough = True
                        print('ip is enough! wait until all threads complete...')
                        executor.shutdown()
                        break

    if not len(good_ips):
        print('sorry, no good ip found. please try again later.')
    else:
        out_file = 'good_ip.ini'
        config.read(out_file)
        if not config.has_section('IPList'):
            config['IPList'] = {}
        config.set('IPList', domain, '|'.join(i for i in good_ips))
        with open(out_file, 'w') as f:
            config.write(f)
        print('%d good ips found and saved to file "%s".' % (len(good_ips), out_file))


import win32gui, ctypes
# from win32con
WM_SETTEXT = 12
WM_GETTEXT = 13
WM_GETTEXTLENGTH = 14
hgui = None

def ctrl_exists(h):
    try:
        return win32gui.GetParent(h)
    except:
        return 0

def setvar(vname, v=''):
    global hgui
    vname = str(vname)
    v = str(v)
    buf_size = win32gui.SendMessage(hgui, WM_GETTEXTLENGTH, 0, 0) + 1
    buf = ctypes.create_unicode_buffer(buf_size)
    win32gui.SendMessage(hgui, WM_GETTEXT, buf_size, buf) # 获取buffer
    lines = buf[:-1].split('\r\n')
    added = 0
    for i in range(len(lines)):
        if lines[i].startswith('%s=' % vname):
            lines[i] = '%s=%s' % (vname, v)
            added = 1
            break
    if not added:
        lines.append('%s=%s' % (vname, v))
    text = '\r\n'.join(lines)
    win32gui.SendMessage(hgui, WM_SETTEXT, None, text)

def getvar(vname):
    global hgui
    buf_size = win32gui.SendMessage(hgui, WM_GETTEXTLENGTH, 0, 0) + 1
    buf = ctypes.create_unicode_buffer(buf_size)
    win32gui.SendMessage(hgui, WM_GETTEXT, buf_size, buf) # 获取buffer
    lines = buf[:-1].split('\r\n')
    for line in lines:
        if line.startswith('%s=' % vname):
            return line[len(vname)+1:]

def send_timestr(): # send time string to tell main thread:"I'm alive".
    global resp_timer
    setvar("ResponseTimer", time.strftime('%Y/%m/%d %H:%M:%S', time.localtime()))
    resp_timer = threading.Timer(3, send_timestr)
    resp_timer.start()

def set_proxy(prx=None):
    global orig_socket

    if not prx:
        socket.socket = orig_socket
        #socks.set_default_proxy()
        #socket.socket = socks.socksocket
        proxy_support = urllib.request.ProxyHandler(None)
        opener = urllib.request.build_opener(proxy_support)
        urllib.request.install_opener(opener)

    elif len(prx) >= 3:
        p_type = prx[0].upper()
        if p_type.startswith('SOCKS'):
            if p_type == 'SOCKS4':
                p_type = socks.SOCKS4
            else: # p_type == 'SOCKS5'
                p_type = socks.SOCKS5
            socks.set_default_proxy(p_type, prx[1], int(prx[2]))
            socket.socket = socks.socksocket # 必须在urllib之前执行
        else: # p_type == 'HTTP'
            p_server = prx[1].lower()
            if p_server == 'google.com':
                setvar("DLInfo", u"|||||查找 Google 可用 IP ...")
                p_server = get_google_ip()
                if not p_server:
                    setvar('DLInfo', u'||1||1|找不到可用的 Google IP')
                    return False
            p = {'http': '%s:%d' % (p_server, int(prx[2])), 'https': '%s:%d' % (p_server, int(prx[2]))}
            proxy_support = urllib.request.ProxyHandler(p)
            opener = urllib.request.build_opener(proxy_support)
            urllib.request.install_opener(opener)

    return True

def get_valid_ip(ips):
    global google_com, ip_is_enough

    google_com = {}
    validip = []
    q = set()
    with ThreadPoolExecutor(max_workers=5) as executor:
        for ip in ips:
            q.add(executor.submit(checkip, ip, 'google.com'))
        while thread_alive(q):
            time.sleep(0.1)
            if len(google_com):
                ip_is_enough = True
                validip = list(google_com.keys())
                executor.shutdown()
                break
    return validip


def get_google_ip():
    global ini_file, config, default_servers, inactive_servers, domains, google_com
    global ip_is_enough

    config.read(ini_file)
    if not config.has_section('IPLookup'):
        config['IPLookup'] = {'google_com':'', 'InactiveServers':'', 'MapHost':1}
        with open(ini_file, 'w') as f:
            config.write(f)

    ips = config.get('IPLookup', 'google_com') if config.has_option('IPLookup', 'google_com') else ''
    validip = []
    googleip = []
    if ips:
        googleip = ips.split('|', 20)
        validip = get_valid_ip(googleip)

    if not len(validip):
        # print('nslookup google ip ...')
        s = config.get('IPLookup', 'InactiveServers') if config.has_option('IPLookup', 'InactiveServers') else ''
        if s:
            inactive_servers_0 = set(s.split('|'))
            inactive_servers = set(s.split('|'))
        else:
            inactive_servers_0 = set()
            inactive_servers = set()
        servers = dns_servers - inactive_servers
        if len(servers) < 20:
            servers = set(random.sample(dns_servers, 40))
        servers = servers|default_servers
        for chance in range(2):
            sdomains = random.sample(domains, 4)  ## pick domains randomly
            q = set()
            ip_is_enough = False
            google_com = {}
            with ThreadPoolExecutor(max_workers=10) as executor:
                for domain in sdomains:
                    for nameserver in servers:
                        q.add(executor.submit(nslookup, domain, [nameserver]))

                while thread_alive(q):
                    time.sleep(0.1)
                    if len(google_com):
                        ip_is_enough = True
                        #print('got a valid google ip, wait until all threads end ...')
                        executor.shutdown()
                        break
            if ip_is_enough: break
        if len(google_com):
            validip = list(google_com.keys())

        if inactive_servers != inactive_servers_0:
            config.set('IPLookup', 'InactiveServers', '|'.join(i for i in inactive_servers))
            with open(ini_file, 'w') as f:
                config.write(f)

    if not len(validip):
        validip = get_google_ip_ex()

    if len(validip):
        for ip in validip:
            if ip in googleip:
                googleip.remove(ip)
            googleip = [ip] + googleip
    else:
        googleip = []
    newips = '|'.join(ip for ip in googleip)
    if newips != ips:
        config.set('IPLookup', 'google_com', newips)
        with open(ini_file, 'w') as f:
            config.write(f)

    if len(validip):
        return validip[0]

def read_from_url(url, b=1024):
    global user_agent
    s = ''
    f = None
    try:
        req = urllib.request.Request(url, headers={'User-Agent':user_agent})
        f = urllib.request.urlopen(req, timeout=3)
        if f.status == 200:
            s = f.read(b).decode('utf-8', 'ignore')
    except:
        pass
    if f:
        f.close()
    return s

def get_google_ip_ex():
    for chance in range(2):
        ips = []
        if chance == 0:
            url = r'http://www.xiexingwen.com/google/tts.php?query=*'
            s = read_from_url(url, 1024)
            if s:
                m = re.search(r'(?is)var +hs\s*=\s*\[\s*([\d\." ,]+)\s*\]', s)
                if m:
                    s = m.group(1)
                    ips = re.findall(r'"(\d+\.\d+\.\d+\.\d+)"', s)
        elif chance == 1:
            url = r'http://www.go2121.com/google/splus.php?query=*'
            s = read_from_url(url, 1024)
            if s:
                m = re.search(r'(?is)var +hs\s*=\s*\[\s*([\d\." ,]+)\s*\]', s)
                if m:
                    s = m.group(1)
                    ips = re.findall(r'"(\d+\.\d+\.\d+\.\d+)"', s)
        if len(ips):
            #print(ips)
            ips = get_valid_ip(ips)
            if len(ips):
                break

    if len(ips) > 20:
        ips = ips[:19]
    return ips


# DLInfo chrome version|chrome urls|complete|success|error|info
def get_latest_chrome_ver(plist=[]):
    global ini_file, proxy

    channel = 'stable'
    x86 = 0
    strproxy = ''
    try:
        channel = plist[0].lower()
        x86 = int(plist[1])
        ini_file = plist[2]
        strproxy = plist[3]
    except:
        pass

    if ':' in strproxy:
        proxy = strproxy.split(':')
    else:
        proxy = None
    if not set_proxy(proxy):
        return

    try:
        aReg = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                              'SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion')
        os_arch = 'x64'
    except:
        os_arch = 'x86'

    latest_chrome = {}
    errinfo = ''
    if channel.startswith('chromium'):
        # https://storage.googleapis.com/chromium-browser-continuous/index.html?path=Win/
        # https://storage.googleapis.com/chromium-browser-continuous/index.html?path=Win_x64/
        host = 'http://storage.googleapis.com'
        if channel == 'chromium-continuous':
            if x86 or os_arch == 'x86':
                urlbase = 'chromium-browser-continuous/Win'
            else:
                urlbase = 'chromium-browser-continuous/Win_x64'
        else:
            urlbase = 'chromium-browser-snapshots/Win'
        for i in range(4):
            if i >= 2 and (not proxy or (len(proxy) >= 3 and proxy[1] != 'google.com')):
                host = 'https://storage.googleapis.com'
            setvar('DLInfo', u'|||||从服务器获取 Chromium 更新信息... 第 %d 次尝试' % (i+1))
            try:
                req = urllib.request.Request(host + '/' + urlbase + '/LAST_CHANGE')
                req.add_header('User-Agent', 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1) Chrome/41.0.2272.101')
                f = urllib.request.urlopen(req, timeout=5)
                s = f.read().decode('utf-8', 'ignore').strip()
                f.close()
                if s.isdigit():
                    latest_chrome = {
                        'channel': channel,
                        'version': s,
                        'urls': '%s/%s/%s/mini_installer.exe' % (host, urlbase, s),
                        'size': 0}
                    break
            except Exception as e:
                errinfo = str(e)
        if len(latest_chrome):
            setvar('DLInfo', u'%s|%s|1|1||已成功获取 Chromium 更新信息' % (latest_chrome['version'], latest_chrome['urls']))
        else:
            setvar('DLInfo', u'||1||1|%s' % errinfo)
        return

    # get latest chrome info according to omaha protocol v3
    # http://code.google.com/p/omaha/wiki/ServerProtocol
    win_ver = '6.1'
    win_sp = 'Service Pack 1'
    try:
        s = sys.getwindowsversion()
        win_ver = '%d.%d' % (s.major, s.minor)
        win_sp = s.service_pack
    except:
        pass

    dict_ap = {
        'stable_x86': '-multi-chrome',
        'stable': 'x64-stable-multi-chrome',
        'beta_x86': '1.1-beta',
        'beta': 'x64-beta-multi-chrome',
        'dev_x86': '2.0-dev',
        'dev': 'x64-dev-multi-chrome',
        'canary_x86': '',
        'canary': 'x64-canary'
        }
    if channel not in dict_ap:
        channel = 'stable'
    if channel == 'canary':
        appid = '4EA16AC7-FD5A-47C3-875B-DBF4A2008C20'
    else:
        appid = '4DC8B4CA-1BDA-483E-B5FA-D3C12E15B62D'
    s = ''
    if x86 or os_arch == 'x86' or win_ver < '6.1':
        os_arch = 'x86'
        s = '_x86'
    ap = dict_ap[channel + s]
    data = '<?xml version="1.0" encoding="UTF-8"?><request protocol="3.0" version="1.3.23.9" ismachine="0">'
    data += '<os platform="win" version="%s" sp="%s" arch="%s"/>' % (win_ver, win_sp, os_arch)
    data += '<app appid="{%s}" version="" nextversion="" ap="%s"><updatecheck/></app></request>' % (appid, ap)
    data = bytes(data, 'utf-8')
    #print(data)
    host = 'http://tools.google.com/service/update2'

    for i in range(4):
        if i >= 2 and (not proxy or (len(proxy) >= 3 and proxy[1] != 'google.com')):
            host = 'https://tools.google.com/service/update2'
        setvar('DLInfo', u'|||||从服务器获取 Chrome 更新信息... 第 %d 次尝试' % (i+1))
        try:
            req = urllib.request.Request(host, method='POST', data=data)
            req.add_header('Content-Type','application/x-www-form-urlencoded;charset=utf-8')
            req.add_header('User-Agent','Google Update/1.3.23.9;winhttp')
            f = urllib.request.urlopen(req, timeout=5)
            s = f.read().decode('utf-8', 'ignore')
            #print(s)
            f.close()
            m = re.search(r'(?i)<manifest +version="(.+?)".* name="(.+?)".* size="(\d+)"', s)
            if m:
                urls = re.findall(r'(?i)<url +codebase="(.+?)"', s)
                if len(urls):
                    latest_chrome = {
                        'channel': channel,
                        'version': m.group(1),
                        'urls': ' '.join([x + m.group(2) for x in urls]),
                        'size': int(m.group(3))}
                    break
        except Exception as e:
            errinfo = str(e)
            #print(errinfo)

    if len(latest_chrome):
        setvar('DLInfo', u'%s|%s|1|1||已成功获取 Chrome 更新信息' % (latest_chrome['version'], latest_chrome['urls']))
    else:
        setvar('DLInfo', u'||1||1|%s' % errinfo)


user_agent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1) Chrome/41.0.2272.101'
# download_info [[start_pos, pointer, end_pos, complete, success], [...]]
download_info = []
# download_status [size, total_size, complete, success, error, info]
download_status = [0,0,'','','','']
def downloader(block_id, url, fobj, buffer=16384):
    global lock, user_agent, download_info, download_status

    chance = 0
    while chance < 3:
        chance += 1
        time.sleep(0.1)
        req = urllib.request.Request(url, headers={'User-Agent':user_agent})
        req.headers['Range'] = 'bytes=%d-%d' % (download_info[block_id][1], download_info[block_id][2])  # set HTTP Header(RANGE)
        try:
            response = urllib.request.urlopen(req, timeout=10)
        except:
            continue

        while True:
            try:
                block = response.read(buffer)
                if not block:
                    continue
            except:
                break
            with lock:
                try:
                    fobj.seek(download_info[block_id][1])  # seek offset
                    fobj.write(block)
                    chance = 0
                except:
                    download_info[block_id][3] = 1  # complete
                    download_status[2] = 1
                    download_status[4] = 3
                    download_status[5] = u'无法保存已下载的数据'
                    return
                block_len = len(block)
                if block_len >= download_info[block_id][2] - download_info[block_id][1] + 1:
                    block_len = download_info[block_id][2] - download_info[block_id][1] + 1
                    download_info[block_id][4] = 1  # success
                download_info[block_id][1] += block_len
                download_status[0] += block_len  # downloaded_size
                if download_info[block_id][4]:
                    break

        if block_len >= download_info[block_id][2] - download_info[block_id][1] + 1:
            download_info[block_id][4] = 1  # success
        if download_info[block_id][4]:
            break
    if response: response.close()
    with lock:
        download_info[block_id][3] = 1  # complete

def download2file(url, save_file, threads=5, resume=False):
    global user_agent, download_info, download_status, lock

    buffer=16384
    if resume:
        download_status[2] = ''
        download_status[4] = ''
        download_status[5] = u'尝试断点续传 ...'
    else:
        download_status = [0,0,'','','','']
        # get file size
        total_size = 0
        for i in range(2):
            error = ''
            req = urllib.request.Request(url, headers={'User-Agent':user_agent})
            req.headers['Range'] = 'bytes=16-128'
            try:
                response = urllib.request.urlopen(req, timeout=5)
                if response.status == 200:  # 不支持断点续传，改单线程
                    total_size = int(response.getheader('Content-Length'))
                    threads = 1
                elif response.status == 206:
                    total_size = int(response.getheader('Content-Range').split('/')[1])
                else:
                    raise Exception(u'获取远程文件信息失败')
                if total_size: break
            except Exception as e:
                error = e
            finally:
                if response:
                    response.close()
        if not total_size:
            download_status[2] = 1
            download_status[4] = 1
            download_status[5] = error
            return
        download_status[1] = total_size

        # assign range for every thread
        # download_info [[start_pos, pointer, end_pos, complete, success], [...]]
        # download_status [size, total_size, complete, success, error, info]
        block_size = int(total_size / threads)
        download_info = []
        for i in range(threads-1):
            download_info.append([i*block_size, i*block_size, i*block_size+block_size-1, 0, 0])
        download_info.append([block_size*(threads-1), block_size * (threads-1), total_size-1, 0, 0])

    try:
        if resume:
            fobj = open(save_file, 'r+b')
        else:
            fobj = open(save_file, 'wb')
    except Exception as e:
        download_status[2] = 1
        download_status[4] = 2
        download_status[5] = u'无法保存文件 ' + e
        return

    t = []
    s = [time.time(), download_status[0]]
    q = [] # queue for download speed calculation
    for i in range(50):
        q.append(s)
    with ThreadPoolExecutor(max_workers=threads) as executor:
        for i in range(len(download_info)):
            if not download_info[i][4]:
                download_info[i][3] = 0
                t.append(executor.submit(downloader, i, url, fobj, buffer))

        while thread_alive(t):
            time.sleep(0.2)
            q.remove(q[0])
            q.append([time.time(), download_status[0]])
            pst = download_status[0]/download_status[1]*100
            speed = (q[-1][1]-q[0][1])/(q[-1][0]-q[0][0])/1024
            if download_status[1]/1024/1024 > 1:
                progress = u'下载进度：  %.1f %%  -  %.1f MB / %.1f MB  -  %.1f KB/s' % (
                    pst, download_status[0]/1024/1024, download_status[1]/1024/1024, speed)
            else:
                progress = u'下载进度：  %.1f %%  -  %.1f KB / %.1f KB  -  %.1f KB/s' % (
                    pst, download_status[0]/1024, download_status[1]/1024, speed)

            with lock:
                download_status[5] = progress

    download_status[2] = 1
    if download_status[0] < download_status[1]:
        download_status[4] = 10  # 未下载完整，可续传
        download_status[5] = u'文件未下载完整'
    elif download_successful():
        download_status[3] = 1 # Success
        download_status[4] = ''
        download_status[5] = u'文件下载完成'
    fobj.flush()
    fobj.close()
    return

def download_successful():
    global download_info
    if not len(download_info):
        return False
    for i in download_info:
        if not i[4]:
            return False
    return True


valid_urls = []
def test_url(url):
    global lock, valid_urls
    req = urllib.request.Request(url, headers={'User-Agent':user_agent})
    try:
        response = urllib.request.urlopen(req, timeout=5)
        if response.status == 200:
            with lock:
                valid_urls.append(url)
    except:
        pass


def download_chrome(plist=[]):
    # download_status [size, total_size, complete, success, error, info]
    global proxy, valid_urls, download_status, ini_file

    urls = ''
    localfile = ''
    version = ''
    threads = 3
    strproxy = ''
    try:
        urls = plist[0].split()
        localfile = plist[1]
        threads = int(plist[2])
        ini_file = plist[3]
        strproxy = plist[4]
    except:
        pass

    if ':' in strproxy:
        proxy = strproxy.split(':')
    else:
        proxy = None
    if not set_proxy(proxy):
        return

    valid_urls = []
    setvar('DLInfo', u'|||||尝试连接 url ...')
    for chance in range(2):
        t = []
        with ThreadPoolExecutor(max_workers=5) as executor:
            for url in urls:
                t.append(executor.submit(test_url, url))

            while thread_alive(t):
                time.sleep(1)
                if len(valid_urls):
                    executor.shutdown()

        if len(valid_urls):
            break
        if proxy and proxy[1] != 'google.com':
            break
        if not set_proxy():
            break


    if not len(valid_urls):
        setvar('DLInfo', u'||1||1|已获取的 url 无法连接')
        return

    end = False
    resume = False
    while not end:
        with ThreadPoolExecutor(max_workers=1) as executor:
            t = executor.submit(download2file, valid_urls[0], localfile, threads, resume)

            while thread_alive([t]):
                time.sleep(1)
                with lock:
                    setvar('DLInfo', u'|'.join([str(x) for x in download_status]))

        if download_status[4] != 10:
            break
        while True:
            time.sleep(0.1)
            rsm = getvar('ResumeDownload')
            if rsm == '1':
                resume = True
                setvar('ResumeDownload', 0)
                break
            if not ctrl_exists(hgui):
                end = True
                break


def main():
    global ini_file, ip_is_enough, tested_ips, good_ips, default_servers
    global max_threads, interactive, check_inifile
    global hgui

    default_servers = set(get_dnsserver_list())
    if len(sys.argv) == 2: # check ini_file
        ini_file = sys.argv[1]
        if os.path.isfile(ini_file):
            check_inifile = True
            checkini(max_threads)
    elif len(sys.argv) >= 4 and sys.argv[1] == 'child_thread_by':
        # child thread to run a function:
        # child_thread_by 0xhwnd function arg1 arg2 ...
        hgui = win32gui.FindWindowEx(int(sys.argv[2], 16), None, 'Edit', None)
        #print(int(sys.argv[2], win32gui.GetParent(hgui), hgui)
        ini_file = 'Mychrome.ini'
        func = globals()[sys.argv[3]]
        v = None
        if len(sys.argv) > 4:
            v = sys.argv[4:]
        global resp_timer
        resp_timer = threading.Timer(3, send_timestr)
        resp_timer.start()
        #print(hgui, func, v)
        func(v) # start a func

        resp_timer.cancel()
    else:
        interactive = True
        print('Mychrome Internet Module')
        while True:
            a = input('\ntype domain to resolve of "q" to exit : ')
            if a == 'q':
                break
            if a == '' or '.' not in a:
                continue
            s = a.split()
            domain = s[0]
            if len(s) > 1:
                server = {s[1]}
            else:
                server = set()
            threads_num = 30
            ipnum = 10
            lookupinteractive(domain, server, threads_num, ipnum)
            tested_ips = set()
            good_ips = set()
            ip_is_enough = False


if __name__ == "__main__":
    main()
    #input('press any key to quit')
