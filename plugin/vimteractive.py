import pexpect
import vim
import contextlib

@contextlib.contextmanager
def preview_window():
    """ Tool to switch to the preview window and execute commands"""
    vim.command('wincmd P')    #switch to preview window
    yield
    vim.command('normal! p') #Switch to previous window


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
        vim.command('vert pedit interactive')
        vim.command('set winwidth=80')

        with preview_window():
            if self.filetype is not None:
                vim.command("set filetype=%s" % self.filetype)
            vim.command("set bufhidden=hide buftype=nofile")
            vim.command("setlocal nobuflisted") # don't come up in buffer lists
            vim.command("setlocal nonumber") # no line numbers, we have in/out nums
            vim.command("setlocal noswapfile") # no swap file (so no complaints cross-instance)

        self.process = pexpect.spawn(self.command)
        self.to_preview();

    def to_preview(self):
        with preview_window():
            for line in self.read():
                vim.current.buffer.append(line)
            vim.command('normal! G')   # go to the end of the file

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

    def setup_preview(self):
        pass

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
    filetype = None

    def __init__(self):
        super(Maple, self).__init__()

        self.send('interface(errorcursor=false);')
        for line in self.read():
            pass


class Python(Server):
    """ python """
    command = 'python'
    prompt = '>>>'
    filetype = 'python'


class IPython(Server):
    """ ipython """
    command = 'ipython --simple-prompt --matplotlib'
    prompt = 'In \[[0-9]+\]:'
    filetype = 'python'


class Bash(Server):
    """ bash """
    command = 'bash --noprofile --norc'
    prompt = 'bash-[0-9.]+\$'
    filetype = 'python'
