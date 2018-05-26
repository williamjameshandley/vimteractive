import pexpect

class Server(object):
    """ Base class for generic server

    This class leverages pexpect to send and recieve lines from an interactive
    prompt. 

    When deriving from this class, you need to defined the member variables:

    self.command : str
        Command to start the interpreter

    self.prompt : str
        Interpreter's prompt
    """
    def __init__(self):
        self.process = pexpect.spawn(self.command, encoding='utf-8')
        self.intro = ''
        for line in self.read():
            self.intro += line + '\n'

    def send(self, line):
        """ Send line to prompt. """
        self.process.sendline(line)

    def read(self):
        """ Loop over lines until next prompt """
        while True:
            index = self.process.expect([self.prompt,'\r\n'])
            yield self.process.before
            if index is 0:
                yield self.process.after
                return


class Maple(Server):
    """ Maple """
    command = 'maple'
    prompt = '\r>'

    def __init__(self):
        super(Maple, self).__init__()

        self.send('interface(errorcursor=false);')
        for line in self.read():
            pass


class Python(Server):
    command = 'python'
    prompt = '>>>'


class IPython(Server):
    command = 'ipython --simple-prompt --matplotlib'
    prompt = 'In \[[0-9]+\]:'


class Bash(Server):
    command = 'bash --noprofile --norc'
    prompt = 'bash-[0-9.]+\$'

server = Maple()
print(server.intro)

server.send('a+b);')
for line in server.read():
    print(line)

server.send('(a+b)/c;')
for line in server.read():
    print(line)

server.send('with(Physics);')
for line in server.read():
    print(line)



server = IPython()
print(server.intro)

server.send('a=1')
for line in server.read():
    print(line)

server.send('b=2')
for line in server.read():
    print(line)

server.send('a+b')
for line in server.read():
    print(line)


server = Bash()
print(server.intro)

server.send('pwd')
for line in server.read():
    print(line)

server.send('cd ..')
for line in server.read():
    print(line)

server.send('pwd')
for line in server.read():
    print(line)
