# .dotfiles

Nix-managed dotfiles and package set for macOS (via `nix-darwin`) and Linux
(via standalone `home-manager`). One flake, same config, both platforms.

## Layout

```
flake.nix                # outputs: darwinConfigurations.macbook,
                          # homeConfigurations.mxj-{x86_64,aarch64}-linux
install.sh                # single-command bootstrap (detects OS/arch)
nix/
  hosts/
    darwin.nix             # macOS system config: Homebrew casks, nix-darwin settings
  home/
    default.nix            # shared home-manager config, imports the rest below
    packages.nix            # CLI tools installed on every machine, both OSs
    zsh.nix, tmux.nix, editors.nix, alacritty.nix   # one file per program
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
~/.dotfiles/install.sh
```

That one command works on both macOS and Linux — it detects the OS and CPU
architecture from `uname` and runs the right thing. Concretely it:

1. Installs Nix itself if missing (multi-user daemon install).
2. Enables flakes in `/etc/nix/nix.conf` if not already on (one-time, needs sudo).
3. Moves aside any conflicting pre-existing dotfile (e.g. from an old manual
   setup) to `<file>.pre-nix-backup` rather than failing or deleting it.
4. Runs `darwin-rebuild switch --flake .#macbook` on macOS, or
   `home-manager switch --flake .#mxj-<arch>-linux -b hm-backup` on Linux.

It's idempotent — safe to re-run any time, on a fresh machine or an
already-set-up one. It's also literally what "apply my latest changes"
reduces to (see below), so you never need to remember the underlying
`darwin-rebuild`/`home-manager` invocation by hand.

### Doing it manually instead

If you'd rather run the underlying commands yourself instead of `install.sh`:

```bash
# macOS
sudo nix --extra-experimental-features 'nix-command flakes' \
  run nix-darwin -- switch --flake ~/.dotfiles#macbook

# Linux — pick the attribute matching your CPU
arch="$(uname -m | sed -e 's/x86_64/x86_64-linux/' -e 's/aarch64/aarch64-linux/' -e 's/arm64/aarch64-linux/')"
nix --extra-experimental-features 'nix-command flakes' \
  run home-manager -- switch --flake ~/.dotfiles#mxj-$arch -b hm-backup
```

(This assumes Nix is already installed and flakes are already enabled —
`install.sh` is what handles both of those for you on a truly fresh machine.)

## Changing a dotfile

Edit the file directly — `zsh/.zshrc`, `tmux/tmux.conf`, `vim/.vimrc`,
`nvim/**`, `alacritty/alacritty.toml`. These are read straight from the
working tree, so a saved edit is immediately what the next switch will apply.
No `.nix` file needs to change for a content-only edit.

Then apply it:

```bash
~/.dotfiles/install.sh
```

A shell/tmux/editor config change needs a new shell, tmux session, or app
restart to actually show up — that's normal reload behavior, not a Nix thing.

**One catch:** this only works instantly for files Nix already knows about.
If you add a **brand-new file** (a new dotfile, a new `nix/home/*.nix`
module), Nix won't see it until it's at least staged in git — flake
evaluation only looks at git-tracked paths, not the raw filesystem:

```bash
git add path/to/new-file
~/.dotfiles/install.sh
```

An edit to an *already-tracked* file needs no git step at all — only brand
new files do.

## Adding or removing a program

Where to declare it depends on how widely you want it applied:

- **Every machine, both OSs (the common case)** — add or remove the package
  name in [`nix/home/packages.nix`](nix/home/packages.nix), then
  `install.sh`. No `flake.lock` update needed unless the package is newer
  than what's in the currently-pinned `nixpkgs` snapshot.
- **This machine/OS only, but still declarative and reproducible** — add it
  to the host-specific file instead, e.g.
  [`nix/hosts/darwin.nix`](nix/hosts/darwin.nix)'s `environment.systemPackages`
  or `homebrew.casks` for something only this Mac should get. Right now
  there's one host per platform, so "host-specific" and "platform-specific"
  are the same thing — if a second Mac or Linux box ever needs to diverge
  from this one, that's the point to split `nix/hosts/` into one file per
  machine.
- **A one-off tool on this machine, not tracked anywhere** — install it
  imperatively, completely outside the flake:
  ```bash
  nix profile install nixpkgs#<package>
  ```
  This won't show up on a fresh machine (nothing in the repo declares it),
  and `install.sh`/`darwin-rebuild`/`home-manager switch` won't touch it
  either way.

A GUI app on macOS that isn't practical to get from nixpkgs (like Alacritty)
goes in `nix/hosts/darwin.nix`'s `homebrew.casks` instead of `packages.nix` —
Homebrew does the actual install, declared as code. `homebrew.onActivation.cleanup`
is deliberately `"none"`, since this machine has plenty of Homebrew packages
installed outside this config — flipping it to `"uninstall"`/`"zap"` would
remove anything not explicitly listed here.

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

- **`nvim/lazy-lock.json` is intentionally not Nix-managed.** It's seeded
  once from the repo on a fresh machine, then left writable so `:Lazy` can
  update it locally (a Nix store path is read-only, and lazy.nvim needs to
  rewrite this file when plugin versions change). After updating plugins,
  copy it back: `cp ~/.config/nvim/lazy-lock.json ~/.dotfiles/nvim/lazy-lock.json`.
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
- **`.stow-local-ignore` is vestigial.** `stow` isn't invoked anywhere
  anymore — `install.sh` does everything through `darwin-rebuild`/`home-manager`.
  The file is kept up to date in case anyone ever runs `stow .` manually, but
  it's not part of the real setup path.
