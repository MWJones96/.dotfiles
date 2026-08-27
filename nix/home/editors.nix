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
{ pkgs, lib, ... }:

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

  home.activation.nvchadSetup = lib.hm.dag.entryAfter [ "seedNvimLockfile" ] ''
    $DRY_RUN_CMD ${pkgs.neovim}/bin/nvim --headless \
      -c "lua require('lazy').restore()" \
      -c "lua require('lazy').load({ plugins = { 'ui', 'nvim-treesitter' } })" \
      -c "lua require('nvchad.mason').install_all()" \
      -c "lua require('nvim-treesitter.install').update({ with_sync = true })" \
      -c "qa"
  '';
}
