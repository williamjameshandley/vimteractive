" Import the module
python << EOF
import vim
import sys
vimteractive_path = vim.eval("expand('<sfile>:h')")
sys.path.append(vimteractive_path)
from vimteractive import *
EOF

" Setup plugin mappings for the most common ways to interact with ipython.
noremap  <Plug>(IRunLine)  :python server.runline()<CR>
noremap  <Plug>(IRunLines) :python server.runlines()<CR>

noremap  <buffer> <silent> <C-s> <Plug>(IRunLine)
inoremap <buffer> <silent> <C-s> <C-o><Plug>(IRunLine)
xnoremap <buffer> <silent> <C-S> <Plug>(IRunLines)

" Setup plugin mappings for the most common ways to interact with ipython.
command!  Iipython :py server=IPython()
command!  Ipython :py server=Python()
command!  Ibash :py server=Bash()
command!  Imaple :py server=Maple()
