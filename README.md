# Vimteractive
Send commands from text files to interactive programs via vim. 

Vimteractive was inspired by the workflow of the [vim-ipython](https://github.com/ivanov/vim-ipython) plugin.

This plugin is designed to extend a subset of the functionality of vimteractive to other interpreters (including ipython). 

At the moment, vimteractive supports the following interpreters:

- python
- ipython
- maple
- bash

## Installation
It's recommended to install via Vundle from this github repo

## Usage

Start an intepreter with `:I<interpreter name>` for example:

    :Iipython

Send line(s) of python from a text file to an interpreter in the preview window
with `<C-s>`

## Extending functionality

In many cases, you simply need to add another python class at the bottom of the
file plugin/vimteractive.py, and an extra I<interpreter name> command to
plugin/vimteractive.vim

