#!/usr/bin/env bash
input=$(cat)
dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
branch=$(git -C "${dir:-.}" --no-optional-locks branch --show-current 2>/dev/null)

jq -r --arg branch "$branch" '
  def color($p): if $p == null then . elif $p >= 90 then "\u001b[31m\(.)\u001b[0m"
    elif $p >= 70 then "\u001b[33m\(.)\u001b[0m" else . end;
  def pct: . as $p | (if $p == null then "--" else "\($p | round)%" end) | color($p);
  def pad: tostring | if length < 2 then "0" + . else . end;
  def resets_in:
    if . == null then ""
    else ([. - now, 0] | max | floor / 60 | floor) as $m
      | " (resets in \($m / 60 | floor):\($m % 60 | pad))"
    end;
  def resets_on:
    if . == null then "" else " (resets \(localtime | strftime("%a %H:%M")))" end;
  [
    (.model.display_name // empty),
    (if $branch != "" then "⎇ \($branch)" else empty end),
    "ctx \(.context_window.used_percentage | pct)",
    "5h \(.rate_limits.five_hour.used_percentage | pct)\(.rate_limits.five_hour.resets_at | resets_in)",
    "7d \(.rate_limits.seven_day.used_percentage | pct)\(.rate_limits.seven_day.resets_at | resets_on)"
  ] | join(" │ ")
' <<<"$input"
