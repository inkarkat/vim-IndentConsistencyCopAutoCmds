" IndentConsistencyCopAutoCmds.vim: autocmds for IndentConsistencyCop.vim
"
" DESCRIPTION:
"   The autocmds in this script automatically trigger the IndentConsistencyCop
"   for certain, configurable filetypes (such as c, cpp, html, xml, ... which
"   typically contain lots of indented lines) once when you load the file in
"   Vim, and (optionally) also on every write of the buffer. The entire buffer
"   will be checked for inconsistent indentation, and you will receive a report
"   on its findings. With this automatic background check, you'll become aware
"   of indentation problems before you start editing and in case you
"   accidentally introduce an inconsistency. 
"
" USAGE:
"   Triggering happens automatically; of course, you can still execute the
"   :IndentConsistencyCop ex command to re-check the buffer after changes. 
"
"   For very large files, the check may take a couple of seconds. You can abort
"   the script run with CTRL-C, like any other Vim command. 
"
"   You can disable/re-enable the autocommands with 
"   :IndentConsistencyCopAutoCmdsOff and :IndentConsistencyCopAutoCmdsOff,
"   respectively. 
"
" INSTALLATION:
"   Put the script into your user or system Vim plugin directory (e.g.
"   ~/.vim/plugin). 
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - Requires IndentConsistencyCop.vim (vimscript #1690). 
"
" CONFIGURATION:
"					      *g:indentconsistencycop_filetypes*
"   If you don't like the default filetypes that are inspected, define your own
"   comma-separated list of filetypes in g:indentconsistencycop_filetypes and
"   put this setting into your vimrc file (see :help vimrc). 
"
"					*g:indentconsistencycop_CheckAfterWrite*
"   Turn off the IndentConsistencyCop run after each write via >
"	let g:indentconsistencycop_CheckAfterWrite = 0
"   The IndentConsistencyCop will only run once after loading a file. 
"
"	       *g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck*
"   To avoid blocking the user whenever a large buffer is written, the
"   IndentConsistencyCop is only scheduled to run on the next 'CursorHold'
"   event in case the buffer contains many lines. The threshold can be adjusted
"   (to the system's performance and personal level of patience): >
"	let g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck = 1000
"
" Copyright: (C) 2006-2010 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.20.007	30-Dec-2010	BUG: :IndentConsistencyCopAutoCmdsOff only works
"				for future buffers, but does not turn off the
"				cop in existing buffers. Must remove all
"				buffer-local autocmds, too. 
"   1.20.006	16-Sep-2009	BUG: The same buffer-local autocmd could be
"				created multiple times when the filetype is set
"				repeatedly. 
"   1.20.005	10-Sep-2009	BUG: By clearing the entire
"				"IndentConsistencyCopBufferCmds" augroup,
"				pending autocmds for other buffers were deleted
"				by an autocmd run in the current buffer. Now
"				deleting only the buffer-local autocmds for the
"				{event}s that fired. 
"				Factored out s:InstallAutoCmd(). 
"				ENH: Added "check after write" feature, which
"				triggers the IndentConsistencyCop whenever the
"				buffer is written. To avoid blocking the user,
"				in large buffers the check is only scheduled to
"				run on the next 'CursorHold' event. 
"   1.10.004	13-Jun-2008	Added -bar to all commands that do not take any
"				arguments, so that these can be chained together. 
"   1.10.003	21-Feb-2008	Avoiding multiple invocations of the
"				IndentConsistencyCop when reloading or switching
"				buffers. Now there's only one check per file and
"				Vim session. 
"   1.00.002	25-Nov-2006	Added commands :IndentConsistencyCopAutoCmdsOn
"				and :IndentConsistencyCopAutoCmdsOff
"				to re-enable/disable autocommands. 
"	0.01	16-Oct-2006	file creation

" Avoid installing twice or when in unsupported version. 
if exists("loaded_indentconsistencycopautocmds") || (v:version < 700)
    finish
endif
let loaded_indentconsistencycopautocmds = 1

"- configuration --------------------------------------------------------------
if ! exists('g:indentconsistencycop_filetypes')
    let g:indentconsistencycop_filetypes = 'ant,c,cpp,cs,csh,css,dosbatch,html,java,javascript,jsp,lisp,pascal,perl,php,python,ruby,scheme,sh,sql,tcsh,vb,vbs,vim,wsh,xhtml,xml,xsd,xslt,zsh'
endif
if ! exists('g:indentconsistencycop_CheckAfterWrite')
    let g:indentconsistencycop_CheckAfterWrite = 1
endif
if ! exists('g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck')
    let g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck = 1000
endif

"- functions ------------------------------------------------------------------
function! s:StartCopOnce()
    " The straightforward way to ensure that the Cop is called only once per
    " file is to hook into the BufRead event. We cannot do this, because at that
    " point modelines haven't been set yet and the filetype hasn't been
    " determined. 
    " Although the BufWinEnter hook removes itself after execution, it may still
    " be triggered multiple times in a Vim session, e.g. when switching buffers
    " (alternate file, or :next, ...) or when a plugin (like FencView) reloads
    " the buffer with changed settings.
    " Thus, we set a buffer-local flag. This ensures that the Cop is really only
    " called once per file in a Vim session, even when the buffer is reloaded
    " via :e!. (Only :bd and :e <file> will create a fresh buffer and cause a
    " new Cop run.) 
    if ! exists('b:indentconsistencycop_is_checked')
	let b:indentconsistencycop_is_checked = 1
	execute 'IndentConsistencyCop'
    endif
endfunction
function! s:StartCopAfterWrite()
    " As long as the IndentConsistencyCop can finish its job without noticeable
    " delay (which we'll estimate based on the number of lines in the current
    " buffer), invoke it directly after the buffer write. 
    " In a large buffer, we'll only schedule the IndentConsistencyCop run once
    " on the next 'CursorHold' event, hoping that the user is then away, busy
    " reading, or just looking out of the window... and won't mind the
    " inspection. (He can always abort via CTRL-C.) 
    if line('$') <= g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck
	let b:indentconsistencycop_is_checked = 1
	execute 'IndentConsistencyCop'
    else
	unlet! b:indentconsistencycop_is_checked
	call s:InstallAutoCmd(['CursorHold'], 1)
    endif
endfunction
function! s:InstallAutoCmd( events, isStartOnce )
    augroup IndentConsistencyCopBufferCmds
	let l:autocmd = 'IndentConsistencyCopBufferCmds ' . join(a:events, ',') . ' <buffer>'
	execute 'autocmd!' l:autocmd
	if a:isStartOnce
	    execute 'autocmd' l:autocmd 'call <SID>StartCopOnce() |  autocmd!' l:autocmd
	else
	    execute 'autocmd' l:autocmd 'call <SID>StartCopAfterWrite()'
	endif
    augroup END
endfunction
function! s:StartCopBasedOnFiletype( filetype )
    let l:activeFiletypes = split( g:indentconsistencycop_filetypes, ', *' )
    if count( l:activeFiletypes, a:filetype ) > 0
	" Modelines have not been processed yet, but we need them because they
	" very likely change the buffer indent settings. So we set up a second
	" autocmd BufWinEnter (which is processed after the modelines), that
	" will trigger the IndentConsistencyCop and remove itself (i.e. a "run
	" once" autocmd). 
	" When a buffer is loaded, the FileType event will fire before the
	" BufWinEnter event, so that the IndentConsistencyCop is triggered. 
	" When the filetype changes in an existing buffer, the BufWinEnter
	" event is not fired. We use the CursorHold event to trigger the
	" IndentConsistencyCop when the user pauses for a brief period.
	" (There's no better event for that.)
	call s:InstallAutoCmd(['BufWinEnter', 'CursorHold'], 1)
	if g:indentconsistencycop_CheckAfterWrite
	    call s:InstallAutoCmd(['BufWritePost'], 0)
	endif
"****D execute 'autocmd IndentConsistencyCopBufferCmds' | call confirm("Active IndentConsistencyCopBufferCmds")
    endif
endfunction

function! s:IndentConsistencyCopAutoCmds(isOn)
    augroup IndentConsistencyCopAutoCmds
	autocmd!
	if a:isOn
	    autocmd FileType * call <SID>StartCopBasedOnFiletype( expand('<amatch>') )
	endif
    augroup END

    if ! a:isOn
	autocmd! IndentConsistencyCopBufferCmds
    endif
endfunction

" Enable the autocommands. 
call s:IndentConsistencyCopAutoCmds(1)

"- commands -------------------------------------------------------------------
command! -bar -nargs=0 IndentConsistencyCopAutoCmdsOn call <SID>IndentConsistencyCopAutoCmds(1)
command! -bar -nargs=0 IndentConsistencyCopAutoCmdsOff call <SID>IndentConsistencyCopAutoCmds(0)

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
