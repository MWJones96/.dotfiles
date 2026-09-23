{ pkgs, lib, ... }:

{
  home.file = {
    ".claude/CLAUDE.md".source = ../../claude/CLAUDE.md;
    ".claude/statusline.sh".source = ../../claude/statusline.sh;
  };

  home.activation.mergeClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.claude/settings.json"
    if [ -z "''${DRY_RUN:-}" ]; then
      mkdir -p "$HOME/.claude"
      [ -e "$target" ] || echo '{}' > "$target"
      merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" ${../../claude/settings.json})
      printf '%s\n' "$merged" > "$target"
    fi
  '';
}
