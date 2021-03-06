" IndentConsistencyCopAutoCmds.vim: autocmds for IndentConsistencyCop
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - IndentConsistencyCop.vim plugin
"   - ingo-library.vim plugin
"
" Copyright: (C) 2006-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported version.
if exists('g:loaded_indentconsistencycopautocmds') || (v:version < 700)
    finish
endif
if ! exists('g:loaded_indentconsistencycop')
    runtime plugin/IndentConsistencyCop.vim
endif
if ! exists('g:loaded_indentconsistencycop')
    echomsg 'IndentConsistencyCopAutoCmds: You need to install the IndentConsistencyCop.vim plugin.'
    finish
endif
let g:loaded_indentconsistencycopautocmds = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration --------------------------------------------------------------

if ! exists('g:indentconsistencycop_filetypes')
    let g:indentconsistencycop_filetypes = 'actionscript,ant,atom,c,cpp,cs,csh,css,dosbatch,groovy,gsp,html,java,javascript,json,jsp,lisp,mxml,pascal,perl,php,ps1,python,ruby,scheme,sh,sql,tcsh,vb,vbs,vim,wsh,xhtml,xml,xsd,xslt,yaml,zsh'
endif
if ! exists('g:IndentConsistencyCopAutoCmds_ExclusionPredicates')
    if v:version < 702 | runtime autoload/IndentConsistencyCopAutoCmds/Excludes.vim | endif  " The Funcref doesn't trigger the autoload in older Vim versions.
    let g:IndentConsistencyCopAutoCmds_ExclusionPredicates = [function('IndentConsistencyCopAutoCmds#Excludes#FugitiveBuffers')]
endif
if ! exists('g:indentconsistencycop_CheckOnLoad')
    let g:indentconsistencycop_CheckOnLoad = 1
endif
if ! exists('g:indentconsistencycop_CheckAfterWrite')
    let g:indentconsistencycop_CheckAfterWrite = 1
endif
if ! exists('g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck')
    let g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck = 1000
endif
if ! exists('g:indentconsistencycop_AutoRunCmd')
    let g:indentconsistencycop_AutoRunCmd = 'IndentConsistencyCop'
endif


"- functions ------------------------------------------------------------------

function! s:GetFilespec()
    return ingo#fs#path#Canonicalize(expand('%:p'))
endfunction
function! IndentConsistencyCopAutoCmds#IgnoreForever()
    if empty(bufname(''))
	call ingo#msg#ErrorMsg('Cannot add unnamed buffer to blacklist')
	return 0
    endif

    call ingo#plugin#persistence#Add('INDENTCONSISTENCYCOPAUTOCMDS_BLACKLIST', s:GetFilespec(), 1)
endfunction
function! s:IsContainedInBlacklist()
    return has_key(ingo#plugin#persistence#Load('INDENTCONSISTENCYCOPAUTOCMDS_BLACKLIST', {}), s:GetFilespec())
endfunction


function! s:IsDisabledHere()
    return (exists('b:indentconsistencycop_SkipChecks') && b:indentconsistencycop_SkipChecks) ||
    \   s:IsContainedInBlacklist()
endfunction
function! s:StartCopOnce( copCommand )
    if s:IsDisabledHere()
	" The user explicitly disabled checking for this buffer.
	return
    endif

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
	execute a:copCommand
	let b:indentconsistencycop_is_checked = 1
    endif
endfunction
function! s:StartCopAfterWrite( copCommand, event )
    if a:event ==# 'BufWritePost' && &l:modified
	" When the persistence of the buffer fails (e.g. with "E212: Cannot open
	" for writing"), don't run the cop; its messages may obscure the write
	" error.
	return
    endif

    if s:IsDisabledHere()
	" The user explicitly disabled checking for this buffer.
	return
    endif

    if exists('b:indentconsistencycop_result') && get(b:indentconsistencycop_result, 'isIgnore', 0)
	" Do not invoke the IndentConsistencyCop if the user chose to ignore the
	" cop's report of an inconsistency.
	return
    endif

    " As long as the IndentConsistencyCop can finish its job without noticeable
    " delay (which we'll estimate based on the number of lines in the current
    " buffer), invoke it directly after the buffer write.
    " In a large buffer, we'll only schedule the IndentConsistencyCop run once
    " on the next 'CursorHold' event, hoping that the user is then away, busy
    " reading, or just looking out of the window... and won't mind the
    " inspection. (He can always abort via CTRL-C.)
    if line('$') <= ingo#plugin#setting#GetBufferLocal('indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck')
	execute a:copCommand
	let b:indentconsistencycop_is_checked = 1
    else
	unlet! b:indentconsistencycop_is_checked
	call s:InstallAutoCmd(a:copCommand, ['CursorHold'], 1)
    endif
