# Local macOS Neovim IDE Setup

This document records the steps used to turn `nvim-lua/kickstart.nvim` into the
current macOS IDE setup for C, C++, HTML, JavaScript, TypeScript, and Python.

The goal is to make the setup reproducible without needing Codex to reconstruct
the history.

## 1. Install System Prerequisites

Install Apple command line tools:

```sh
xcode-select --install
```

Install Neovim and core command-line dependencies:

```sh
brew install neovim ripgrep fd tree-sitter node
```

Optional, but recommended for icons:

```sh
brew install --cask font-jetbrains-mono-nerd-font
```

Confirm Homebrew is on the shell path:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

The persistent shell setup lives in:

```sh
~/.zprofile
```

It should contain:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## 2. Fork And Clone Kickstart

Fork the upstream repository into the GitHub account:

```text
https://github.com/nvim-lua/kickstart.nvim
```

The fork used here is:

```text
https://github.com/YakkoByte/kickstart.nvim
```

Clone the fork as the active Neovim config:

```sh
git clone https://github.com/YakkoByte/kickstart.nvim.git ~/.config/nvim
```

If GitHub prompts for a password over HTTPS, do not use the account password.
GitHub no longer supports password authentication for Git operations. Use either
a personal access token or SSH.

This setup now uses SSH:

```sh
git -C ~/.config/nvim remote set-url origin git@github.com:YakkoByte/kickstart.nvim.git
```

Confirm:

```sh
git -C ~/.config/nvim remote -v
```

Expected:

```text
origin  git@github.com:YakkoByte/kickstart.nvim.git (fetch)
origin  git@github.com:YakkoByte/kickstart.nvim.git (push)
```

## 3. First Launch

Start Neovim:

```sh
nvim
```

Allow the initial packages to install.

If Tree-sitter parser installation fails with an error like:

```text
ENOENT: no such file or directory (cmd): 'tree-sitter'
```

then the `tree-sitter` CLI is missing from the shell path.

Homebrew's `tree-sitter` formula may install the library without exposing a CLI
binary. The working fix used here was npm:

```sh
npm install -g tree-sitter-cli
```

Confirm:

```sh
which tree-sitter
tree-sitter --version
```

Expected path:

```text
/opt/homebrew/bin/tree-sitter
```

Then update parsers:

```sh
nvim --headless '+TSUpdate' '+sleep 3' '+qa'
```

Inside Neovim, this can also be run manually:

```vim
:TSUpdate
```

## 4. Language Tooling Added To `init.lua`

The current config enables these language servers:

```lua
local servers = {
  clangd = {},
  pyright = {},
  ts_ls = {},
  html = {},
  stylua = {},
  lua_ls = {
    -- existing kickstart Lua config
  },
}
```

The Mason install list includes:

```lua
'black',
'clang-format',
'codelldb',
'isort',
'prettier',
'prettierd',
```

The formatter setup uses `conform.nvim`:

```lua
formatters_by_ft = {
  c = { 'clang-format' },
  cpp = { 'clang-format' },
  python = { 'isort', 'black' },
  html = { 'prettierd', 'prettier', stop_after_first = true },
  javascript = { 'prettierd', 'prettier', stop_after_first = true },
  typescript = { 'prettierd', 'prettier', stop_after_first = true },
}
```

Auto-format-on-save is enabled for:

```lua
c = true,
cpp = true,
html = true,
javascript = true,
python = true,
typescript = true,
```

Tree-sitter parsers were expanded to include:

```lua
'c',
'cpp',
'html',
'javascript',
'json',
'python',
'typescript',
```

## 5. Mason Packages

Open Mason:

```vim
:Mason
```

The expected installed packages are:

```text
black
clang-format
clangd
codelldb
html-lsp
isort
lua-language-server
prettier
prettierd
pyright
stylua
typescript-language-server
```

Mason's `(4) Linter` tab may show no installed packages. That is expected in
this setup because the C/C++ linter is `clang-tidy`, installed through Homebrew
LLVM rather than Mason.

## 6. C/C++ Debugging And Linting

Custom C/C++ tooling lives in:

```text
lua/custom/plugins/cpp.lua
```

That file installs and configures:

```text
nvim-dap
nvim-dap-ui
nvim-nio
nvim-lint
```

It configures:

```text
Debugger: codelldb through nvim-dap
Linter: clang-tidy through nvim-lint
Formatter: clang-format through conform.nvim
```

Debugger keymaps:

