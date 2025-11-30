.DEFAULT_GOAL := sync

BLACK   := \033[1;30m
RED     := \033[1;31m
GREEN   := \033[1;32m
YELLOW  := \033[1;33m
BLUE    := \033[1;34m
MAGENTA := \033[1;35m
CYAN    := \033[1;36m
ENDC    := \033[0m

black   = $(shell echo "$(BLACK)$(1)$(ENDC)")
red     = $(shell echo "$(RED)$(1)$(ENDC)")
green   = $(shell echo "$(GREEN)$(1)$(ENDC)")
yellow  = $(shell echo "$(YELLOW)$(1)$(ENDC)")
blue    = $(shell echo "$(BLUE)$(1)$(ENDC)")
magenta = $(shell echo "$(MAGENTA)$(1)$(ENDC)")
cyan    = $(shell echo "$(CYAN)$(1)$(ENDC)")

good  = $(shell echo "$(GREEN)$(1)$(ENDC)")
bad   = $(shell echo "$(RED)$(1)$(ENDC)")
ugly  = $(shell echo "$(UGLY)$(1)$(ENDC)")

luarocks_t = $(shell echo "[$(CYAN)LuaRocks$(ENDC)]")
brew_t     = $(shell echo "[$(YELLOW)Brew$(ENDC)]")
npm_t      = $(shell echo "[$(GREEN)NPM$(ENDC)]")

export NVIM_APPNAME=rakhsh
nvim := NVIM_APPNAME=rakhsh $(shell command -v nvim)

cache = $(shell mkdir -p /tmp/$(NVIM_APPNAME); echo "/tmp/rakhsh.$(1)")

ITERM2_PLIST    := $(HOME)/Library/Preferences/com.googlecode.iterm2.plist
ITERM2_DYN_PROF := $(HOME)/Library/Application Support/iTerm2/DynamicProfiles/rakhsh.json

RAKHSH_CONFIG := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("config"))' +qa)
RAKHSH_DATA   := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("data"))'   +qa)
RAKHSH_STATE  := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("state"))'  +qa)
RAKHSH_CACHE  := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("cache"))'  +qa)
RAKHSH_SOCKET := $(RAKHSH_STATE)/server.pipe
RAKHSH_LAZY   := $(RAKHSH_DATA)/lazy
RAKHSH_ZSHRC  := $(PWD)/dot.d/dot.zshrc

brew     := $(shell command -v brew || exit 2)
luarocks := $(shell command -v luarocks || exit 1)
npm      := $(shell command -v npm || exit 1)
teal     := $(shell command -v tl)
tlchk    := $(shell command -v libexec/tlchk)
find     := $(shell command -v find)
rakhsh   := $(shell command -v $(PWD)/bin/rx)

BREW_DIRTY     := $(call cache,BREW_DIRTY)
BREW_INSTALLED := $(call cache,BREW_INSTALLED)
BREW_OUTDATED  := $(call cache,BREW_OUTDATED)
${BREW_INSTALLED}:; @$(brew) list -q > $@
${BREW_OUTDATED}:; @$(brew) outdated -q > $@
define brew-install
	@if grep -Fqw $1 $(BREW_INSTALLED) 2>/dev/null; then\
	  if grep -Fqw $1 $(BREW_OUTDATED) 2>/dev/null; then\
	    printf "$(brew_t) Upgrading %s...\n" "$1";\
	    $(brew) upgrade $1;\
	    touch $(BREW_DIRTY);\
	  else\
	    printf "$(brew_t) %s...$(call good,GOOD)\n" "$1";\
	  fi;\
	else\
	  printf "$(brew_t) Installing %s...\n" "$1";\
	  $(brew) install $1;\
	  touch $(BREW_DIRTY);\
	fi
endef

BREWCASK_DIRTY     := $(call cache,BREWCASK_DIRTY)
BREWCASK_INSTALLED := $(call cache,BREWCASK_INSTALLED)
BREWCASK_OUTDATED  := $(call cache,BREWCASK_OUTDATED)
${BREWCASK_INSTALLED}:; @$(brew) list --casks > $@
${BREWCASK_OUTDATED}:; @$(brew) outdated --cask > $@
define brew-cask-install
	@$(brew) tap $1 >/dev/null 2>&1 || true;\
	if grep -Fqw $2 $(BREWCASK_INSTALLED) 2>/dev/null; then\
	  if grep -Fqw $2 $(BREWCASK_OUTDATED) 2>/dev/null; then\
	    printf "$(brew_t) Upgrading cask %s...\n" "$2";\
	    $(brew) upgrade --cask $2;\
	    touch $(BREWCASK_DIRTY);\
	  else\
	    printf "$(brew_t) cask %s...$(call good,GOOD)\n" "$2";\
	  fi;\
	else\
	  printf "$(brew_t) Installing cask %s...\n" "$2";\
	  $(brew) install --cask $2;\
	  touch $(BREWCASK_DIRTY);\
	fi
endef

LUAROCKS_DIRTY     := $(call cache,LUAROCKS_DIRTY)
LUAROCKS_INSTALLED := $(call cache,LUAROCKS_INSTALLED)
LUAROCKS_OUTDATED  := $(call cache,LUAROCKS_OUTDATED)
${LUAROCKS_INSTALLED}:; @printf "%s %s %s %s\n" $(shell $(luarocks) list --porcelain) > $@
${LUAROCKS_OUTDATED}:; @printf "%s %s %s %s\n" $(shell $(luarocks) list --outdated --porcelain) > $@
define luarocks-install
	@if grep -Fqw $1 $(LUAROCKS_INSTALLED) 2>/dev/null; then\
	  if grep -Fqw $1 $(LUAROCKS_OUTDATED) 2>/dev/null; then\
	    printf "$(luarocks_t) Upgrading %s...\n" "$1";\
	    $(luarocks) upgrade $1;\
	    touch $(LUAROCKS_DIRTY);\
	  else\
	    printf "$(luarocks_t) %s...$(call good,GOOD)\n" "$1";\
	  fi;\
	else\
	  printf "$(luarocks_t) Installing %s...\n" "$1";\
	  $(luarocks) install $1;\
	  touch $(LUAROCKS_DIRTY);\
	fi
endef

NPM_DIRTY     := $(call cache,NPM_DIRTY)
NPM_INSTALLED := $(call cache,NPM_INSTALLED)
NPM_OUTDATED  := $(call cache,NPM_OUTDATED)
${NPM_INSTALLED}:; @$(npm) list -g --depth=0 --parseable > $@
${NPM_OUTDATED}:; @$(npm) outdated -g --depth=0 --parseable > $@ || true
define npm-install
	@if grep -Fqw $1 $(NPM_INSTALLED) 2>/dev/null; then \
	  if grep -Fqw $1 $(NPM_OUTDATED) 2>/dev/null; then \
	    printf "$(npm_t) Upgrading %s...\n" "$1"; \
	    $(npm) install -g $1; \
	    touch $(NPM_DIRTY);\
	  else \
	    printf "$(npm_t) %s...$(call good,GOOD)\n" "$1"; \
	  fi; \
	else \
	  printf "$(npm_t) Installing %s...\n" "$1"; \
	  $(npm) install -g $1; \
	  touch $(NPM_DIRTY);\
	fi
endef

installed: $(BREW_INSTALLED) $(BREWCASK_INSTALLED) $(LUAROCKS_INSTALLED) $(NPM_INSTALLED)
.PHONY: installed

outdated: $(BREW_OUTDATED) $(BREWCASK_INSTALLED) $(LUAROCKS_OUTDATED) $(NPM_OUTDATED)
.PHONY: outdated

upgrade: dependencies
.PHONY: upgrade

################################################################################

post-install-cleanup = [ ! -e "$($(1)_DIRTY)" ] || rm -f "$($(1)_DIRTY)" "$($(1)_INSTALLED)" "$($(1)_OUTDATED)"

caches: /opt/homebrew/.git/HEAD
/tmp/.nonce: /opt/homebrew/.git/HEAD
	@$(call post-install-cleanup,BREW)
	@touch -r /opt/homebrew/.git/HEAD $@
/opt/homebrew/.git/HEAD:
.PHONY: caches

dependencies: caches installed outdated
	@#= NeoVim
	@$(call brew-install,coreutils)
	@$(call brew-install,neovim)
	@$(call brew-install,neovim-remote)
	@$(call brew-cask-install,homebrew/cask-fonts,font-jetbrains-mono-nerd-font)
	@#= CLI
	@$(call brew-install,fd)
	@$(call brew-install,rsync)
	@$(call brew-install,ripgrep)
	@$(call brew-install,lsd)
	@$(call brew-install,bat)
	@$(call brew-install,jq)
	@#= Bash
	@$(call brew-install,bash-language-server)    #+ Bash LSP
	@#= Python
	@$(call npm-install,pyright)                  #+ Python LSP
	@#= C++
	@$(call brew-install,llvm)
	@#= Lua & Teal
	@$(call brew-install,luarocks)
	@$(call luarocks-install,tl)
	@$(call luarocks-install,cyan)
	@$(call brew-install,lua-language-server)     #+ Lua LSP
	@#= Go
	@$(call brew-install,go)
	@#= Markdown
	@$(call brew-install,marksman)                #+ Python LSP
	@#= Internal
	@$(call post-install-cleanup,BREWCASK)
	@$(call post-install-cleanup,BREW)
	@$(call post-install-cleanup,LUAROCKS)
	@$(call post-install-cleanup,NPM)
.PHONY: dependencies

pre-validate: src/tl dependencies
	$(info [$(call magenta,$@)])
	@set -e; for f in $$(rg -g '*.tl' --files); do $(tlchk) -I$< "$$f"; done
.PHONY: pre-validate

build: pre-validate
	$(info [$(call blue,$@)])
	@rm -rf build
	@mkdir -p build
	@cyan build --prune > $(RAKHSH_CACHE)/cyan.log 2>&1 || { cat $(RAKHSH_CACHE)/cyan.log && exit 1; }
	@#rsync -ai --prune-empty-dirs --info=NAME0 --include "*/" --include="*.lua" --exclude="*" src/lua/ build/lua/
.PHONY: build

iTerm2.regex:; @jq -r '.Profiles[0]."Smart Selection Rules"[0].regex' "$(ITERM2_DYN_PROF)"
iTerm2:
	$(info [$(call green,$@)])
	@libexec/iTerm2-integ.py
.PHONY: iTerm2 iTerm2.regex

link:; @ln -sf $(RAKHSH_ZSHRC) ~/.zshrc.d/rakhsh.zshrc
.PHONY: link

$(RAKHSH_LAZY):; @bin/rx
install: $(RAKHSH_CONFIG) build iTerm2 $(RAKHSH_LAZY) link
	$(info [$(call green,$@)])

$(RAKHSH_CONFIG): build
	@#rsync -ai --info=NAME0 --delete $</ $@/
	@rsync -a --info=NAME0 --delete $</ $@/
	@mv $@/lua/init.lua $@/
	@mv $@/lua/after $@/
	@ln -sf $(PWD)/bin/rx ~/bin/rx
.PHONY: install

sync: $(RAKHSH_CONFIG) link
	$(info [$(call green,$@)])
.PHONY: sync

post-validate: install
	$(info [$(call magenta,$@)])
	@$(nvim) --headless +'lua print(vim.inspect(vim.fn.maparg("K", "n", false, true)))' +qa
	@$(nvim) --headless "+lua local ok,u = pcall(require,'core.utils');\
	  if not ok then error('Rakhsh post-validate: require(\"core.utils\") failed: '..tostring(u)) end;\
	  if type(u.validate_keymaps) ~= 'function' then\
	    error('Rakhsh post-validate: core.utils.validate_keymaps() is not implemented (dev TODO)');\
	  end;\
	  u.validate_keymaps()" \
	+qa
	@#$(nvim) --headless -u $(RAKHSH_CONFIG)/init.lua "+quit" || exit 1
	@#$(nvim) --headless -u $(RAKHSH_CONFIG)/init.lua "+checkhealth" "+qa" > /tmp/nvim.log
	@#grep "ERROR" /tmp/nvim.log && exit 1 || exit 0
	@#$(find) $(RAKHSH_CONFIG) -type f -name "*.lua" -print0\
		| xargs -0 -I{} $(nvim) --headless -c "luafile {}" -c "qa"\
		|| exit 1
.PHONY: post-validate

purgeinstall: purge post-validate
.PHONY: purgeinstall

reinstall: uninstall post-validate
.PHONY: reinstall

unlink:; rm -f ~/.zshrc.d/rakhsh.zshrc
.PHONY: unlink

uninstall: clean unlink
	$(info [$(call black,$@)])
	rm -f "$(ITERM2_DYN_PROF)"
	rm -rf $(RAKHSH_CONFIG)
	rm -f ~/bin/rx
.PHONY: uninstall

purge: uninstall
	$(info [$(call black,$@)])
	rm -rf $(RAKHSH_DATA)
	rm -rf $(RAKHSH_CONFIG)
	rm -rf $(RAKHSH_SOCKET)
.PHONY: purge

clean:
	$(info [$(call yellow,$@)])
	rm -rf build
.PHONY: clean

################################################################################

ide: reinstall
	$(info [$(call yellow,$@)])
	$(info [$(call green,$@)])
	$(rx)

lazy:
	$(info [$(call magenta,$@)])
	$(info [$(call magenta,$@)])
	lsd --tree "$$($(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("data"), "\n")' +qa)/lazy"

ls-files:
	$(info [$(call magenta,$@)])
	$(info Typed TEAL)
	@lsd --tree src/tl
ls-files.user:
	$(info [$(call magenta,$@)])
	$(info Installed LUA)
	@lsd --tree "$(RAKHSH_CONFIG)"
.PHONY: ls-files ls-files.user

state: pid := $(shell lsof -t $(RAKHSH_SOCKET) 2>/dev/null)
state:
	$(info [$(call magenta,$@)])
	@printf "%-24s" "Socket:"
	@[ -e $(RAKHSH_SOCKET) ] && echo "$(call green,$(RAKHSH_SOCKET))" || echo "$(call black,$(RAKHSH_SOCKET))"
	@printf "%-24s" "PID:"
	@[ -n "$(pid)" ] && echo "$(call green,$(pid))" || echo "$(call black,000)"
	@printf "%-24s" "Buffers:"
	@n=0; [ ! -S $(RAKHSH_SOCKET) ] || n=$$(nvim --server $(RAKHSH_SOCKET) --headless --remote-expr "len(getbufinfo({'buflisted':1}))"); echo "$$n"
.PHONY: state

killsocket: pid := $(shell lsof -t $(RAKHSH_SOCKET) 2>/dev/null)
killsocket:
	$(info [$(call magenta,$@)])
	kill -9 $(pid)

fonts:
	sudo rm -rf /Library/Fonts/*Cache*
	sudo rm -rf /System/Library/Fonts/*Cache*
	rm -rf ~/Library/Fonts/*Cache*
	rm -rf ~/Library/Caches/com.apple.FontServices
	rm -rf ~/Library/Caches/com.apple.coretext*
	sudo rm -rf /Library/Caches/com.apple.FontServices*
	sudo rm -rf /Library/Caches/com.apple.coretext*
