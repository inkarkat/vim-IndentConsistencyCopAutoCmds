" IndentConsistencyCopAutoCmds/Excludes.vim: Default exclusion predicates.
"
" DEPENDENCIES:
"
" Copyright: (C) 2018 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

function! IndentConsistencyCopAutoCmds#Excludes#FugitiveBuffers()
    return expand('<afile>:h') =~# '^fugitive://'
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
