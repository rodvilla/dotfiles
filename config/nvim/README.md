# Neovim setup

This config is LazyVim-based and tuned for Laravel/PHP, React/React Native TypeScript, Markdown, and Bash.

## First run / updates

```vim
:Lazy sync
:Mason
```

`tools.lua` asks Mason to install editor helpers like Intelephense, PHPStan, Prettier, ESLint, Marksman, ShellCheck, and shfmt. If something is missing, open `:Mason` and install it from there.

## PHP / Laravel behavior

- LSP: Intelephense (`vim.g.lazyvim_php_lsp = "intelephense"`).
- Format on save / `<leader>cf`: Laravel Pint when the project has `vendor/bin/pint` or `pint.json`; otherwise Mago.
- Automatic linting: lightweight `php -l` syntax checks.
- Heavier project checks run on demand in a terminal:

| Key | Command | Action |
| --- | --- | --- |
| `<leader>cpl` | `:PhpPint` | Pint current PHP file |
| `<leader>cpL` | `:PhpPintAll` | Pint whole project |
| `<leader>cps` | `:PhpStan` | PHPStan analyze |
| `<leader>cpr` | `:RectorDry` | Rector dry run |
| `<leader>cpR` | `:Rector` | Rector apply |
| `<leader>cpm` | `:MagoLint` | Mago lint |
| `<leader>cpM` | `:MagoFix` | Mago safe fixes + format |
| `<leader>cpT` | `:PhpUnitFile` | PHPUnit current test file |
| `<leader>cpt` | `:PhpUnitTest` | PHPUnit test method under cursor |

Recommended per Laravel project:

```bash
composer require --dev laravel/pint rector/rector phpstan/phpstan
vendor/bin/pint --init
vendor/bin/rector init
vendor/bin/phpstan analyse --generate-baseline # optional for existing projects
mago init # optional, if the project should use Mago config
```

Global tools managed by these dotfiles:

```bash
brew bundle --file ~/.dotfiles/Brewfile
brew bundle --file ~/.dotfiles/Brewfile.workstation
```

If you do not use Mason for Intelephense, install it globally instead:

```bash
npm install -g intelephense
```

## TypeScript / React / React Native

Enabled extras:

- `lazyvim.plugins.extras.lang.typescript`
- `lazyvim.plugins.extras.lang.tailwind`
- `lazyvim.plugins.extras.formatting.prettier`
- `lazyvim.plugins.extras.linting.eslint`

Use project-local dependencies when possible:

```bash
npm install --save-dev typescript prettier eslint
```

LazyVim provides the common LSP/code actions. Use `<leader>cf` to format and `<leader>ca` for code actions.

## Markdown and Bash

- Markdown: render/preview support plus Marksman and markdownlint via Mason.
- Bash: Bash language server, ShellCheck diagnostics, and shfmt formatting.

Useful commands:

```vim
:ConformInfo  " see available formatters for current file
:LintInfo     " see available linters for current file
:LspInfo      " see attached language servers
```
