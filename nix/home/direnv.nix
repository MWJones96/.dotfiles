# Lets a project auto-load its own dev environment (a local flake.nix/.envrc)
# the instant you `cd` into it, and unload it on the way out — the answer to
# "how do I get a specific toolchain/Python version for just this project"
# without touching global config. nix-direnv adds Nix-aware caching so
# repeated `cd`s don't re-evaluate the flake every time.
{ ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
