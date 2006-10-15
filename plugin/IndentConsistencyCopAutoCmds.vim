" IndentConsistencyCopAutoCmds.vim: autocmds for IndentConsistencyCop.vim
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	0.01	16-Oct-2006	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_indentconsistencycopautocmds") || (v:version < 700)
    finish
endif
let loaded_indentconsistencycopautocmds = 1

function! s:StartCopBasedOnFiletype()
    IndentConsistencyCop
endfunction

augroup IndentConsistencyCop
    autocmd!
    autocmd BufReadPost * call <SID>StartCopBasedOnFiletype()
augroup END

