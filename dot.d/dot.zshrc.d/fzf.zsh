if [[ ! "$PATH" == */Users/k34446/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/Users/k34446/.fzf/bin"
fi
source <(fzf --zsh)

fzf-rg-search-widget() {
  # Split the CLI buffer: keep everything before the last space as prefix, use final token as query
  local prefix query
  if [[ "$LBUFFER" == *" "* ]]; then
    prefix="${LBUFFER% *}"
    query="${LBUFFER##* }"
  else
    prefix="$LBUFFER"
    query=""
  fi

  local selected_file

  # Launch fzf with a bind command that reloads the rg search on every change in the fzf input
  selected_file=$(
    fzf --ansi --tiebreak=index --no-sort --border \
        --prompt="Ripgrep > " \
        --bind="change:reload(rg --column --line-number --no-heading --color=always --smart-case {q} || true)" \
        --preview='FILE=$(echo {1} | cut -d: -f1); if command -v bat >/dev/null 2>&1; then bat --color=always --style=numbers "$FILE"; else cat "$FILE"; fi' \
        --phony --query="$query"
  )

  # If file selected, insert its path into cli buffer
  if [[ -n "$selected_file" ]]; then
    LBUFFER="${prefix} $(echo "$selected_file" | awk -F: '{print $1}')"
    zle accept-line # execute the command immediately (in case in `vim <search-term>` already)
  fi
}
zle -N fzf-rg-search-widget
bindkey '^X' fzf-rg-search-widget

fzf-git-grep-p-widget() {
  # Split the CLI buffer: keep everything before the last space as prefix, use final token as query
  local prefix query
  if [[ "$LBUFFER" == *" "* ]]; then
    prefix="${LBUFFER% *}"
    query="${LBUFFER##* }"
  else
    prefix="$LBUFFER"
    query=""
  fi

  local selected_file

  selected_file=$(
    fzf --ansi --tiebreak=index --no-sort --border \
        --prompt="Git Grep -P > " \
        --bind="change:reload(git grep -lP --color=always {q} || true)" \
        --preview='FILE=$(echo {1} | cut -d: -f1); if command -v bat >/dev/null 2>&1; then bat --color=always --style=numbers "$FILE"; else cat "$FILE"; fi' \
        --phony --query="$query"
  )

  if [[ -n "$selected_file" ]]; then
    LBUFFER="${prefix} $(echo "$selected_file" | awk -F: '{print $1}')"
    zle accept-line # execute the command immediately (in case in `vim <search-term>` already)
  fi
}
zle -N fzf-git-grep-p-widget
bindkey '^G' fzf-git-grep-p-widget

export FZF_CTRL_T_COMMAND='fd . --type f --hidden --follow --exclude .git -x stat -f "%m %N" | sort -rn | cut -d" " -f2-'
