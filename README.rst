============
Vimteractive
============
:vimteractive: send commands from text files to interactive programs via vim
:Author: Will Handley
:Version: 3.0.0 (vimteractive3 branch)
:Homepage: https://github.com/williamjameshandley/vimteractive
:Documentation: ``:help vimteractive``

Vimteractive was inspired by the workflow of the
`vim-ipython <https://github.com/ivanov/vim-ipython>`__ plugin.

This plugin is designed to extend a subset of the functionality of vim-ipython
to other `REPLs <https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop>`__ (including ipython). It is based around the unix
philosophy of `"do one thing and do it well" <https://en.wikipedia.org/wiki/Unix_philosophy#Do_One_Thing_and_Do_It_Well>`__.
Vimteractive aims to provide a robust and simple link between text files and
language shells. Vimteractive will never aim to do things like
autocompletion, leaving that to other, more developed tools such as
`YouCompleteMe <https://github.com/Valloric/YouCompleteMe>`__ or
`Copilot <https://github.com/features/copilot>`__.

**New in vimteractive3: Dual backend support!**

- **tmux backend** (default): Opens REPLs in external terminal windows via tmux
  
  - Pros: Terminal persists after vim exits, better for long-running sessions
  - Cons: Requires tmux, xterm, and xdotool
  
- **vimterminal backend**: Uses vim's built-in ``:terminal`` feature
  
  - Pros: No external dependencies, integrated vim experience
  - Cons: Terminal closes with vim

Set your backend with ``let g:vimteractive_backend = 'vimterminal'`` or ``'tmux'``

The activating commands are:

- `ipython <https://ipython.readthedocs.io>`__ ``:Iipython``
- `julia <https://julialang.org/>`__ ``:Ijulia``
- `maple <https://maplesoft.com/>`__ ``:Imaple``
- `mathematica <https://www.wolfram.com/mathematica/>`__ ``:Imathematica``
- `bash <https://en.wikipedia.org/wiki/Bash_(Unix_shell)>`__ ``:Ibash``
- `zsh <https://www.zsh.org/>`__ ``:Izsh``
- `python <https://www.python.org/>`__ ``:Ipython``
- `clojure <https://clojure.org/>`__ ``:Iclojure``
- `apl <https://en.wikipedia.org/wiki/APL_(programming_language)>`__ ``:Iapl``
- `R <https://www.r-project.org/>`__ ``:IR``
- `sgpt <https://github.com/TheR1D/shell_gpt>`__ ``:Isgpt``
- `gpt-command-line <https://github.com/kharvd/gpt-cli>`__ ``:Igpt``
- `aichat <https://github.com/sigoden/aichat>`__ ``:Iaichat``
- autodetect based on filetype ``:Iterm``

Commands may be sent from a text file to the chosen REPL using ``CTRL-S``.
If there is no REPL, ``CTRL-S`` will automatically open one for you using
``:Iterm``.

For supported REPLs (IPython, sgpt, gpt-command-line, aichat, zsh), the output 
of the last command may be retrieved with ``CTRL-Y``.

Note: it's highly recommended to use IPython as your default Python
interpreter. You can set it like this:

.. code:: vim

	let g:vimteractive_default_repls = { 'python': 'ipython' }

Migration from Vimteractive v2
-------------------------------

**Important changes in v3:**

1. **Default backend is tmux** (external terminals), not vim's native terminal
2. **New dependency**: vim-slime is now required
3. **Commands changed**: ``:Ipython`` now starts IPython (not ``:Iipython2`` or ``:Iipython3``)

