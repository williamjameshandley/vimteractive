# Vimteractive
Send commands from text files to interactive programs via vim. 

Vimteractive was inspired by the workflow of the [vim-ipython](https://github.com/ivanov/vim-ipython) plugin.

This plugin is designed to extend a subset of the functionality of vim-ipython to other interpreters (including ipython). It is based around the unix philosophy of ["do one thing and do it well"](https://en.wikipedia.org/wiki/Unix_philosophy#Do_One_Thing_and_Do_It_Well). It aims to provide a robust and simple link from between text files and interactive interpreters. Vimteractive will never aim to do things like autocompletion, leaving that to other, more developed tools such as [YouCompleteMe](https://github.com/Valloric/YouCompleteMe).

At the moment, vimteractive supports the following interpreters:

- python
- ipython
- maple
- bash

## Installation
- Installation should be relatively painless via the usual routes such as [Vundle](https://github.com/VundleVim/Vundle.vim) or [Pathogen](https://github.com/tpope/vim-pathogen)

-  If you're masochistic enough to use [Arch](https://wiki.archlinux.org/index.php/Arch_Linux)/[Manjaro](https://manjaro.org/), it is also installable via the [aur](https://aur.archlinux.org/packages/vim-vimteractive)

- For old-school users, there is also a package on the [vim repo](https://www.vim.org/scripts/script.php?script_id=5687)

## Usage

Start an intepreter with `:I<interpreter name>` for example:

    :Iipython

Send line(s) of python from a text file to an interpreter in the preview window with `<C-s>`

## Extending functionality

In many cases, you simply need to add another python class at the bottom of the
file plugin/vimteractive.py, and an extra I<interpreter name> command to
plugin/vimteractive.vim

Feel free to create a [fork and pull request](https://gist.github.com/Chaser324/ce0505fbed06b947d962) with your proposed changes

## Similar projects
- [vim-ipython](https://github.com/ivanov/vim-ipython)
- [vim-notebook](https://github.com/baruchel/vim-notebook)
- [conque](https://code.google.com/archive/p/conque/)
- [vim-slime](https://github.com/jpalardy/vim-slime)
- [tslime_ipython](https://github.com/eldridgejm/tslime_ipython)
- [vipy](https://github.com/johndgiese/vipy)

