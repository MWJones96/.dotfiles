# .dotfiles

Nix-managed dotfiles and package set for macOS (via `nix-darwin`) and Linux
(via standalone `home-manager`). One flake, same config, both platforms.

## Layout

```
flake.nix                # outputs: darwinConfigurations.macbook{,-install,-bootstrap},
                          # homeConfigurations.mxj-{x86_64,aarch64}-linux
scripts/
  bootstrap.sh             # installs everything: Nix, programs, apps (detects OS/arch)
  refresh.sh               # applies settings changes only, never installs anything
  add-package.sh           # add a package, permanently or as a one-off
  remove-package.sh        # counterpart to add-package.sh
nix/
  hosts/
    darwin.nix             # macOS system config: nix GUI apps, nix-darwin settings
    homebrew.nix           # Homebrew and App Store apps, installed by bootstrap.sh
    provisioning.nix       # new machine only: Homebrew cleanup, Dock, system defaults
  home/
    default.nix            # shared home-manager config, imports the rest below
    packages.nix            # CLI tools installed on every machine, both OSs
    zsh.nix, tmux.nix, editors.nix, alacritty.nix, direnv.nix   # one file per program
zsh/.zshrc, tmux/tmux.conf, vim/.vimrc, nvim/**, alacritty/alacritty.toml
                          # the actual dotfile contents — plain files, hand-edited
```

The files in `zsh/`, `tmux/`, `vim/`, `nvim/`, `alacritty/` are the real
configs, referenced by the matching `nix/home/*.nix` module. Editing dotfile
*content* never touches the `.nix` files — those just decide *where* a file
gets placed and *what packages* come with it.

## First-time setup on a new machine

```bash
git clone https://github.com/MWJones96/.dotfiles.git ~/.dotfiles
~/.dotfiles/scripts/bootstrap.sh
```

That one command works on both macOS and Linux — it detects the OS and CPU
architecture from `uname` and runs the right thing. Concretely it:

1. Installs Nix itself if missing (multi-user daemon install).
2. Enables flakes in `/etc/nix/nix.conf` if not already on (one-time, needs sudo).
3. Moves aside any conflicting pre-existing dotfile (e.g. from an old manual
   setup) to `<file>.pre-nix-backup` rather than failing or deleting it.
4. Runs `darwin-rebuild switch` on macOS, or
   `home-manager switch --flake .#mxj-<arch>-linux -b hm-backup` on Linux.
   On macOS this also installs the Homebrew and App Store apps
   (`nix/hosts/homebrew.nix`).

On a new Mac it uses `.#macbook-bootstrap`, which additionally uninstalls any
Homebrew package not declared and sets the Dock and system defaults
(`nix/hosts/provisioning.nix`). On a Mac that already has nix-darwin it uses
`.#macbook-install`, which leaves those alone.

It's idempotent — safe to re-run any time. Re-run it whenever you add or
remove a program.

For everything else, use `refresh.sh` (see below). It applies settings only:
if the config would add or remove a program, it stops and tells you to run
`bootstrap.sh` instead.

### Doing it manually instead

If you'd rather run the underlying commands yourself instead of `bootstrap.sh`:

```bash
# macOS
sudo nix --extra-experimental-features 'nix-command flakes' \
  run nix-darwin -- switch --flake ~/.dotfiles#macbook-bootstrap

# Linux — pick the attribute matching your CPU
arch="$(uname -m | sed -e 's/x86_64/x86_64-linux/' -e 's/aarch64/aarch64-linux/' -e 's/arm64/aarch64-linux/')"
nix --extra-experimental-features 'nix-command flakes' \
  run home-manager -- switch --flake ~/.dotfiles#mxj-$arch -b hm-backup
```

(This assumes Nix is already installed and flakes are already enabled —
`bootstrap.sh` is what handles both of those for you on a truly fresh machine.)

## Changing a dotfile

Edit the file in the repo: `zsh/.zshrc`, `tmux/tmux.conf`, `vim/.vimrc`,
`nvim/**`, `alacritty/alacritty.toml`, `claude/CLAUDE.md`,
`claude/statusline.sh`. They're symlinked straight to the repo, so a saved
edit is live straight away: open a new shell, run `tmux source ~/.config/tmux/tmux.conf`,
or restart nvim. No `refresh.sh` needed, including for new files under `nvim/`.

`refresh.sh` is only needed for changes to the `nix/` files themselves, or to
`claude/settings.json`. This relies on the repo living at `~/.dotfiles`.

