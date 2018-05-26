import pexpect
import vim

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
        vim.command('pedit interactive')
        self.process = pexpect.spawn(self.command)
        self.to_preview();

    def to_preview(self):
        vim.command('wincmd P')    #switch to preview window
        for line in self.read():
            vim.current.buffer.append(line)
        vim.command('normal! G')   # go to the end of the file
        vim.command('normal! p') # go back to where you were

    def runline(self):
        line = vim.current.line
        self.send(line)
        self.to_preview()

    def runlines(self):
        lines = vim.current.range
        for line in lines:
            self.send(line)
            self.to_preview()

    def send(self, line):
        """ Send line to prompt. """
        self.process.sendline(line)

    def read(self):
        """ Loop over lines until next prompt """
        while True:
            index = self.process.expect([self.prompt,'\r\n'])
            yield self.process.before.decode('utf-8')
            if index is 0:
                yield self.process.after.decode('utf-8')
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
    """ python """
    command = 'python'
    prompt = '>>>'


class IPython(Server):
    """ ipython """
    command = 'ipython --simple-prompt --matplotlib'
    prompt = 'In \[[0-9]+\]:'


class Bash(Server):
    """ bash """
    command = 'bash --noprofile --norc'
    prompt = 'bash-[0-9.]+\$'
