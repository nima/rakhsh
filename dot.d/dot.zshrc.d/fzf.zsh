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

if ! zle -l | grep -q fzf-git-grep-p-widget; then
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
fi

export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --follow --exclude=.git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type=d"
export FZF_ALT_C_OPTS="--preview 'lsd --tree --color=always {} | head -n200'"
_fzf_compgen_path() { fd --hidden --exclude=.git . "$1"; }
_fzf_compgen_dir() { fd --type=d --hidden --exclude=.git . "$1"; }
