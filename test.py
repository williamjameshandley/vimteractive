import pexpect
import sys

class Server(object):
    def __init__(self):
        self.process = pexpect.spawn(self.command, encoding='utf-8')
        self.intro = ''
        for line in self.read():
            self.intro += line + '\n'

    def send(self, line):
        self.process.sendline(line)

    def read(self):
        while True:
            self.process.expect(self.prompt_or_newline)
            yield self.process.before
            if self.process.after == self.prompt:
                return

    @property
    def newline(self):
        return '\r\n'

    @property
    def prompt_or_newline(self):
        return '(%s|%s)' % (self.newline,self.prompt)


class Maple(Server):
    command = "maple"
    prompt = '\r>'

    def __init__(self):
        super(Maple, self).__init__()

        self.send('interface(errorcursor=false);')
        for line in self.read():
            pass

class Python(Server):
    command = "python"
    prompt = '>>>'


mserver = Maple()
print(mserver.intro)

mserver.send('a+b);')
for line in mserver.read():
    print(line)

mserver.send('(a+b)/c;')
for line in mserver.read():
    print(line)

mserver.send('with(Physics);')
for line in mserver.read():
    print(line)



pserver = Python()
print(pserver.intro)

pserver.send('a=1')
for line in pserver.read():
    print(line)

pserver.send('b=2')
for line in pserver.read():
    print(line)

pserver.send('a+b')
for line in pserver.read():
    print(line)
