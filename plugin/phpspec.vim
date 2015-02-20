if exists('g:loaded_phpspec') && g:loaded_phpspec
	finish
endif

let g:loaded_phpspec = 1

if ! exists('g:phpspec_executable')
	if filereadable('./bin/phpspec')
		let g:phpspec_executable = './bin/phpspec'
	elseif filereadable('./vendor/bin/phpspec')
		let g:phpspec_executable = './vendor/bin/phpspec'
	elseif filereadable('./vendor/phpspec/phpspec/bin/phpspec')
		let g:phpspec_executable = './vendor/phpspec/phpspec/bin/phpspec'
	else
		let g:phpspec_executable = 'phpspec'
	endif
endif

if ! exists('g:phpspec')
	let g:phpspec = {}
endif

if (!exists('g:phpspec_default_mapping') || g:phpspec_default_mapping)
	map <leader>spr :PhpSpecRun<CR>
	map <leader>spc :PhpSpecRunCurrent<CR>
	map <leader>sps :PhpSpecSwitch<CR>
endif

command! -nargs=0 PhpSpecRun          call phpspec#run()
command! -nargs=0 PhpSpecRunCurrent   call phpspec#run_current()
command! -nargs=1 PhpSpecDesc         call phpspec#describe(<f-args>)
command! -nargs=0 PhpSpecSwitch       call phpspec#switch()

function s:load_phpspec_yml(yml_path)
python << EOF
import yaml, os, vim

yml_path = vim.eval('a:yml_path')
f = open(yml_path);
phpspec = yaml.load(f);
vim.command('let g:phpspec["%s"] = %s' %(yml_path, repr(phpspec)));
f.close();
EOF
endfunction

function s:run(cmd)
	if exists('*vimproc#pgroup_open')
		let proc = vimproc#pgroup_open(a:cmd, 0, 2)
		call proc.stdin.close()

		let lines = []
		while ! proc.stdout.eof || ! proc.stderr.eof
			try
				if ! proc.stdout.eof
					call add(lines, proc.stdout.read_line())
				endif

				if ! proc.stderr.eof
					call add(lines, proc.stderr.read_line())
				endif
			catch
				echom v:throwpoint
			endtry
		endwhile
		call proc.stdout.close()
		call proc.stderr.close()
		call proc.kill(9)
		call proc.waitpid()
	else
		let lines = split(system(a:cmd), '\n')
	endif

	botright new
	setlocal winheight=15
	setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
	call append(line('$'), lines)
endfunction

function phpspec#switch()
	let file_class = substitute(phpspec#get_class_name(), '\\', '/', 'g')
	let file_match = phpspec#match(getcwd(), file_class)

	if strlen(file_match) == 0
		if file_class =~ 'Spec$'
			echoerr 'Unable to find matching class for '.file_class
		else
			if 1 == confirm('No spec yet, would you like to create it?', "&Yes\n&No")
				call phpspec#describe(file_class)
			endif
		endif
	else
		if bufexists(file_match)
			execute(printf('buffer %s', file_match))
		elseif filereadable(file_match)
			execute(printf('edit %s', file_match))
		endif
	endif
endfunction

function phpspec#describe(file_class)
	let cmd = g:phpspec_executable.' desc '.file_class.' -q'
	if exists('*vimproc#system')
		call vimproc#system(cmd)
	else
		call system(cmd)
	endif
	call phpspec#switch()
endfunction

function phpspec#run(...)
	let cmd = g:phpspec_executable.' run --no-ansi'
	if a:0 > 0
		let cmd .= ' '.a:1
	endif
	call s:run(cmd)
endfunction

function phpspec#run_current()
	let cmd = g:phpspec_executable.' run --no-ansi '.expand('%')
	call s:run(cmd)
endfunction

function phpspec#match(directory, file_class)
	" Load phpspec's config, and use cache if available
	let phpspec_yml = a:directory.'/phpspec.yml'
	if ! has_key(g:phpspec, phpspec_yml)
		if filereadable(phpspec_yml)
			call s:load_phpspec_yml(phpspec_yml)
		else
			echoerr 'Cannot find phpspec.yml'
			return
		endif
	endif

	let is_spec = a:file_class =~ 'Spec$'
	let file_class = substitute(a:file_class, 'Spec$', '', '')

	let file_match = ''
	let suites = items(g:phpspec[phpspec_yml]['suites'])
	for [suite, settings] in suites
		if type(settings) == 1
			let src_path  = 'src'
			let spec_path = 'spec'
			let namespace = settings
		else
			let src_path  = get(settings, 'src_path', 'src')
			let spec_path = get(settings, 'spec_path', 'spec').'/spec'
			let namespace = get(settings, 'namespace', '')
		endif
		let namespace = substitute(namespace, '\\', '/', '')

		if is_spec
			if stridx(file_class, 'spec/'.namespace.'/') == 0
				let candidate = src_path.'/'
					\.substitute(file_class, escape('spec/'.namespace.'/', '\/'), '', 'g')
					\.'.php'
				if filereadable(candidate)
					let file_match = candidate
					break
				endif
			endif
		else
			if stridx(file_class, namespace.'/') == 0
				let candidate = spec_path.'/'.file_class.'Spec.php'
				if filereadable(candidate)
					let file_match = candidate
					break
				endif
			endif
		endif

		unlet suite settings
	endfor
	unlet suites

	return file_match
endfunction

function! phpspec#get_class_name()
	let name_pattern = '[a-zA-Z_\x7f-\xff\\][a-zA-Z_0-9\x7f-\xff\\]*'
	let total_lines = line('$') - 1
	let namespace = '\'
	let class = ''
	let i = 0

	while i < total_lines
		let line = getline(i)

		if line =~? '^\s*namespace\s*'.name_pattern
			let namespace = matchstr(line, '^\s*namespace\s*\zs'.name_pattern.'\ze')
		endif

		if line =~? '^\s*class\s*'.name_pattern
			let class = matchstr(line, '^\s*class\s*\zs'.name_pattern.'\ze')
			break
		endif

		let i += 1
	endwhile
	return namespace.'\'.class
endfunction
