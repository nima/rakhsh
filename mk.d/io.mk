pkgs-import.arm64: ~/Vaults/Cristobalite/staging
	cat $(wildcard $</chunk-*) >/tmp/superchunk
	chmod +x /tmp/superchunk
	/tmp/superchunk
	#! rsync -Pa cache/ "$($(brew) --cache)/

pkgs-export.arm64: /tmp/brew_installer_arm64.run
	rm -rf /tmp/staging
	mkdir /tmp/staging
	split -b 5M $< /tmp/staging/chunk-
	sync
	rm -rf ~/Vaults/Cristobalite/staging
	mv /tmp/staging ~/Vaults/Cristobalite/
/tmp/brew_installer_arm64.run:
	libexec/mk-installer arm64 llvm neovim neovim-remote fd ripgrep rsync jq lsd bat lua-language-server go bash-language-server marksman
	mv brew_installer_arm64.run $@


