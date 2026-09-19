# NvChad's own plugin manager (lazy.nvim) and mason keep managing plugins/LSPs
# at runtime exactly as before — Nix's job is just to place the config files
# and install neovim itself, then replay the same headless bootstrap that
# install.sh's install_nv_chad used to run.
#
# lazy-lock.json is deliberately NOT symlinked into the Nix store like the
# rest of the config: lazy.nvim rewrites it whenever plugin versions change,
# and a store path is read-only. Instead it's copied once (seeded) so a fresh
# machine starts from the version committed to the repo, then left alone so
# `:Lazy` can update it locally. After a plugin update, copy it back:
#   cp ~/.config/nvim/lazy-lock.json ~/.dotfiles/nvim/lazy-lock.json
{ pkgs, lib, config, ... }:

{
  home.file.".vimrc".source = ../../vim/.vimrc;

  xdg.configFile = {
    "nvim/init.lua".source = ../../nvim/init.lua;
    "nvim/.stylua.toml".source = ../../nvim/.stylua.toml;
    "nvim/lua" = {
      source = ../../nvim/lua;
      recursive = true;
    };
  };

  home.activation.seedNvimLockfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/nvim/lazy-lock.json"
    if [ ! -e "$target" ]; then
      $DRY_RUN_CMD install -m 0644 ${../../nvim/lazy-lock.json} "$target"
    fi
  '';

  # easy-dotnet.nvim's backend is a C# JSON-RPC server shipped as a dotnet
  # global tool, so neither lazy.nvim nor nixpkgs can supply it. Installing it
  # here keeps `install.sh` a single command on a new machine. It lands in
  # ~/.dotnet/tools, already on home.sessionPath.
  #
  # Only installed if absent — `dotnet tool update --global EasyDotnet` is
  # left to you, the same way lazy-lock.json is seeded once and then left
  # alone. Deliberately non-fatal: it needs the network, and a switch
  # shouldn't fail offline.
  home.activation.easyDotnetTool = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Reuses the DOTNET_ROOT default.nix computes, so the SDK referenced here
    # can't drift from the one on PATH.
    export DOTNET_ROOT="${config.home.sessionVariables.DOTNET_ROOT}"
    export PATH="$DOTNET_ROOT:$PATH"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    if ! dotnet tool list --global 2>/dev/null | grep -qi '^easydotnet '; then
      $DRY_RUN_CMD dotnet tool install --global EasyDotnet ||
        echo "warning: could not install the EasyDotnet tool (easy-dotnet.nvim's backend); run 'dotnet tool install --global EasyDotnet' once online"
    fi
  '';

  home.activation.nvchadSetup = lib.hm.dag.entryAfter [ "seedNvimLockfile" "easyDotnetTool" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    $DRY_RUN_CMD ${pkgs.neovim}/bin/nvim --headless \
      -c "lua require('lazy').restore()" \
      -c "lua require('lazy').load({ plugins = { 'ui', 'base46', 'nvim-treesitter' } })" \
      -c "lua require('nvchad.mason').install_all()" \
      -c "lua require('nvim-treesitter.install').update({ with_sync = true })" \
      -c "lua require('base46').load_all_highlights()" \
      -c "qa"
  '';
}
