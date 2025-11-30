function _bind_hist_search_keys() {
  local -a maps=(emacs viins vicmd)

  local up_norm=$'\e[A'   # ^[[A
  local dn_norm=$'\e[B'   # ^[[B
  local up_app=$'\eOA'    # ^[OA
  local dn_app=$'\eOB'    # ^[OB

  local map
  for map in $maps; do
    bindkey -M $map "$up_norm" history-beginning-search-backward
    bindkey -M $map "$up_app"  history-beginning-search-backward

    bindkey -M $map "$dn_norm" history-beginning-search-forward
    bindkey -M $map "$dn_app"  history-beginning-search-forward
  done
}

bindkey -e

#+ make sure this runs *after* bindkey -v / bindkey -e
_bind_hist_search_keys