## Adding or removing a program

Where to declare it depends on how widely you want it applied:

- **Every machine, both OSs (the common case)** —
  ```bash
  ./scripts/add-package.sh <package>       # add
  ./scripts/remove-package.sh <package>    # remove
  ```
  Both verify the package name actually resolves in nixpkgs first (fast
  attribute lookup, catches a typo before it's committed or half-applied),
  edit [`nix/home/packages.nix`](nix/home/packages.nix), and offer to run
  `bootstrap.sh` for you. (Equivalent to editing `packages.nix` by hand — the
  scripts just add the existence check and save a step.) Removing doesn't
  immediately delete anything from `/nix/store` — it just takes the package
  off this machine's `PATH` on the next `bootstrap.sh`; the files themselves
  get reclaimed whenever you next run a garbage-collection sweep
  (`nix-collect-garbage`), which is normal Nix behavior, not something these
  scripts need to manage.
- **A one-off tool on this machine, not tracked anywhere** —
  ```bash
  ./scripts/add-package.sh --once <package>       # install
  ./scripts/remove-package.sh --once <package>    # uninstall
  ```
  Runs `nix profile install`/`remove nixpkgs#<package>` directly. This won't
  show up on a fresh machine (nothing in the repo declares it), and
  `bootstrap.sh`/`refresh.sh`/`darwin-rebuild`/`home-manager switch` won't
  touch it either way.
- **This machine/OS only, but still declarative and reproducible** — add it
  to the host-specific file instead, e.g.
  [`nix/hosts/darwin.nix`](nix/hosts/darwin.nix)'s `environment.systemPackages`
  or [`nix/hosts/homebrew.nix`](nix/hosts/homebrew.nix)'s
  `homebrew.casks` for something only this Mac should get. Right now
  there's one host per platform, so "host-specific" and "platform-specific"
  are the same thing — if a second Mac or Linux box ever needs to diverge
  from this one, that's the point to split `nix/hosts/` into one file per
  machine. The add/remove scripts don't cover this case — edit the file
  directly.

A GUI app on macOS goes in `nix/hosts/darwin.nix`'s `environment.systemPackages`
when nixpkgs has a macOS build of it, and lands in `/Applications/Nix Apps`.
Otherwise it goes in `nix/hosts/homebrew.nix`'s `homebrew.casks` (or
`masApps`, for the App Store).

### What's still Homebrew

Only the apps nixpkgs has no macOS build for: Claude Desktop, Docker Desktop,
Keybase and Twingate. Microsoft Outlook comes from the App Store. Everything
else, CLI tools and `tfenv` included, comes from Nix. `bootstrap.sh`
uninstalls any Homebrew package not declared in `homebrew.nix`, on a new Mac only.

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

## Known caveats

- **NvChad's headless bootstrap can fail on a truly cold plugin cache**
  (a brand new machine that's never run nvim before): `require('lazy').restore()`
  downloads plugins to disk, but the following `lazy.load({...})` call only
  loads `ui`/`nvim-treesitter` into the running session — not `nvchad`/`mason.nvim`
  — so `require('nvchad.mason').install_all()` can fail with a "module not
  found" error on first run. This is inherited from the original install
  script's bootstrap sequence, not something this migration introduced.
  Opening nvim normally afterward and letting lazy.nvim finish on its own
  works around it; the headless step just doesn't guarantee full LSP/tool
  install on the very first run on a fresh machine.
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
  when it can't import pytest — under which plain `def test_*` functions
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
  register cases with `gtest_discover_tests()` -- a single `add_test` for the
  whole binary gives ctest nothing per-test to filter on -- and they need a
  **build** first, not just a configure, because that is when
  `gtest_discover_tests` enumerates them. Before that ctest exits 0 saying
  "No tests were found".
- **The first `<leader>rb` in a CMake project asks which target to build.**
  So does `<leader>rt` for tests. That's cmake-tools prompting, not an error;
  `<leader>rs` and `<leader>rS` set the build and launch targets so it stops
  asking.
- **`~/.local/bin/ruff` shadows the Nix one.** `home.sessionPath` puts
  `~/.local/bin` ahead of the Nix profile, so a stale ruff left there by pipx
  wins on the command line (0.9.6 vs the current release, at the time of
  writing). It doesn't affect nvim — Mason's ruff is ahead of both there —
  but `rm ~/.local/bin/ruff` makes the shell agree with the editor.
