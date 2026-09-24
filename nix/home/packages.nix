# Cross-platform CLI tools, replacing install.sh's brew/apt/dnf/pacman
# branching and the rustup + cargo-binstall pipeline. Same package set on
# macOS and every Linux distro.
#
# dotnetSdk is passed in rather than picked here because default.nix also needs
# the very same derivation for DOTNET_ROOT — see the comment there.
{ pkgs, dotnetSdk }:

with pkgs; [
  git
  curl
  wget
  unzip

  vim
  neovim

  rustc
  cargo
  clippy
  rustfmt
  cargo-nextest

  # basedpyright (Mason) is a node app, but it still needs a real interpreter
  # to resolve imports and stdlib types against, and it's what neotest and
  # nvim-dap-python fall back to for a project with no .venv.
  python3
  ruff
  uv

  # clangd (Mason) is LSP-only; these are what actually build/debug the code.
  clang
  cmake
  # cmake-tools.nvim generates with -G Ninja. CMake's default here is Unix
  # Makefiles, whose dependency scanning is what makes an incremental rebuild
  # slower than it needs to be.
  ninja
  # clang-format, for conform's c/cpp entry -- nothing provided it before, so
  # those buffers silently fell through to the LSP formatter. Also brings
  # clang-tidy as a standalone binary; clangd embeds its own copy for
  # --clang-tidy, but the CLI is what a pre-commit hook or CI would call.
  clang-tools
  # Produces compile_commands.json for projects that build with plain make.
  # CMake emits one itself, so this is only for the ones that don't -- without
  # it clangd guesses flags per file and every non-trivial #include goes
  # unresolved. Usage: `bear -- make`.
  bear

  # Same deal for C#: Roslyn (which easy-dotnet.nvim fetches as a dotnet
  # global tool) doesn't build anything, and it needs a real SDK to run on
  # in the first place. Pinned to 10.x in default.nix — plain `dotnet-sdk`
  # is still 8.x in nixpkgs, and the quaisr/core services all target net10.0
  # (CI pins dotnet-version: 10.0.x).
  dotnetSdk
  # EF Core's CLI, for generating/inspecting migrations in services/Migrations.
  # Packaged here rather than left to `dotnet tool install --global` so it
  # comes with the config on a new machine. Note this is the standalone
  # `dotnet-ef` binary — the `dotnet ef` subcommand form only works for tools
  # installed into ~/.dotnet/tools.
  dotnet-ef
  # nvim-dap needs a real debugger binary, the same way clang above backs
  # Mason's clangd.
  netcoredbg

  # The web workspace's toolchain (vitest, eslint, the yarn workspaces in
  # quaisr/core's web/). Corepack rather than nixpkgs' yarn because the repo
  # pins `packageManager: yarn@4.13.0` and Yarn 4 refuses to run on a mismatch:
  # nixpkgs' `yarn` is 1.x and `yarn-berry` is 4.14.1, so neither can satisfy
  # it. Corepack fetches whatever version a repo asks for, which is also what
  # CI does (`corepack enable`).
  #
  # `corepack enable` on its own fails here -- it writes shims next to the node
  # binary, which is a read-only store path. Install them somewhere writable
  # instead, once per machine:
  #   corepack enable --install-directory ~/.local/bin
  # (already on home.sessionPath). Or skip the shims and call `corepack yarn`.
  nodejs_24
  corepack_24

  # Cloud/cluster tooling, moved off Homebrew. `kubelogin` is Azure's
  # (Azure/kubelogin, the AKS credential plugin) -- nixpkgs also ships
  # int128/kubelogin as `kubelogin-oidc`, which is a different tool.
  awscli2
  azure-cli
  kubectl
  kubelogin
  kubernetes-helm
  kind
  tfenv
  # Client only: the daemon is Docker Desktop's, and the `compose`/`buildx`
  # subcommands come from Docker.app via ~/.docker/cli-plugins, so they keep
  # working regardless of where the `docker` binary itself comes from.
  docker-client

  # nixpkgs' `yq` is the Python wrapper around jq; Homebrew's `yq` (and what
  # the scripts here expect) is mikefarah's Go rewrite, which is `yq-go`.
  yq-go
  # macOS builds of gnupg already bake in pinentry-mac as the agent's pinentry
  # program, so no gpg-agent.conf is needed to get a working prompt.
  gnupg
  # Superseded by home-manager for this repo, but still wanted for other
  # people's stow-based dotfiles.
  stow
  hatch
  pipx
  claude-code

  oh-my-posh
  fzf
  eza
  bat
  ripgrep
  fd
  bottom
  zoxide
  tree-sitter
  atuin
  dua
  tealdeer
  stylua

  # General dev workflow — not installed anywhere before this pass.
  gh
  lazygit
  jq
  delta
  shellcheck
  just
  # Closes a real gap: conform.nvim formats css/html with this, but nothing
  # installed it anywhere.
  prettier
  # conform.nvim's C# formatter. quaisr/core has no dotnet-tools.json, so
  # conform's `dotnet csharpier` probe fails and it falls back to this one
  # on PATH -- which is the reason it's worth installing here at all.
  csharpier
  # vscode-html-language-server, which easy-dotnet bridges markup-backed
  # Razor requests to (completion/hover/formatting inside .razor markup);
  # without it Razor still opens, but those requests come back empty. Also
  # supplies the html/cssls servers nvim-lspconfig.lua enables, which until
  # now nothing actually installed.
  vscode-langservers-extracted

  # LaTeX, for building the CV in ~/dev/Resume. scheme-small plus exactly the
  # packages Matthew_Jones_CV.tex's preamble reaches for -- texliveFull is
  # ~7GB and this set is ~600MB. Two of these are named for their bundle
  # rather than the .sty the document asks for: fullpage.sty comes from
  # preprint, and footmisc is a dependency of ragged2e, not a direct import.
  (texliveSmall.withPackages (ps: with ps; [
    fontawesome
    preprint
    titlesec
    marvosym
    enumitem
    fancyhdr
    ragged2e
    footmisc
    microtype
    # scheme-small ships the engines but not the build driver; latexmk runs
    # pdflatex the two-or-three times hyperref's .out file needs.
    latexmk
  ]))

  # Referenced by alacritty/alacritty.toml. home-manager symlinks font
  # packages into ~/Library/Fonts on macOS automatically; on Linux it's
  # picked up via fontconfig.
  nerd-fonts.jetbrains-mono
]
# On macOS, Alacritty is in nix/hosts/darwin.nix's environment.systemPackages
# so it lands in /Applications/Nix Apps like the other GUI apps.
++ lib.optional pkgs.stdenv.hostPlatform.isLinux alacritty
