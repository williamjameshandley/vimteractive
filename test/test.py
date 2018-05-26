from vim_interactive import *

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

