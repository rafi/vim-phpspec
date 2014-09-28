
# vim-phpspec

Vim PhpSpec integration which reads phpspec.yml file from current-working
directory.

## Features

- Reads phpspec.yml
- Switch to spec/class
- Run current/all specs
- Uses vimproc if available
- Tiny. [~200LoC](./plugin/phpspec.vim)

## Dependencies
- vim +python - Verify with `:echo has('python')` (output should be `1`)
- [python2-yaml]

## Installation
Use your favorite plugin manager.

## Commands
- `:PhpSpecRun` - Runs all spec suites. (_Default mapping:_ `<Leader>spr`)
- `:PhpSpecRunCurrent` - Runs current spec.  (_Default mapping:_ `<Leader>spc`)
- `:PhpSpecSwitch` - Switch to spec or class file, confirms spec creation if
    missing. (_Default mapping:_ `<Leader>sps`)

### Options
Put any of the following options into your `~/.vimrc` in order to overwrite the default behaviour.

| Option                      | Default     | Description                               |
|-----------------------------|-------------|-------------------------------------------|
| `g:phpspec_executable`      | Auto-detect | Path to phpspec executable                |
| `g:phpspec_default_mapping` | 1           | Set to 0 to disable default key-mappings  |

## Credits & Contribution
Inspiration:
- [Herzult/phpspec-vim]
- [shawncplus/phpcomplete.vim]

This plugin was developed by Rafael Bodill under the [MIT License].

  [python2-yaml]: http://pyyaml.org
  [Herzult/phpspec-vim]: https://github.com/Herzult/phpspec-vim
  [shawncplus/phpcomplete.vim]: https://github.com/shawncplus/phpcomplete.vim
  [MIT License]: ./LICENSE
