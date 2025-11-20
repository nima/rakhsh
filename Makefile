.DEFAULT_GOAL := sync


GREEN  := \033[32m
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
CYAN   := \033[36m
ENDC   := \033[0m

good  = $(shell echo "$(GREEN)$(1)$(ENDC)")
bad   = $(shell echo "$(RED)$(1)$(ENDC)")
ugly  = $(shell echo "$(UGLY)$(1)$(ENDC)")

cache = $(shell mkdir -p /tmp/rakhsh; echo "/tmp/rakhsh.$(1)")

luarocks_t = $(shell echo "[$(CYAN)LuaRocks$(ENDC)]")
brew_t     = $(shell echo "[$(YELLOW)Brew$(ENDC)]")
npm_t      = $(shell echo "[$(GREEN)NPM$(ENDC)]")

export NVIM_APPNAME=rakhsh
nvim := NVIM_APPNAME=rakhsh $(shell command -v nvim)

RAKHSH        := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("config"))' +qa)
RAKHSH_CONFIG := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("config"))' +qa)
RAKHSH_DATA   := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("data"))'   +qa)
RAKHSH_STATE  := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("state"))'  +qa)
RAKHSH_CACHE  := $(shell $(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("cache"))'  +qa)

ITERM2_PLIST := $(HOME)/Library/Preferences/com.googlecode.iterm2.plist

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

installed: $(BREW_INSTALLED) $(LUAROCKS_INSTALLED) $(NPM_INSTALLED)
.PHONY: installed

outdated: $(BREW_OUTDATED) $(LUAROCKS_OUTDATED) $(NPM_OUTDATED)
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
	@$(call post-install-cleanup,BREW)
	@$(call post-install-cleanup,LUAROCKS)
	@$(call post-install-cleanup,NPM)
.PHONY: dependencies

pre-validate: src/tl dependencies
	$(info # target:$@)
	@set -e; for f in $$(rg -g '*.tl' --files); do $(tlchk) -I$< "$$f"; done
.PHONY: pre-validate

build: pre-validate
	$(info # target:$@)
	@rm -rf build
	@mkdir -p build
	@cyan build --prune
	@#rsync -ai --prune-empty-dirs --info=NAME0 --include "*/" --include="*.lua" --exclude="*" src/lua/ build/lua/
.PHONY: build

iTerm2: $(ITERM2_PLIST).xml
$(ITERM2_PLIST).xml $(ITERM2_PLIST).bak:
	@libexec/it2integ.sh
	@#osascript -e 'tell application "iTerm2" to quit' && open -a iTerm
.PHONY: iTerm2

install: $(RAKHSH) build $(ITERM2_PLIST).xml $(ITERM2_PLIST).bak
	$(info # target:$@)
sync: $(RAKHSH)
$(RAKHSH): build
	@#rsync -ai --info=NAME0 --delete $</ $@/
	@rsync -a --info=NAME0 --delete $</ $@/
	@mv $@/lua/init.lua $@/
	@mv $@/lua/after $@/
	@ln -sf $(PWD)/bin/rx ~/bin/rx
.PHONY: install
.PHONY: sync

post-validate: install
	$(info # target:$@)
	@$(nvim) --headless +'lua print(vim.inspect(vim.fn.maparg("K", "n", false, true)))' +qa
	@$(nvim) --headless "+lua local ok,u = pcall(require,'core.utils');\
	  if not ok then error('Rakhsh post-validate: require(\"core.utils\") failed: '..tostring(u)) end;\
	  if type(u.validate_keymaps) ~= 'function' then\
	    error('Rakhsh post-validate: core.utils.validate_keymaps() is not implemented (dev TODO)');\
	  end;\
	  u.validate_keymaps()" \
	+qa
	@#$(nvim) --headless -u $(RAKHSH)/init.lua "+quit" || exit 1
	@#$(nvim) --headless -u $(RAKHSH)/init.lua "+checkhealth" "+qa" > /tmp/nvim.log
	@#grep "ERROR" /tmp/nvim.log && exit 1 || exit 0
	@#$(find) $(RAKHSH) -type f -name "*.lua" -print0\
		| xargs -0 -I{} $(nvim) --headless -c "luafile {}" -c "qa"\
		|| exit 1
.PHONY: post-validate


reinstall: uninstall clean post-validate
.PHONY: reinstall

uninstall:
	$(info # target:$@)
	rm -rf $(RAKHSH)
	rm -f ~/bin/rx
.PHONY: uninstall

purge: clean uninstall
	rm -rf $(RAKHSH_DATA)
	rm -rf $(RAKHSH_CONFIG)
	rm -rf $(RAKHSH_STATE)/server.pip
	@if [ -e $(ITERM2_PLIST).bak ] && [ -e $(ITERM2_PLIST).xml ]; then\
		mv $(ITERM2_PLIST).bak $(ITERM2_PLIST);\
		rm $(ITERM2_PLIST).xml;\
	fi
.PHONY: purge

clean:
	$(info # target:$@)
	rm -rf build
.PHONY: clean

################################################################################

ide: reinstall
	$(rx)

lazy:
	lsd --tree "$$($(nvim) --headless --clean +'lua io.stdout:write(vim.fn.stdpath("data"), "\n")' +qa)/lazy"

ls-files:
	$(info Typed TEAL)
	@lsd --tree src/tl
ls-files.user:
	$(info Installed LUA)
	@lsd --tree "$(RAKHSH_CONFIG)"
.PHONY: ls-files ls-files.user