endfunction

function! s:IsExcludedByPredicate()
    for l:Predicate in g:IndentConsistencyCopAutoCmds_ExclusionPredicates
	if ingo#actions#EvaluateOrFunc(l:Predicate)
	    return 1
	endif
    endfor
    return 0
endfunction
function! s:InstallAutoCmd( copCommand, events, isStartOnce )
    augroup IndentConsistencyCopBufferCmds
	if a:isStartOnce
	    let l:autocmd = 'autocmd! IndentConsistencyCopBufferCmds ' . join(a:events, ',') . ' <buffer>'
	    execute l:autocmd 'call <SID>StartCopOnce(' . string(a:copCommand) . ') |' l:autocmd
	else
	    for l:event in a:events
		execute printf('autocmd! IndentConsistencyCopBufferCmds %s <buffer> call <SID>StartCopAfterWrite(%s, %s)', l:event, string(a:copCommand), string(l:event))
	    endfor
	endif
    augroup END
endfunction
function! s:StartCopBasedOnFiletype( filetype )
    let l:activeFiletypes = split( g:indentconsistencycop_filetypes, ', *' )
    if index(l:activeFiletypes, a:filetype) == -1 || s:IsExcludedByPredicate()
	return
    endif

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

    let l:isCheckOnLoad = ingo#plugin#setting#GetBufferLocal('indentconsistencycop_CheckOnLoad')
    if l:isCheckOnLoad
	" Check both indent consistency and consistency with buffer indent
	" settings when a file is loaded.
	call s:InstallAutoCmd(g:indentconsistencycop_AutoRunCmd, ['BufWinEnter', 'CursorHold'], 1)
    endif
    if ingo#plugin#setting#GetBufferLocal('indentconsistencycop_CheckAfterWrite')
	if l:isCheckOnLoad
	    " Only check indent consistency after a write of the buffer. The
	    " user already was alerted to inconsistent buffer settings when
	    " the file was loaded; editing the file did't change anything in
	    " that regard, so we'd better not bother the user with this
	    " information repeatedly.
	    let l:cmd = 'IndentRangeConsistencyCop'
	else
	    " For the first write, perform the full check, then only check
	    " indent consistency on subsequent writes; it's enough to alert
	    " the user once.
	    let l:cmd = 'if exists("b:indentconsistencycop_is_checked") | IndentRangeConsistencyCop | else | ' . g:indentconsistencycop_AutoRunCmd . ' | endif'
	endif

	call s:InstallAutoCmd(l:cmd, ['BufWritePost'], 0)
    endif
"****D execute 'autocmd IndentConsistencyCopBufferCmds' | call confirm("Active IndentConsistencyCopBufferCmds")
endfunction
function! s:ExistsIndentConsistencyCop()
    return exists(':' . matchstr(g:indentconsistencycop_AutoRunCmd, '^\s*\S\+')) == 2
endfunction

function! s:IndentConsistencyCopAutoCmds( isOn )
    if a:isOn && ! s:ExistsIndentConsistencyCop()
	call ingo#err#Set(printf('The IndentConsistencyCop command (%s) is not available', string(g:indentconsistencycop_AutoRunCmd)))
	return 0
    endif

    let l:isEnable = a:isOn
    augroup IndentConsistencyCopAutoCmds
	autocmd!
	if l:isEnable
	    autocmd FileType * call <SID>StartCopBasedOnFiletype( expand('<amatch>') )
	endif
    augroup END

    if ! l:isEnable
	silent! autocmd! IndentConsistencyCopBufferCmds
    endif
    return 1
endfunction

" Enable the autocommands; suppress error about non-existing command during plugin load.
call s:IndentConsistencyCopAutoCmds(1)


"- integration -----------------------------------------------------------------

if ! exists('g:IndentConsistencyCop_MenuExtensions')
    let g:IndentConsistencyCop_MenuExtensions = {}
endif
if ingo#plugin#persistence#CanPersist()
    let g:IndentConsistencyCop_MenuExtensions['Ignore forever'] = {
    \   'priority': 100,
    \   'choice': 'Ignore &forever',
    \   'Action': function('IndentConsistencyCopAutoCmds#IgnoreForever'),
    \}
endif


"- commands -------------------------------------------------------------------

command! -bar IndentConsistencyCopAutoCmdsOn  if ! <SID>IndentConsistencyCopAutoCmds(1) | echoerr ingo#err#Get() | endif
command! -bar IndentConsistencyCopAutoCmdsOff if ! <SID>IndentConsistencyCopAutoCmds(0) | echoerr ingo#err#Get() | endif

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
