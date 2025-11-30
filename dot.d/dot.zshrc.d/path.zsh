path=(
  "${HOME}/bin"
  "/opt/homebrew/bin"
  "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  "${PATH}"
)
typeset -U path
export PATH="${(j/:/)path[@]}"

