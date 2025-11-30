RAKHSH_HOME=$(realpath $(readlink ~/.zshrc.d/rakhsh.zsh)/../..)
for rc in ${RAKHSH_HOME}/dot.d/dot.zshrc.d/*(N); do source "$rc"; done
