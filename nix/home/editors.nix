# NvChad's own plugin manager (lazy.nvim) and mason keep managing plugins/LSPs
# at runtime exactly as before — Nix's job is just to place the config files
# and install neovim itself, then replay the same headless bootstrap that
# install.sh's install_nv_chad used to run.
#
# Config files link straight to the repo rather than the Nix store, so an edit
# is live without a rebuild, and lazy.nvim writes lazy-lock.json back into the
# repo itself.
{ pkgs, lib, config, ... }:

{
  home.file.".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/vim/.vimrc";
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/nvim";

  # easy-dotnet.nvim's backend is a C# JSON-RPC server shipped as a dotnet
  # global tool, so neither lazy.nvim nor nixpkgs can supply it. Installing it
  # here keeps `bootstrap.sh` a single command on a new machine. It lands in
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

  home.activation.nvchadSetup = lib.hm.dag.entryAfter [ "easyDotnetTool" ] ''
    if [ ! -d "$HOME/.local/share/nvim/lazy" ]; then
      export PATH="${pkgs.git}/bin:$PATH"
      $DRY_RUN_CMD ${pkgs.neovim}/bin/nvim --headless \
        -c "lua require('lazy').restore()" \
        -c "lua require('lazy').load({ plugins = { 'ui', 'base46', 'nvim-treesitter' } })" \
        -c "lua require('nvchad.mason').install_all()" \
        -c "lua require('nvim-treesitter.install').update({ with_sync = true })" \
        -c "lua require('base46').load_all_highlights()" \
        -c "qa"
    fi
  '';
}
