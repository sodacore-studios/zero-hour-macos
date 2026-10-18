from pathlib import Path
import socket,struct,secrets,json,time,hmac,hashlib,base64,argparse
parser=argparse.ArgumentParser();parser.add_argument('--secrets',type=Path,required=True);parser.add_argument('--host',required=True);parser.add_argument('--denied-peer',default='192.0.2.1');args=parser.parse_args()
SECRET=json.loads(args.secrets.read_text())['turn']
HOST=args.host; COOKIE=0x2112a442

def attr(t,b):return struct.pack('!HH',t,len(b))+b+b'\0'*((-len(b))%4)
def parse(b):
 d={};i=20
 while i+4<=len(b):
  t,n=struct.unpack('!HH',b[i:i+4]);d[t]=b[i+4:i+4+n];i+=4+((n+3)//4)*4
 return d

def addr(v):
 return socket.inet_ntoa(bytes(x^y for x,y in zip(v[4:8],struct.pack('!I',COOKIE)))),struct.unpack('!H',v[2:4])[0]^(COOKIE>>16)
def xaddr(a):
 return b'\0\1'+struct.pack('!H',a[1]^(COOKIE>>16))+bytes(x^y for x,y in zip(socket.inet_aton(a[0]),struct.pack('!I',COOKIE)))
def error(a):
 v=a.get(9,b'\0'*4);return v[2]*100+v[3]

class Client:
 def __init__(self,label):
  self.s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);self.s.settimeout(5);self.s.connect((HOST,3478))
  self.user=f'{int(time.time())+600}:probe-{label}'.encode();self.key=None
  t,a=self.request(3,attr(0x19,b'\x11\0\0\0'),False)
  assert t==0x113 and error(a)==401,(t,error(a))
  self.realm=a[0x14];self.nonce=a[0x15]
  password=base64.b64encode(hmac.new(SECRET.encode(),self.user,hashlib.sha1).digest())
  self.key=hashlib.md5(self.user+b':'+self.realm+b':'+password).digest()
  t,a=self.request(3,attr(0x19,b'\x11\0\0\0'))
  assert t==0x103,(t,error(a))
  self.relay=addr(a[0x16]);assert self.relay[0]==socket.gethostbyname(HOST) and 49160<=self.relay[1]<=49200,self.relay
 def request(self,t,attrs,auth=True):
  tx=secrets.token_bytes(12)
  if auth:attrs+=attr(6,self.user)+attr(0x14,self.realm)+attr(0x15,self.nonce)
  msg=struct.pack('!HHI',t,len(attrs)+(24 if auth else 0),COOKIE)+tx+attrs
  if auth:msg+=attr(8,hmac.new(self.key,msg,hashlib.sha1).digest())
  self.s.send(msg);b=self.s.recv(8192);assert b[8:20]==tx
  return struct.unpack('!H',b[:2])[0],parse(b)
 def permission(self,peer):
  return self.request(8,attr(0x12,xaddr(peer)))
 def send(self,peer,payload):
  attrs=attr(0x12,xaddr(peer))+attr(0x13,payload)
  self.s.send(struct.pack('!HHI',0x16,len(attrs),COOKIE)+secrets.token_bytes(12)+attrs)
 def receive(self,payload):
  b=self.s.recv(8192);assert struct.unpack('!H',b[:2])[0]==0x17
  assert parse(b)[0x13]==payload
 def close(self):
  try:self.request(4,attr(0xd,struct.pack('!I',0)))
  finally:self.s.close()

clients=[]
try:
 a=Client('A');clients.append(a);b=Client('B');clients.append(b)
 print('PASS: public UDP 3478 reachable; unauthenticated allocation rejected; authenticated allocations use public relay ports',flush=True)
 for c,peer in [(a,b.relay),(b,a.relay)]:
  t,r=c.permission(peer);assert t==0x108,(t,error(r))
 t,r=a.permission((args.denied_peer,5001));assert t==0x118 and error(r)==403,(t,error(r))
 print('PASS: relay peer permissions accepted; access to excluded peer denied',flush=True)
 for i in range(5):
  payload=b'ZeroHour public relay A->B '+str(i).encode()+secrets.token_bytes(32)
  a.send(b.relay,payload);b.receive(payload)
  payload=b'ZeroHour public relay B->A '+str(i).encode()+secrets.token_bytes(32)
  b.send(a.relay,payload);a.receive(payload)
 print('PASS: 10 payloads transmitted bidirectionally through public relay mapping with exact content',flush=True)
finally:
 for c in clients:
  try:c.close()
  except Exception:pass
