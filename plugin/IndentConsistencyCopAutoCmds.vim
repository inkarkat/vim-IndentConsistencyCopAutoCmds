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

if ! exists('g:indentconsistencycop_filetypes')
    let g:indentconsistencycop_filetypes = 'ant,c,cpp,cs,csh,css,dosbatch,html,java,javascript,jsp,lisp,pascal,perl,php,python,ruby,scheme,sh,sql,tcsh,vb,vim,xhtml,xml,xsd,xslt,zsh'
endif

function! s:StartCopBasedOnFiletype( filetype )
    let l:activeFiletypes = split( g:indentconsistencycop_filetypes, ',' )
    if count( l:activeFiletypes, a:filetype ) > 0
	" modelines have not been processed yet, but we need them because they
	" very likely change the buffer indent settings. So we set up a second
	" autocmd CursorHold, that will trigger the IndentConsistencyCop and
	" remove itself (i.e. a "run once" autocmd). 
	augroup IndentConsistencyCopBuffer
	    autocmd!
	    autocmd CursorHold <buffer>	echomsg 'TODO: inspecting filetype' |  autocmd! IndentConsistencyCopBuffer * <buffer>
	augroup END
    endif
endfunction

augroup IndentConsistencyCop
    autocmd!
    autocmd FileType * call <SID>StartCopBasedOnFiletype( expand('<amatch>') )
augroup END

