[[ -f ~/.lastdir ]] && cd "$(cat ~/.lastdir)"
chpwd() { pwd > ~/.lastdir }
