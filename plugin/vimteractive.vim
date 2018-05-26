" Import the module
python << EOF
import vim
import sys
vimteractive_path = vim.eval("expand('<sfile>:h')")
sys.path.append(vimteractive_path)
from vimteractive import *
EOF

" Setup plugin mappings for the most common ways to interact with ipython.
noremap  <C-s> :python server.runline()<CR> 
inoremap <C-s> :python server.runline()<CR>  
xnoremap <C-S> :python server.runlines()<CR>

" Setup plugin mappings for the most common ways to interact with ipython.
command!  Iipython :py server=IPython()
command!  Ipython :py server=Python()
command!  Ibash :py server=Bash()
command!  Imaple :py server=Maple()