```text
F5          Debug start/continue
F10         Step over
F11         Step into
F12         Step out
<leader>db  Toggle breakpoint
<leader>dB  Conditional breakpoint
<leader>dr  Open debug REPL
<leader>du  Toggle debug UI
<leader>dl  Run last debug session
```

The status helper is:

```vim
:CppToolingStatus
```

Expected output includes:

```text
LSP: clangd
Formatter: clang-format via conform.nvim (<leader>f)
Linter: clang-tidy via nvim-lint on save/insert-leave
Debugger: codelldb via nvim-dap
```

## 7. Install `clang-tidy`

Install Homebrew LLVM:

```sh
brew install llvm
```

Homebrew installs LLVM as keg-only, so `clang-tidy` is not placed directly on
the normal shell path. The config points to it directly:

```text
/opt/homebrew/opt/llvm/bin/clang-tidy
```

Confirm:

```sh
/opt/homebrew/opt/llvm/bin/clang-tidy --version
```

## 8. Validate Neovim Configuration

Run:

```sh
nvim --headless '+lua print("config ok")' '+CppToolingStatus' '+qa'
```

Run a general health check inside Neovim:

```vim
:checkhealth
```

Known normal warnings:

- Optional language toolchains may be missing in Mason, such as Go, Rust, PHP,
  Java, or Julia. Ignore these unless actively developing in those languages.
- Provider warnings for Node, Python, Ruby, or Perl are optional for this Lua
  config.
- `which-key` may warn about `nvim-web-devicons`; kickstart uses `mini.icons`
  and mocks devicons compatibility.
- `blink.cmp` may warn about its optional Rust fuzzy matcher; this config uses
  the Lua matcher.

## 9. LSP Inspection In Neovim 0.12

`:LspInfo` is not available in this setup. Use:

```vim
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
```

Shorter version:

```vim
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do print(c.name) end
```

Expected C/C++ output:

```text
clangd
```

LSP attaches only to source buffers, not to the netrw directory listing. Open a
C++ file first:

```vim
:e src/main.cpp
```

## 10. Project Compile Context

For C/C++, clangd needs the same compile context as the real build. If clangd
shows false errors such as unresolved raylib types or missing standard library
types, the project is missing compile flags from clangd's point of view.

For simple Makefile projects, add `compile_flags.txt` in the project root.

Example for `ecs-gui-sandbox-01`:

```text
-std=c++23
-I/opt/homebrew/Cellar/raylib/5.5/include
```

Then reopen Neovim from the project root:

```sh
cd /Users/localuser/Coding/CodexProjects/ecs-gui-sandbox-01
nvim .
```

For larger projects, prefer `compile_commands.json`. For CMake:

```sh
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sf build/compile_commands.json compile_commands.json
```

For Makefile projects, generate a compile database with `bear`:

```sh
brew install bear
bear -- make clean all
```

## 11. Example Workflow For `ecs-gui-sandbox-01`

From the repo root:

```sh
cd /Users/localuser/Coding/CodexProjects/ecs-gui-sandbox-01

pkg-config --cflags raylib
pkg-config --libs raylib

make clean
make
make smoke

nvim .
```

Inside Neovim:

```vim
:e src/main.cpp
:CppToolingStatus
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do print(c.name) end
```

Expected LSP:

```text
clangd
```

## 12. Debugger Smoke Test

In `src/main.cpp`:

1. Build first:

   ```vim
   :make
   ```

2. Put the cursor on a line in `main`.

3. Toggle a breakpoint:

   ```text
   <leader>db
   ```

4. Start debugging:

   ```text
   F5
   ```

5. When prompted for the executable path, use:

   ```text
   /Users/localuser/Coding/CodexProjects/ecs-gui-sandbox-01/bin/ecs_gui_sandbox_01
   ```

   If Neovim was opened from the project root, this also works:

   ```text
   bin/ecs_gui_sandbox_01
   ```

## 13. File Explorer

The built-in file explorer is netrw:

```vim
:Explore
```

Short form:

```vim
:Ex
```

Telescope file search:

```text
<leader>sf
```

Neo-tree is still optional and not enabled by default in this setup.

## 14. Git Baseline

The important local commits created during setup were:

```text
16a2c79 Configure initial language tooling
64a8d19 Add C++ debugging and linting tooling
```

The remote was switched to SSH and pushed:

```sh
git -C ~/.config/nvim remote set-url origin git@github.com:YakkoByte/kickstart.nvim.git
git -C ~/.config/nvim push
```

Check sync state:

```sh
git -C ~/.config/nvim status --short --branch
```

Expected:

```text
## master...origin/master
```

