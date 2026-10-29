# .dotfiles

[![flake check](https://github.com/MWJones96/.dotfiles/actions/workflows/flake-check.yml/badge.svg)](https://github.com/MWJones96/.dotfiles/actions/workflows/flake-check.yml)

Nix-managed dotfiles and package set for macOS (via `nix-darwin`) and Linux
(via standalone `home-manager`). One flake, same config, both platforms.

## Overview

A single [`flake.nix`](flake.nix) describes the whole environment: the CLI
tools, the GUI apps, and where each configuration file goes. The
configuration files themselves (`.zshrc`, `tmux.conf`, the Neovim config and
so on) stay as plain, hand-edited files in this repository. The Nix modules
only decide where each file is placed and which packages come with it.

Shell scripts in [`scripts/`](scripts) wrap the Nix commands: one to set up a
new machine, one to apply settings changes, and a pair to add or remove
packages.

## What's configured

| Tool | Files | Highlights |
|------|-------|------------|
| Neovim | `nvim/` | NvChad v2.5 base with LSP, formatting, debugging and test running for Rust, Python, C, C++ and C# (see [Neovim](#neovim)) |
| zsh | `zsh/.zshrc` | zinit plugin manager, syntax highlighting, autosuggestions, `fzf-tab`, Oh My Zsh snippets, `eza` aliases, `fzf`, `zoxide` (as `cd`) and `oh-my-posh` |
| tmux | `tmux/tmux.conf`, `nix/home/tmux.nix` | Prefix `C-Space`, catppuccin (mocha) theme, vim-style pane navigation, session save and restore |
| Alacritty | `alacritty/alacritty.toml` | Dracula colours, JetBrainsMono Nerd Font, slight transparency |
| Vim | `vim/.vimrc` | A minimal fallback config |
| direnv | `nix/home/direnv.nix` | `direnv` with `nix-direnv`, for per-project environments |
| Claude Code | `claude/` | User instructions (`CLAUDE.md`), settings, and a custom status line |
| macOS | `nix/hosts/` | GUI apps, Homebrew casks, an App Store app, and Dock and system defaults on first setup |

### Packages

[`nix/home/packages.nix`](nix/home/packages.nix) installs the same CLI tools on
every machine. Broadly:

- **Languages and build tools**: Rust (`rustc`, `cargo`, `clippy`, `rustfmt`,
  `cargo-nextest`), Python (`python3`, `ruff`, `uv`, `hatch`, `pipx`), C and C++
  (`clang`, `clang-tools`, `cmake`, `ninja`, `bear`), .NET 10 SDK with
  `dotnet-ef` and `netcoredbg`, and Node.js 24 with Corepack.
- **Cloud and containers**: AWS CLI, Azure CLI, `kubectl`, `kubelogin`, Helm,
  `kind`, `tfenv` and the Docker client.
- **Command-line utilities**: `fzf`, `eza`, `bat`, `ripgrep`, `fd`, `bottom`,
  `zoxide`, `atuin`, `dua`, `tealdeer`, `jq`, `yq-go`, `delta`, `lazygit`, `gh`,
  `shellcheck`, `just` and `gnupg`.
- **Editor support**: `neovim`, `vim`, `tree-sitter`, `stylua`, `prettier`,
  `csharpier` and `vscode-langservers-extracted`.
- **Other**: `claude-code`, `stow`, a small TeX Live set with `latexmk`, and the
  JetBrainsMono Nerd Font.

On Linux it also installs Alacritty and Obsidian. On macOS those come from
[`nix/hosts/darwin.nix`](nix/hosts/darwin.nix) instead, along with Firefox,
Slack and Zoom.

## Layout

```
flake.nix                # outputs: darwinConfigurations.macbook{,-install,-bootstrap},
                         # homeConfigurations.mxj-{x86_64,aarch64}-linux
scripts/
  bootstrap.sh           # installs everything: Nix, programs, apps (detects OS/arch)
  refresh.sh             # applies settings changes only, never installs anything
  add-package.sh         # add a package, permanently or as a one-off
  remove-package.sh      # counterpart to add-package.sh
nix/
  hosts/
    darwin.nix           # macOS system config: nix GUI apps, nix-darwin settings
    homebrew.nix         # Homebrew and App Store apps, installed by bootstrap.sh
    provisioning.nix     # new machine only: Homebrew cleanup, Dock, system defaults
  home/
    default.nix          # shared home-manager config, imports the rest below
    packages.nix         # CLI tools installed on every machine, both OSs
    zsh.nix, tmux.nix, editors.nix, alacritty.nix, direnv.nix, claude.nix
                         # one file per program
zsh/.zshrc, tmux/tmux.conf, vim/.vimrc, nvim/**, alacritty/alacritty.toml, claude/*
                         # the actual dotfile contents: plain files, hand-edited
.github/workflows/flake-check.yml
                         # CI: `nix flake check --no-build` on every push and PR
```

The files in `zsh/`, `tmux/`, `vim/`, `nvim/`, `alacritty/` and `claude/` are
the real configs, referenced by the matching `nix/home/*.nix` module. Editing
dotfile *content* never touches the `.nix` files.

## First-time setup on a new machine

```bash
git clone https://github.com/MWJones96/.dotfiles.git ~/.dotfiles
~/.dotfiles/scripts/bootstrap.sh
```

The repository must live at `~/.dotfiles`: the Nix modules link and source
files from that path.

That one command works on both macOS and Linux. It detects the OS and CPU
architecture from `uname` and runs the right thing. Concretely it:

1. Installs `curl` and `xz` with the system package manager if they are
   missing (apt, dnf, pacman, zypper or Homebrew), since the Nix installer
   needs both.
2. Installs Nix itself if missing (multi-user daemon install).
3. Enables flakes in `/etc/nix/nix.conf` if not already on (one-time, needs sudo).
4. Moves aside any conflicting pre-existing symlink for `~/.zshrc`, `~/.vimrc`,
   `~/.config/tmux/tmux.conf` or `~/.config/nvim` (e.g. from an old
   `stow`-based setup) to `<file>.pre-nix-backup` rather than failing or
   deleting it.
5. Runs `darwin-rebuild switch` on macOS, or
   `home-manager switch --flake .#mxj-<arch>-linux -b hm-backup` on Linux.
   On macOS this also installs the Homebrew and App Store apps
   (`nix/hosts/homebrew.nix`). On Linux it first installs 1Password to
   `/opt/1Password` from the official tarball if it isn't already present.

On a new Mac it uses `.#macbook-bootstrap`, which additionally uninstalls any
Homebrew package not declared and sets the Dock and system defaults
(`nix/hosts/provisioning.nix`). On a Mac that already has nix-darwin it uses
`.#macbook-install`, which leaves those alone.

The home-manager activation also installs the `EasyDotnet` .NET global tool
(the backend for easy-dotnet.nvim) and, if Neovim has never been set up,
runs NvChad's headless bootstrap to install plugins, Mason tools and
Treesitter parsers.

It's idempotent, so it's safe to re-run any time. Re-run it whenever you add
or remove a program.

For everything else, use `refresh.sh` (see below). It applies settings only:
if the config would add or remove a program, it stops and tells you to run
`bootstrap.sh` instead.

### Supported platforms

- macOS on Apple silicon (`aarch64-darwin`)
- Linux on `x86_64` or `aarch64`

The username and home directory are fixed in the flake, the Nix modules and
the scripts, so using this on an account with a different name means editing
those first.

### Doing it manually instead

If you'd rather run the underlying commands yourself instead of `bootstrap.sh`:

```bash
# macOS
sudo nix --extra-experimental-features 'nix-command flakes' \
  run nix-darwin -- switch --flake ~/.dotfiles#macbook-bootstrap

# Linux: pick the attribute matching your CPU
arch="$(uname -m | sed -e 's/x86_64/x86_64-linux/' -e 's/aarch64/aarch64-linux/' -e 's/arm64/aarch64-linux/')"
nix --extra-experimental-features 'nix-command flakes' \
  run home-manager -- switch --flake ~/.dotfiles#mxj-$arch -b hm-backup
```

(This assumes Nix is already installed and flakes are already enabled.
`bootstrap.sh` is what handles both of those for you on a truly fresh machine.)

## Changing a dotfile

Edit the file in the repo: `zsh/.zshrc`, `tmux/tmux.conf`, `vim/.vimrc`,
`nvim/**`, `alacritty/alacritty.toml`, `claude/CLAUDE.md`,
`claude/settings.json`, `claude/statusline.sh`.

The Vim, Neovim, Alacritty and Claude Code files are symlinked straight to the
repo. The zsh and tmux configs generated by home-manager `source` the repo
files. Either way, a saved edit is live straight away: open a new shell, run
`tmux source ~/.config/tmux/tmux.conf`, or restart nvim. No `refresh.sh` is
needed, including for new files under `nvim/`.

`refresh.sh` is only needed for changes to the `nix/` files themselves.

## Adding or removing a program

Where to declare it depends on how widely you want it applied:

- **Every machine, both OSs (the common case)**:
  ```bash
  ./scripts/add-package.sh <package>       # add
  ./scripts/remove-package.sh <package>    # remove
  ```
  Both edit [`nix/home/packages.nix`](nix/home/packages.nix) and offer to run
  `bootstrap.sh` for you. `add-package.sh` first checks that the name resolves
  in nixpkgs (a fast attribute lookup that catches a typo before it is
  committed or half-applied). The scripts are equivalent to editing
  `packages.nix` by hand. Removing doesn't immediately delete anything from
  `/nix/store`: it takes the package off this machine's `PATH` on the next
  `bootstrap.sh`, and the files are reclaimed by the next garbage collection
  (`nix-collect-garbage`).
- **A one-off tool on this machine, not tracked anywhere**:
  ```bash
  ./scripts/add-package.sh --once <package>       # install
  ./scripts/remove-package.sh --once <package>    # uninstall
  ```
  Runs `nix profile install`/`remove` directly. This won't show up on a fresh
  machine (nothing in the repo declares it), and
  `bootstrap.sh`/`refresh.sh`/`darwin-rebuild`/`home-manager switch` won't
  touch it either way.
- **This machine/OS only, but still declarative and reproducible**: add it to
  the host-specific file instead, e.g.
  [`nix/hosts/darwin.nix`](nix/hosts/darwin.nix)'s `environment.systemPackages`
  or [`nix/hosts/homebrew.nix`](nix/hosts/homebrew.nix)'s `homebrew.casks` for
  something only this Mac should get. Right now there's one host per platform,
  so "host-specific" and "platform-specific" are the same thing. If a second
  Mac or Linux box ever needs to diverge from this one, that's the point to
  split `nix/hosts/` into one file per machine. The add/remove scripts don't
  cover this case, so edit the file directly.

A GUI app on macOS goes in `nix/hosts/darwin.nix`'s `environment.systemPackages`
when nixpkgs has a macOS build of it, and lands in `/Applications/Nix Apps`.
Otherwise it goes in `nix/hosts/homebrew.nix`'s `homebrew.casks` (or
`masApps`, for the App Store).

### What's still Homebrew

Only the apps nixpkgs has no macOS build for: Claude Desktop, Docker Desktop,
Keybase and Twingate. Plus 1Password, which has one but refuses to run from
anywhere but `/Applications`. Microsoft Outlook comes from the App Store.
Everything else, CLI tools and `tfenv` included, comes from Nix. `bootstrap.sh`
uninstalls any Homebrew package not declared in `homebrew.nix`, on a new Mac only.

## Neovim

The config in [`nvim/`](nvim) builds on [NvChad](https://nvchad.com/) v2.5,
with plugins managed by lazy.nvim and pinned in `nvim/lazy-lock.json`. The
leader key is Space.

### Editor and UI

- **Theme**: `tokyonight`, with custom nvim-tree highlights.
- **Statusline**: NvChad's `vscode_colored` statusline with a custom git
  section showing the branch, commits ahead and behind, and staged, modified
  and untracked counts across the whole repository, from a single cached
  `git status` call ([`configs/gitstatus.lua`](nvim/lua/configs/gitstatus.lua)).
- **Pickers**: `vim.ui.select` (code actions and similar) is replaced by a
  plain centred popup list ([`configs/select.lua`](nvim/lua/configs/select.lua)).
- **nvim-tree**: git status and diagnostics shown on files and directories,
  git-ignored files hidden.
- **gitsigns**: inline blame for the current line.
- **render-markdown.nvim** for Markdown buffers.
- **Treesitter** (main branch): the "stable" parser set plus an explicit list
  (C, C++, CMake, C#, Python, Rust, Lua, Bash, JSON, YAML, TOML, Markdown).
- Relative line numbers and inlay hints are on.

### Languages

| Language | Language server | Formatter | Run, test and debug |
|----------|-----------------|-----------|---------------------|
| Rust | rust-analyzer via rustaceanvim | rustfmt | rustaceanvim runnables, neotest, codelldb; crates.nvim for `Cargo.toml` |
| Python | basedpyright and ruff | ruff (fix, organise imports, format) | neotest-python, nvim-dap-python with debugpy, venv-selector.nvim |
| C | clangd (with clangd_extensions.nvim) | clang-format | cmake-tools.nvim (configure, build, run, debug, ctest) |
| C++ | clangd | clang-format | cmake-tools.nvim; tests run through `ctest` |
| C# | Roslyn via easy-dotnet.nvim | CSharpier | easy-dotnet.nvim (build, run, watch, test runner, NuGet, EF Core migrations), netcoredbg |
| Lua | lua-language-server | stylua | |
| HTML, CSS | vscode-langservers-extracted | prettier | |

Formatting runs on save through conform.nvim, falling back to the language
server. mason-tool-installer.nvim installs the Mason-managed tools on startup:
lua-language-server, basedpyright, ruff, debugpy, stylua, codelldb, clangd and
rust-analyzer.

### Keymaps

Beyond NvChad's defaults:

| Keys | Action |
|------|--------|
| `;` | Enter command mode |
| `jk` (insert mode) | Escape |
| Arrow keys | Show a reminder to use `h`/`j`/`k`/`l` instead of moving |
| `<leader>d…` | Debugger: `c` continue, `b` toggle breakpoint, `d` conditional breakpoint, `j` step over, `l` step into, `k` step out, `e` terminate, `r` run last, `h` inspect value, `u` toggle UI |
| `F5`, `F9`, `F10`, `F11`, `F12` | Debugger: continue, toggle breakpoint, step over, step into, step out |
| `<leader>r…` | Language-specific run, build and test commands, set per buffer for Rust, Python, C, C++ and C#. Lower case acts on the current item or target, upper case widens or resets it (for example `<leader>rt` runs the tests in the file, `<leader>rT` the whole suite) |
| `<leader>c…` (in `Cargo.toml`) | crates.nvim: versions, features, dependencies, upgrade |

nvim-dap-ui opens and closes automatically with a debug session, and
nvim-dap-virtual-text shows variable values inline.

## Shell and terminal

- **zsh**: zinit installs itself on first run and loads
  `zsh-syntax-highlighting`, `zsh-completions`, `zsh-autosuggestions` and
  `fzf-tab`, plus Oh My Zsh snippets for git, sudo, Arch Linux, AWS, kubectl,
  kubectx and command-not-found. Emacs keybindings with `Ctrl-P`/`Ctrl-N`
  history search, a 5,000-line shared history without duplicates,
  case-insensitive completion, and `eza` aliases for `ls`, `ll`, `la`, `lt`
  and `lx`. The prompt is oh-my-posh.
- **tmux**: prefix `C-Space`; `h`/`j`/`k`/`l` after the prefix or Alt-arrow
  keys to move between panes; Shift-arrow keys or `Alt-Shift-H`/`Alt-Shift-L`
  to switch windows; windows and panes numbered from 1; vi copy mode (`v` to
  select, `y` to copy); splits open in the current directory; prefix `,`
  renames the window in a popup. Plugins come from nixpkgs rather than TPM:
  sensible, vim-tmux-navigator, yank, catppuccin, resurrect (with pane
  contents) and continuum (automatic restore).
- **Alacritty**: Dracula colours, JetBrainsMono Nerd Font at size 12, 95%
  opacity, and `Shift-Enter` sending an escaped newline.
- **Vim**: a short `.vimrc` with search and line-number settings, leader `'`,
  `jk` to escape, and arrow keys disabled.

## Claude Code

`claude/` holds the user-level Claude Code configuration, symlinked into
`~/.claude/`:

- `CLAUDE.md`: personal instructions for how Claude should work (commenting
  style, brevity, asking before opening pull requests).
- `settings.json`: model, theme, status line command, and an enabled plugin
  from a third-party marketplace.
- `statusline.sh`: a status line showing the model, the git branch, context
  window use, and the five-hour and seven-day rate-limit usage with reset
  times, coloured yellow from 70% and red from 90%. It needs `jq`, which
  `packages.nix` installs.

## Verifying a switch actually applied

```bash
nix flake check ~/.dotfiles      # catches eval errors before applying anything
readlink ~/.zshrc                # should point into /nix/store/..., not ~/.dotfiles
command -v <tool>                # confirms a given package landed on PATH
```

After a real switch: open a new shell (zinit, aliases, `fzf`/`zoxide`/`oh-my-posh`
init should all work), a new tmux session (catppuccin theme, `vim-tmux-navigator`
pane switching, prefix `C-Space`, no `~/.config/tmux/plugins/tpm` needed), and
nvim (NvChad should look and behave the same).

CI runs `nix flake check --no-build` on every push and pull request, which
evaluates every output, including the macOS ones, on a Linux runner.

## Known caveats

- **NvChad's headless bootstrap can fail on a truly cold plugin cache**
  (a brand new machine that's never run nvim before): `require('lazy').restore()`
  downloads plugins to disk, but the following `lazy.load({...})` call only
  loads `ui`/`base46`/`nvim-treesitter` into the running session, not
  `nvchad`/`mason.nvim`, so `require('nvchad.mason').install_all()` can fail
  with a "module not found" error on first run. Opening nvim normally
  afterwards and letting lazy.nvim finish on its own works around it; the
  headless step just doesn't guarantee a full LSP/tool install on the very
  first run on a fresh machine.
- **The first C# buffer on a new machine is slow.** easy-dotnet.nvim fetches
  `roslyn-language-server` (a ~200MB dotnet global tool) the first time you
  open a `.cs` file, so completion and diagnostics only come alive a minute
  or two in. It's a one-off; afterwards Roslyn starts in seconds. The other
  dotnet tool it needs, `EasyDotnet`, is installed up front by
  `nix/home/editors.nix` during activation, so only Roslyn is deferred.
  `dotnet-easydotnet roslyn update` refreshes it later; `:checkhealth
  easy-dotnet` reports what's missing.
- **Python tests need the interpreter to have pytest.** neotest asks the
  project's interpreter which runner to use, and falls back to `unittest`
  when it can't import pytest. Under `unittest`, plain `def test_*` functions
  outside a `TestCase` aren't collected, so the file looks empty rather than
  broken. A bare `uv venv` with nothing synced does exactly this. `uv sync`
  (or `uv pip install pytest`) fixes it. `<leader>rv` picks a different
  interpreter if the wrong one was found.
- **C needs a `compile_commands.json` before clangd is any use.** Without one
  it guesses flags per file, so cross-file jump-to-definition and most
  diagnostics quietly don't work. In a CMake project `<leader>rg`
  (`:CMakeGenerate`) writes it and symlinks it to the project root
  automatically. For a plain Makefile project there's no generator, so run
  `bear -- make` once instead.
- **C++ tests run through ctest, not neotest.** neotest-gtest is the only
  GoogleTest adapter and it is broken on Neovim 0.11+: it calls
  `iter_matches(..., { all = false })`, an API removed in 0.11, so every
  discovery throws. `<leader>rr` and `<leader>rf` instead shell out to
  `ctest -R` for the test or suite under the cursor. Both need the project to
  register cases with `gtest_discover_tests()` (a single `add_test` for the
  whole binary gives ctest nothing per-test to filter on), and they need a
  **build** first, not just a configure, because that is when
  `gtest_discover_tests` enumerates them. Before that, ctest exits 0 saying
  "No tests were found".
- **The first `<leader>rb` in a CMake project asks which target to build.**
  So does `<leader>rt` for tests. That's cmake-tools prompting, not an error;
  `<leader>rs` and `<leader>rS` set the build and launch targets so it stops
  asking.
- **`~/.local/bin/ruff` shadows the Nix one.** `home.sessionPath` puts
  `~/.local/bin` ahead of the Nix profile, so a stale ruff left there by pipx
  wins on the command line. It doesn't affect nvim, where Mason's ruff is
  ahead of both, but `rm ~/.local/bin/ruff` makes the shell agree with the
  editor.
- **`corepack enable` needs an install directory.** Its default is next to the
  `node` binary, which is a read-only Nix store path. Run
  `corepack enable --install-directory ~/.local/bin` once per machine (already
  on `PATH`), or call `corepack yarn` directly.

## Licence

[MIT](LICENSE)
