# Vimteractive
Send commands from text files to interactive programs via vim. 

Vimteractive was inspired by the workflow of the [vim-ipython](https://github.com/ivanov/vim-ipython) plugin.

This plugin is designed to extend a subset of the functionality of vim-ipython to other interpreters (including ipython). It is based around the unix philosophy of ["do one thing and do it well"](https://en.wikipedia.org/wiki/Unix_philosophy#Do_One_Thing_and_Do_It_Well). It aims to provide a robust and simple link from between text files and interactive interpreters. Vimteractive will never aim to do things like autocompletion, leaving that to other, more developed tools such as [YouCompleteMe](https://github.com/Valloric/YouCompleteMe).

The activating commands are 
- ipython `:Iipython` 
- python  `:Ipython`
- maple   `:Imaple`
- bash    `:Ibash`

Commands may be sent from a text file to the chosen terminal using `CTRL-S`. 

## Installation
- Installation should be relatively painless via the usual routes such as [Vundle](https://github.com/VundleVim/Vundle.vim) or [Pathogen](https://github.com/tpope/vim-pathogen)

-  If you're masochistic enough to use [Arch](https://wiki.archlinux.org/index.php/Arch_Linux)/[Manjaro](https://manjaro.org/), it is also installable via the [aur](https://aur.archlinux.org/packages/vim-vimteractive)

- For old-school users, there is also a package on the [vim repo](https://www.vim.org/scripts/script.php?script_id=5687)


## Motivation

[IPython and Jupyter](https://ipython.org/) are excellent tools for exploratory analyses in python. They leverage the interactivity of the python kernel to allow you to keep results of calculations in memory whilst developing further code to process them.

However, I can't stand typing into anything other than vim. Anywhere else, my screen fills with hjklEB, or worse, I close the window with a careless `<C-w>`. I want a technique that allows me to operate on plain text files, but still be able to work interactively with the interpreter with minimal effort.

[Many Projects](#similar-projects) achieve this with a varying level of functionality. Vimteractive aims to create the simplest tool for sending things from text to interpreter, and making it easy to add additional interpreters. In particular, my main aim in starting this was to get a vim-ipython like interface to the command line [maple](https://www.maplesoft.com/).


## Usage

### Example usage:

Create a python file `vimteractive_test.py` with the following content:
```python
import matplotlib.pyplot as plt
import numpy

fig, ax = plt.subplots()
x = numpy.linspace(-2,2,1000)
y = x**3-x
ax.plot(x, y)
ax.set_xlabel('$x$')
ax.set_ylabel('$y$')
```

Now start an ipython interpreter in vim with `:Iipython`. You should see a
preview window open above with your ipython prompt. Position your cursor over
the first line of `vimteractive_test.py`, and press  `CTRL-S`. You should see this
line now appear in the first prompt of the preview window. Do the same with
the second and fourth lines. At the fourth line, you should see a figure
appear once it's constructed with `plt.subplots()`. Continue by sending lines to
the interpreter. You can send multiple lines by doing a visual selection and
pressing `CTRL-S`.

If you switch windows with `CTRL-W+k`, you will see the terminal buffer switch
to a more usual looking normal-mode buffer, from which you can perform
traditional normal mode commands. However, if you try to insert, you will
enter the terminal, and be able to enter commands interactively into the
prompt as if you had run it in the command line. You can save this buffer if
you wish to a new file if it contains valuable output

### Supported terminals

- `:Iipython` Activate an ipython terminal
- `:Ipython`  Activate a python terminal
- `:Imaple`   Activate a maple terminal
- `:Ibash`    Activate a bash terminal

### Sending commands

`CTRL-S` sends lines of text to the interpreter in a mode-dependent manner:

In Normal mode, `CTRL-S` sends the line currently occupied by the cursor
the terminal.

In Insert mode, `CTRL-S` sends the line currently being edited, and then
returns to insert mode at the same location.

In Visual mode, `CTRL-S` sends all currently selected lines to the terminal.

## Extending functionality
This project is very much in an alpha phase, so if you have any issues that arise on your system, feel free to [contact me](mailto:williamjameshandley@gmail.com).

If you want to add additional interpreters, in many cases, you simply need to add an extra `I<interpreter name>` command to `plugin/vimteractive.vim`. Feel free to create a [fork and pull request](https://gist.github.com/Chaser324/ce0505fbed06b947d962) with your proposed changes

## Similar projects
- [vim-ipython](https://github.com/ivanov/vim-ipython)
- [vim-notebook](https://github.com/baruchel/vim-notebook)
- [conque](https://code.google.com/archive/p/conque/)
- [vim-slime](https://github.com/jpalardy/vim-slime)
- [tslime_ipython](https://github.com/eldridgejm/tslime_ipython)
- [vipy](https://github.com/johndgiese/vipy)
