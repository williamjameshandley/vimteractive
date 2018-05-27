# Vimteractive
Send commands from text files to interactive programs via vim. 

Vimteractive was inspired by the workflow of the [vim-ipython](https://github.com/ivanov/vim-ipython) plugin.

This plugin is designed to extend a subset of the functionality of vim-ipython to other interpreters (including ipython). 

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

