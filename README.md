INDENT CONSISTENCY COP AUTO CMDS   
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

The autocmds in this script automatically trigger the IndentConsistencyCop for
certain, configurable filetypes (such as c, cpp, html, xml, ... which
typically contain lots of indented lines) once when you load the file in Vim,
and/or on every write of the buffer.
The entire buffer will be checked for inconsistent indentation, and you will
receive a report on its findings. With this automatic background check, you'll
become aware of indentation problems before you start editing and/or when
writing. This prevents you from accidentally introducing an inconsistency with
your edits.

USAGE
------------------------------------------------------------------------------

    Triggering happens automatically; by default, when a buffer is opened for the
    first time, both the compatibility of the file's indent with the buffer
    settings and its internal consistency are checked; on each subsequent save,
    the latter check is repeated.
    Of course, you can still manually execute the :IndentConsistencyCop command
    to re-check the buffer at any time.

    For very large files, the check may take a couple of seconds. You can abort
    the script run with CTRL-C, like any other Vim command.

    If you chose to "Ignore" any inconsistent indents in the IndentConsistencyCop
    report, further automatic invocations on buffer writes are suspended. It is
    assumed that you don't bother for this particular file. You can re-enable
    automatic invocations by manually invoking :IndentConsistencyCop once and then
    choosing an option other than "Ignore".

    :IndentConsistencyCopAutoCmdsOff
    :IndentConsistencyCopAutoCmdsOn
                            Disable / re-enable the autocommands. This affects all
                            existing buffers as well as any newly opened files.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-IndentConsistencyCopAutoCmds
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim IndentConsistencyCopAutoCmds*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the IndentConsistencyCop.vim plugin ([vimscript #1690](http://www.vim.org/scripts/script.php?script_id=1690)).
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.010 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

If you don't like the default filetypes that are inspected, define your own
comma-separated list of filetypes or add to the existing ones:

    let g:indentconsistencycop_filetypes = 'c,cpp,java,javascript,perl,php,python,ruby,sh,tcsh,vim'
    let g:indentconsistencycop_filetypes .= ',perl6'

To exclude some files even though they have one of the filetypes in
g:indentconsistencycop\_filetypes, you can define a List of expressions or
Funcrefs that are evaluated; if one returns 1, the buffer will be skipped. The
current filename can be obtained from <afile>.

    let g:IndentConsistencyCopAutoCmds_ExclusionPredicates =
    ['expand("<afile>:p" =~# "/tmp"', function('ExcludeScratchFiles')]

By default, scratch buffers from the fugitive.vim plugin (that show immutable
changes) are excluded.

Turn off the IndentConsistencyCop run when a buffer is loaded via

    let g:indentconsistencycop_CheckOnLoad = 0

This avoids alerts when just viewing files (especially the multiple
confirmations when opening many files or restoring a saved session; though one
could also temporarily disable the autocmds in that case via
:IndentConsistencyCopAutoCmdsOff). On the other hand, it comes with the risk
of introducing indent inconsistencies until the first write (when the buffer's
indent settings do not match the file's).

Turn off the IndentConsistencyCop run after each write via

    let g:indentconsistencycop_CheckAfterWrite = 0

The IndentConsistencyCop will only run once after loading a file.

To avoid blocking the user whenever a large buffer is written, the
IndentConsistencyCop is only scheduled to run on the next 'CursorHold' event
in case the buffer contains many lines. The threshold can be adjusted (to the
system's performance and personal level of patience):

    let g:indentconsistencycop_CheckAfterWriteMaxLinesForImmediateCheck = 1000

By default, both indent consistency and consistency with the buffer settings
will be checked when a file is loaded.
Only indent consistency is checked after a write of the buffer. The user
already was alerted to inconsistent buffer settings when the file was loaded
and editing the file did't change anything in that regard.
If you don't want the check for consistency with the buffer settings, set

    let g:indentconsistencycop_AutoRunCmd = 'IndentRangeConsistencyCop'

INTEGRATION
------------------------------------------------------------------------------

If you want to disable the automatic checks for certain buffers only, without
turning off the IndentConsistencyCop completely through
:IndentConsistencyCopAutoCmdsOff or for certain filetypes by adapting
g:indentconsistencycop\_filetypes, set a buffer variable, e.g. via one of the
local vimrc plugins:

    :let b:indentconsistencycop_SkipChecks = 1

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-IndentConsistencyCopAutoCmds/issues or email
(address below).

HISTORY
------------------------------------------------------------------------------

##### 1.47    RELEASEME
- Make the plugin dependency to IndentConsistencyCop.vim more robust by
  attempting to load the plugin if it's not yet available during plugin load.
- Check for existence of g:indentconsistencycop\_AutoRunCmd and issue error if
  the command does not exist on :IndentConsistencyCopAutoCmdsOn.
- ENH: Allow to excluded certain files within supported filetypes via new
  g:IndentConsistencyCopAutoCmds\_ExclusionPredicates configuration.
  By default, exclude scratch buffers from fugitive.vim

##### 1.46    23-Dec-2017
- Add yaml filetype to g:indentconsistencycop\_filetypes.

##### 1.45    09-Feb-2015
- Add several more filetypes to g:indentconsistencycop\_filetypes.
- FIX: Install of continuous buffer autocmd never worked because of missing
  <buffer> target.
- Allow buffer-local config for indentconsistencycop\_CheckOnLoad,
  indentconsistencycop\_CheckAfterWrite,
  indentconsistencycop\_CheckAfterWriteMaxLinesForImmediateCheck.
- Add dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)). __You need to separately
  install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.010 (or higher)!__

##### 1.42    27-Feb-2013
- When the persistence of the buffer fails (e.g. with "E212: Cannot open for
writing"), don't run the cop; its messages may obscure the write error.

##### 1.41    23-Oct-2012 (unreleased)
- ENH: Allow skipping automatic checks for certain buffers (i.e. not globally
disabling the checks via :IndentConsistencyCopAutoCmdsOff), configured for
example by a directory-local vimrc, via new b:indentconsistencycop\_SkipChecks
setting.

##### 1.40    26-Sep-2012
- ENH: Allow check only on buffer writes by clearing new config flag
g:indentconsistencycop\_CheckOnLoad. This comes with the risk of introducing
indent inconsistencies until the first write, but on the other hand avoids
alerts when just viewing file(s) (especially when restoring a saved session
with multiple files; though one could also temporarily disable the autocmds in
that case). Suggested by Marcelo Montu.

##### 1.32    07-Mar-2012
- Avoid "E464: Ambiguous use of user-defined command: IndentConsistencyCop" when
loading of the IndentConsistencyCop has been suppressed via --cmd "let
g:loaded\_indentconsistencycop = 1" by checking for the existence of the
command in the definition of the autocmds. Do not define the commands when the
IndentConsistencyCop command has not been defined.

##### 1.31    08-Jan-2011
- BUG: "E216: No such group or event: IndentConsistencyCopBufferCmds" on
:IndentConsistencyCopAutoCmdsOff.

##### 1.30    31-Dec-2010
- ENH: Do not invoke the IndentConsistencyCop if the user chose to ignore the
  cop's report of an inconsistency. Requires
  b:indentconsistencycop\_result.isIgnore flag introduced in
  IndentConsistencyCop 1.21.
- ENH: Only check indent consistency after a write of the buffer, not
  consistency with buffer settings.
- BUG: :IndentConsistencyCopAutoCmdsOff only works for future buffers, but
  does not turn off the cop in existing buffers. Must remove all buffer-local
  autocmds, too.
- Allowing to just run indent consistency check, not buffer settings at all
  times via g:indentconsistencycop\_AutoRunCmd.
- Added separate help file and packaging the plugin as a vimball.

##### 1.20    10-Sep-2009 (incomplete, never released)
- ENH: Added "check after write" feature, which triggers the
  IndentConsistencyCop whenever the buffer is written. To avoid blocking the
  user, in large buffers the check is only scheduled to run on the next
  'CursorHold' event.
- BUG: The same buffer-local autocmd could be created multiple times when the
  filetype is set repeatedly.
- BUG: By clearing the entire IndentConsistencyCopBufferCmds augroup, pending
  autocmds for other buffers were deleted by an autocmd run in the current
  buffer. Now deleting only the buffer-local autocmds for the events that
  fired.

##### 1.10    23-Jun-2008
- Minor change: Added -bar to all commands that do not take any arguments, so
that these can be chained together.

##### 1.10    22-Feb-2008
- Avoiding multiple invocations of the IndentConsistencyCop when reloading or
  switching buffers. Now there's only one check per file and Vim session.
- Added commands :IndentConsistencyCopAutoCmdsOn and
  :IndentConsistencyCopAutoCmdsOff to re-enable/disable autocommands.

##### 1.00    24-Oct-2006
- First published version.

##### 0.01    16-Oct-2006
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2006-2018 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat <ingo@karkat.de>
