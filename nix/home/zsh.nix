# zinit still bootstraps and manages zsh plugins itself (git clone on first
# run, same as before) — Nix's job here is just installing the binaries this
# file's PATH/eval lines depend on (fzf, zoxide, oh-my-posh, eza, ...) and
# placing the file itself, replacing what stow used to do.
{ ... }:

{
  programs.zsh = {
    enable = true;
    initContent = builtins.readFile ../../zsh/.zshrc;
  };
}
