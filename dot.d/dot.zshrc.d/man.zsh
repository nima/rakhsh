man() {
  command man "$@" \
    | col -bx \
    | bat --language=man --plain --paging=always --color=always
}
