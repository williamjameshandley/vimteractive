import pexpect
import sys

class Server(object):
    def __init__(self):
        process = "maple"
        self.child = pexpect.spawn(process)
        self.intro = ''
        for line in self.read():
            self.intro += line + '\n'

        self.send('interface(errorcursor=false);')
        for line in self.read():
            pass

    def send(self, line):
        self.child.sendline(line)

    def read(self):
        while True:
            self.child.expect('\r[\n>]')
            yield self.child.before.decode('utf-8') 
            if self.child.after == b'\r>':
                return

mserver = Server()
print(mserver.intro)

mserver.send(None)
for line in mserver.read():
    print(line)

mserver.send('(a+b)/c;')
for line in mserver.read():
    print(line)

mserver.send('with(Physics);')
for line in mserver.read():
    print(line)
