UTIL := fzf
PLUG := fugitive ctrlp vim-table-mode fzf vim-polyglot lightline

START := $(HOME)/.vim/pack/plugins/start
OPT := /opt/github
BUILD := $(UTIL:%=$(OPT)/%) $(PLUG:%=$(START)/%)
install: $(BUILD)

$(START):; mkdir -p $(STORE)/opt $(STORE)/start
$(START)/fugitive:; git clone --depth=1 https://tpope.io/vim/fugitive.git $@
$(START)/ctrlp:; git clone --depth=1 https://github.com/ctrlpvim/ctrlp.vim.git $@
$(START)/vim-table-mode:; git clone --depth=1 https://github.com/dhruvasagar/vim-table-mode.git $@
$(START)/fzf:; git clone --depth=1 https://github.com/junegunn/fzf.vim.git $@
$(START)/vim-polyglot:; git clone --depth=1 https://github.com/sheerun/vim-polyglot.git $@
$(START)/lightline:; git clone --depth=1 https://github.com/itchyny/lightline.vim $@
$(OPT)/fzf:; git clone --depth=1 https://github.com/junegunn/fzf.git $@

purge:; rm -rf $(START) $(UTIL:%=$(OPT)/%)