**To get the v2 experience (vim's native terminal):**

Add this to your ``.vimrc``:

.. code:: vim

	" Use vim's built-in terminal instead of tmux
	let g:vimteractive_backend = 'vimterminal'
	
	" Optional: Configure terminal split behavior
	let g:vimteractive_vimterminal_config = {
	    \ 'vertical': 1,     " Use vertical split
	    \ 'term_rows': 20    " Set terminal height
	    \ }

**To use the new tmux backend (recommended for long sessions):**

Install the dependencies: tmux, xterm (or another terminal), and xdotool.
No configuration needed - tmux is the default.

Installation
------------

**Core Dependencies (both backends):**

- Vim 8 or greater
- `vim-slime <https://github.com/jpalardy/vim-slime>`__ (required for sending text)

**Additional Dependencies for tmux backend:**

- `tmux <https://github.com/tmux/tmux>`__ (for terminal multiplexing)
- `xterm` or another terminal emulator (configurable via ``g:vimteractive_terminal``)
- `xdotool <https://github.com/jordansissel/xdotool>`__ (for window focus management)
- `perl` and `col` (for zsh output processing)

**Vimterminal backend requires no additional dependencies!**

Installation should be relatively painless via
`the usual routes <https://vimawesome.com/plugin/vimteractive>`_ such as
`Vundle <https://github.com/VundleVim/Vundle.vim>`__,
`Pathogen <https://github.com/tpope/vim-pathogen>`__ or the vim 8 native
package manager (``:help packages``).

**Important:** You must also install vim-slime as it's a required dependency:

.. code:: vim

    " Example for Vundle
    Plugin 'jpalardy/vim-slime'
    Plugin 'williamjameshandley/vimteractive'

If you're masochistic enough to use
`Arch <https://wiki.archlinux.org/index.php/Arch_Linux>`__/`Manjaro <https://manjaro.org/>`__,
you can install vimteractive via the
`aur <https://aur.archlinux.org/packages/vim-vimteractive>`__.
For old-school users, there is also a package on the `vim
repo <https://www.vim.org/scripts/script.php?script_id=5687>`__.
Depending on your package manager, you may need to run ``:helptags <path/to/repo/docs>`` to install the help documentation.

Motivation
----------

`IPython and Jupyter <https://ipython.org/>`__ are excellent tools for
exploratory analyses in python. They leverage the interactivity of the python
kernel to allow you to keep results of calculations in memory whilst developing
further code to process them.

However, I can't stand typing into anything other than vim. Anywhere else, my
screen fills with hjklEB, or worse, I close the window with a careless
``<C-w>``. I want a technique that allows me to operate on plain text files,
but still be able to work interactively with the interpreter with minimal
effort.

`Many Projects <#similar-projects>`__ achieve this with a varying level of
functionality. Vimteractive aims to create the simplest tool for sending things
from text to interpreter, and making it easy to add additional interpreters. In
particular, my main aim in starting this was to get a vim-ipython like
interface to the command line `maple <https://www.maplesoft.com/>`__.

Usage
-----

To use the key-bindings, you should first disable the ``CTRL-S``
default, which is a terminal command to freeze the output. You can
disable this by putting

.. code:: bash

   stty -ixon

into your ``.bashrc`` (or equivalent shell profile file).


Example usage:
~~~~~~~~~~~~~~

|example_usage|

Create a python file ``test.py`` with the following content:

.. code:: python

   import matplotlib.pyplot as plt
   import numpy

   fig, ax = plt.subplots()
   x = numpy.linspace(-2,2,1000)
   y = x**3-x
   ax.plot(x, y)
   ax.set_xlabel('$x$')
   ax.set_ylabel('$y$')

Now start an ipython interpreter with ``:Iipython``. An external terminal 
window will open running IPython in a tmux session. Position your cursor over
the first line of ``test.py``, and press ``CTRL-S``. You should see this line
now appear in the IPython terminal. Do the same with the second and fourth 
lines. At the fourth line, you should see a figure appear once it's 
constructed with ``plt.subplots()``. Continue by sending lines to the
interpreter. You can send multiple lines by doing a visual selection and
pressing ``CTRL-S``.

The REPL runs in an external terminal window attached to a tmux session, 
allowing you to interact with it directly if needed

You may want to send lines to one REPL from two buffers. To achieve that,
run ``:Iconn <pane_name>`` where ``<pane_name>`` is the name of the tmux pane
containing the REPL (tab completion available). If there is only one REPL, 
you can use just ``:Iconn``.

Supported REPLs
~~~~~~~~~~~~~~~

-  ``:Iipython`` Activate an ipython REPL
-  ``:Ijulia`` Activate a julia REPL
-  ``:Imaple`` Activate a maple REPL
-  ``:Imathematica`` Activate a mathematica REPL
-  ``:Ibash`` Activate a bash REPL
-  ``:Izsh`` Activate a zsh REPL
-  ``:Ipython`` Activate a python REPL
-  ``:Iclojure`` Activate a clojure REPL
-  ``:Iapl`` Activate an apl REPL
-  ``:IR`` Activate an R REPL
-  ``:Isgpt`` Activate an sgpt REPL
-  ``:Igpt`` Activate an gpt-command-line REPL
-  ``:Iterm`` Activate default REPL for this filetype

Sending commands
~~~~~~~~~~~~~~~~

``CTRL-S`` sends lines of text to the interpreter in a mode-dependent manner:

In Normal mode, ``CTRL-S`` sends the line currently occupied by the cursor to the
REPL.

In Insert mode, ``CTRL-S`` sends the line currently being edited, and then
returns to insert mode at the same location.

In Visual mode, ``CTRL-S`` sends the current selection to the REPL.

``ALT-S`` sends all lines from the start to the current line.

Retrieving command outputs
~~~~~~~~~~~~~~~~~~~~~~~~~~

CTRL-Y retrieves the output of the last command sent to the REPL. This is
implemented for the following REPLs: ``:Iipython``, ``:Isgpt``, ``:Igpt``, 
``:Iaichat``, and ``:Izsh``

In ``Normal-mode``, CTRL-Y retrieves the output of the last command sent to the
REPL and places it in the current buffer.

In ``Insert-mode``, CTRL-Y retrieves the output of the last command sent to the
REPL and places it in the current buffer, and then returns to insert mode
after the output.

In ``Visual-mode``, CTRL-Y deletes the selection and replaces it with the
output of the last command.

Connecting to an existing REPL
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``:Iconn [{pane_name}]`` connects current buffer to REPL in tmux pane 
``{pane_name}``. You can connect any number of buffers to one REPL. 
``{pane_name}`` can be omitted if there is only one REPL. Tab completion
is available to show all available pane names.

``]v`` and ``[v`` can be used to cycle between connected buffers in the style of 
`unimpaired <https://github.com/tpope/vim-unimpaired>`__.

Common issues
-------------

Bracketed paste
~~~~~~~~~~~~~~~

If you see strange symbols like ``^[[200~`` when sending lines to your new
interpreter, you may need to disable bracketed paste for that REPL. The plugin
automatically enables bracketed paste for REPLs in the 
``g:vimteractive_bracketed_paste`` list. To disable it for a specific REPL,
remove it from the list:

.. code:: vim

	" Remove 'python' from bracketed paste list
	let g:vimteractive_bracketed_paste = filter(g:vimteractive_bracketed_paste, 'v:val != "python"')


Options
-------
These options can be put in your ``.vimrc``, or run manually as desired:

.. code:: vim

    " Choose backend: 'tmux' (default) or 'vimterminal'
    let g:vimteractive_backend = 'vimterminal'  " Use vim's native terminal
    
    " Backend-specific options
    let g:vimteractive_terminal = 'xterm -e'     " Terminal for tmux backend only
    
    " General options
    let g:vimteractive_default_repl = ''         " Default REPL (empty = filetype detection)
    let g:vimteractive_extract_markdown_code_blocks = 1  " Extract code from markdown responses
    let g:vimteractive_zsh_prompt = '^\$'       " Regex for zsh prompt detection
    let g:vimteractive_zsh_prompt_multiline = 1  " Lines to skip for multiline prompts

Extending functionality
-----------------------

This project is very much in an beta phase, so if you have any issues
that arise on your system, feel free to `leave an issue <https://github.com/williamjameshandley/vimteractive/issues/new>`__ or create a `fork and pull
request <https://gist.github.com/Chaser324/ce0505fbed06b947d962>`__ with
your proposed changes

You can easily add your interpreter to Vimteractive, using the following code
in your ``.vimrc``:

.. code:: vim

    " Mapping from Vimterpreter command to shell command
    " This would give you :Iasyncpython command
    let g:vimteractive_commands = {
        \ 'asyncpython': ['python3', '-m', 'asyncio']
        \ }

    " The g:vimteractive_bracketed_paste variable is a list of REPLs
    " that support bracketed paste mode. Add or remove REPLs as needed:
    let g:vimteractive_bracketed_paste += ['asyncpython']

    " If you want to set interpreter as default (used by :Iterm),
    " map filetype to it. If not set, :Iterm will use interpreter
    " named same with filetype.
    let g:vimteractive_default_repls = {
        \ 'python': 'asyncpython'
        \ }

    " Note: The g:vimteractive_slow_prompt feature mentioned in some
    " documentation is not currently implemented in this branch.


Similar projects
----------------

-  `vim-ipython <https://github.com/ivanov/vim-ipython>`__
-  `vim-notebook <https://github.com/baruchel/vim-notebook>`__
-  `conque <https://code.google.com/archive/p/conque/>`__
-  `vim-slime <https://github.com/jpalardy/vim-slime>`__
-  `tslime_ipython <https://github.com/eldridgejm/tslime_ipython>`__
-  `vipy <https://github.com/johndgiese/vipy>`__

.. |example_usage| image:: https://raw.githubusercontent.com/williamjameshandley/vimteractive/master/images/example_usage.gif
