DEV_OHMYZSH_DIR := ~/.dotfiles/oh-my-zsh

dev-setup: ## Provision your MacBook (and become a DevOps ninja) - optional: REINSTALL=true
	rm -f $(SETUP_COMPLETE_FLAG_FILE)
	make dev-disable-gatekeeper
	make \
		dev-prepare \
		dev-update \
		dev-install-essential \
		dev-install-additional \
		dev-install-corporate \
		dev-check \
		dev-config \
		dev-fix \
		dev-info
	make dev-enable-gatekeeper
	touch $(SETUP_COMPLETE_FLAG_FILE)

dev-prepare:: ## Prepare for installation and configuration of the development dependencies
	sudo chown -R $$(id -u) $$(brew --prefix)/*

dev-update:: ## Update all currently installed development dependencies
	which mas > /dev/null 2>&1 || brew install mas
	mas upgrade $(mas list | grep -i xcode | awk '{ print $1 }')
	brew update
	brew upgrade
	brew tap buo/cask-upgrade
	brew cu --all --yes

dev-install-essential:: ## Install essential development dependencies - optional: REINSTALL=true
	install="install"
	if [[ "$$REINSTALL" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		install="reinstall --force"
	fi
	brew update
	brew tap blendle/blendle
	brew tap buo/cask-upgrade
	brew tap homebrew/cask-fonts
	brew tap homebrew/cask-versions
	brew $$install ack ||:
	brew $$install aws-iam-authenticator ||:
	brew $$install awscli ||:
	brew $$install bash ||:
	brew $$install coreutils ||:
	brew $$install dive ||:
	brew $$install findutils ||:
	brew $$install gawk ||:
	brew $$install git ||:
	brew $$install gnu-sed ||:
	brew $$install gnu-tar ||:
	brew $$install gnutls ||:
	brew $$install go ||:
	brew $$install gpg ||:
	brew $$install gradle ||:
	brew $$install grep ||:
	brew $$install httpie ||:
	brew $$install jenv ||:
	brew $$install jq ||:
	brew $$install kns ||:
	brew $$install kustomize ||:
	brew $$install make ||:
	brew $$install mas ||:
	brew $$install nvm ||:
	brew $$install pyenv ||:
	brew $$install pyenv-virtualenv ||:
	brew $$install pyenv-which-ext ||:
	brew $$install python ||:
	brew $$install shellcheck ||:
	brew $$install terraform ||:
	brew $$install tmux ||:
	brew $$install tree ||:
	brew $$install zsh ||:
	brew $$install zsh-autosuggestions ||:
	brew $$install zsh-completions ||:
	brew $$install zsh-syntax-highlighting ||:
	brew cask $$install docker ||:
	brew cask $$install font-hack-nerd-font ||:
	brew cask $$install iterm2 ||:
	brew cask $$install java ||:
	brew cask $$install visual-studio-code ||:
	# maven depends on java
	brew $$install maven ||:

dev-install-additional:: ## Install additional development dependencies - optional: REINSTALL=true
	install="install"
	if [[ "$$REINSTALL" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		install="reinstall --force"
	fi
	brew update
	brew cask $$install appcleaner ||:
	brew cask $$install atom ||:
	brew cask $$install bettertouchtool ||:
	brew cask $$install dbeaver-community ||:
	brew cask $$install dcommander ||:
	brew cask $$install drawio
	brew cask $$install firefox-developer-edition ||:
	brew cask $$install gimp ||:
	brew cask $$install gitkraken ||:
	brew cask $$install google-chrome ||:
	brew cask $$install hammerspoon ||:
	brew cask $$install intellij-idea-ce ||:
	brew cask $$install istat-menus ||:
	brew cask $$install karabiner-elements ||:
	brew cask $$install keepingyouawake ||:
	brew cask $$install postman ||:
	brew cask $$install pycharm ||:
	brew cask $$install smartgit ||:
	brew cask $$install spectacle ||:
	brew cask $$install tripmode ||:
	brew cask $$install tunnelblick ||:
	brew cask $$install vanilla ||:
	brew cask $$install vlc ||:
	brew cask $$install wifi-explorer ||:
	# Pinned package: vagrant
	brew cask reinstall --force \
		https://raw.githubusercontent.com/Homebrew/homebrew-cask/ae2a540ffee555491ccbb2cefa4296c76355ef9f/Casks/vagrant.rb ||:
	# Pinned package: virtualbox
	brew cask reinstall --force \
		https://raw.githubusercontent.com/Homebrew/homebrew-cask/33de1ad39862b4d31528e62f931480c1ba8a90f8/Casks/virtualbox.rb ||:
	# Pinned package: virtualbox-extension-pack
	brew cask reinstall --force \
		https://raw.githubusercontent.com/Homebrew/homebrew-cask/5a0a2b2322e35ec867f6633ca985ee485255f0b1/Casks/virtualbox-extension-pack.rb ||:

dev-install-corporate:: ## Install corporate dependencies - optional: REINSTALL=true
	install="install"
	if [[ "$$REINSTALL" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		install="reinstall --force"
	fi
	brew update
	brew cask $$install microsoft-office ||:
	brew cask $$install microsoft-teams ||:
	brew cask $$install skype-for-business ||:
	brew cask $$install slack ||:
	brew cask $$install vmware-horizon-client ||:
	brew cask $$install avast-security ||:

dev-check:: ## Check if the development dependencies are installed
	# Essential dependencies
	mas list | grep -i "xcode" ||:
	brew list ack ||:
	brew list aws-iam-authenticator ||:
	brew list awscli ||:
	brew list bash ||:
	brew list coreutils ||:
	brew list dive ||:
	brew list findutils ||:
	brew list gawk ||:
	brew list git ||:
	brew list gnu-sed ||:
	brew list gnu-tar ||:
	brew list gnutls ||:
	brew list go ||:
	brew list gpg ||:
	brew list gradle ||:
	brew list grep ||:
	brew list httpie ||:
	brew list jenv ||:
	brew list jq ||:
	brew list kns ||:
	brew list kustomize ||:
	brew list make ||:
	brew list mas ||:
	brew list maven ||:
	brew list nvm ||:
	brew list pyenv ||:
	brew list pyenv-virtualenv ||:
	brew list pyenv-which-ext ||:
	brew list python ||:
	brew list shellcheck ||:
	brew list terraform ||:
	brew list tmux ||:
	brew list tree ||:
	brew list zsh ||:
	brew list zsh-autosuggestions ||:
	brew list zsh-completions ||:
	brew list zsh-syntax-highlighting ||:
	brew cask list docker ||:
	brew cask list font-hack-nerd-font ||:
	brew cask list iterm2 ||:
	brew cask list visual-studio-code ||:
	# Additional dependencies
	brew cask list atom ||:
	brew cask list dbeaver-community ||:
	brew cask list drawio ||:
	brew cask list gitkraken ||:
	brew cask list google-chrome ||:
	brew cask list intellij-idea-ce ||:
	brew cask list java ||:
	brew cask list keepingyouawake ||:
	brew cask list postman ||:
	brew cask list pycharm ||:
	brew cask list smartgit ||:
	brew cask list spectacle ||:
	brew cask list tunnelblick ||:

dev-config:: ## Configure development dependencies
	make \
		_dev-config-mac \
		_dev-config-zsh \
		_dev-config-oh-my-zsh \
		_dev-config-iterm2 \
		_dev-config-visual-studio-code \
		_dev-config-visual-studio-code-disable-java-extensions \
		_dev-config-command-line

dev-fix:: ## Fix development dependencies
	make _dev-fix-vagrant-virtualbox

dev-info: ## Show "Setting up your macOS using Make DevOps" manual
	info=$(LIB_DIR)/macos/README.md
	html=$(TMP_DIR)/make-devops-doc-$(shell echo $$info | md5sum | cut -c1-7).html
	perl $(BIN_DIR)/markdown.pl --html4tags $$info > $$html
	cp -f $$html ~/Desktop/Setting\ up\ your\ macOS\ using\ Make\ DevOps.html
	open -a "Safari" ~/Desktop/Setting\ up\ your\ macOS\ using\ Make\ DevOps.html

dev-disable-gatekeeper:: ## Disable Gatekeeper
	sudo spctl --master-disable

dev-enable-gatekeeper:: ## Enable Gatekeeper
	sudo spctl --master-enable

# ==============================================================================

_dev-config-mac:
	sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
	networksetup -setdnsservers Wi-Fi 8.8.8.8
	defaults write -g com.apple.trackpad.scaling -float 5.0
	defaults write -g com.apple.mouse.scaling -float 5.0
	defaults write -g InitialKeyRepeat -int 15
	defaults write -g KeyRepeat -int 2

_dev-config-zsh:
	cat /etc/shells | grep $$(brew --prefix)/bin/zsh > /dev/null 2>&1 || sudo sh -c "echo $$(brew --prefix)/bin/zsh >> /etc/shells"
	chsh -s $$(brew --prefix)/bin/zsh

_dev-config-oh-my-zsh:
	ZSH=$(DEV_OHMYZSH_DIR) sh -c "$$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended ||:
	git clone https://github.com/romkatv/powerlevel10k.git $(DEV_OHMYZSH_DIR)/custom/themes/powerlevel10k ||:
	cp ~/.zshrc ~/.zshrc.bak.$$(date -u +"%Y%m%d%H%M%S") ||:
	find ~/ -maxdepth 1 -type f -mtime +3 -name '.zshrc.bak.*' -execdir rm -- '{}' \;
	cat ~/.zshrc | grep -Ev '^plugins=(.*)' > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
	make file-remove-content FILE=~/.zshrc CONTENT="\nsource (.)*/oh-my-zsh.sh\n"
	make file-remove-content FILE=~/.zshrc CONTENT="\n# BEGIN: Custom configuration(.)*# END: Custom configuration\n"
	echo -e "\n# BEGIN: Custom configuration" >> ~/.zshrc
	echo "plugins=(" >> ~/.zshrc
	echo "    git" >> ~/.zshrc
	echo "    docker" >> ~/.zshrc
	echo "    docker-compose" >> ~/.zshrc
	echo "    virtualenv" >> ~/.zshrc
	echo "    terraform" >> ~/.zshrc
	echo "    kubectl" >> ~/.zshrc
	echo "    aws" >> ~/.zshrc
	echo "    httpie" >> ~/.zshrc
	echo "    vscode" >> ~/.zshrc
	echo "    iterm2" >> ~/.zshrc
	echo "    osx" >> ~/.zshrc
	echo "    emoji" >> ~/.zshrc
	echo "    ssh-agent" >> ~/.zshrc
	echo "    gpg-agent" >> ~/.zshrc
	echo "    common-aliases" >> ~/.zshrc
	echo "    colorize" >> ~/.zshrc
	echo "    $(DEVOPS_PROJECT_NAME)" >> ~/.zshrc
	echo ")" >> ~/.zshrc
	echo "ZSH_THEME=powerlevel10k/powerlevel10k" >> ~/.zshrc
	echo "POWERLEVEL9K_MODE=nerdfont-complete" >> ~/.zshrc
	echo "POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)" >> ~/.zshrc
	echo "POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv root_indicator background_jobs history time)" >> ~/.zshrc
	echo "POWERLEVEL9K_PROMPT_ON_NEWLINE=true" >> ~/.zshrc
	echo "POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true" >> ~/.zshrc
	echo "source \$$ZSH/oh-my-zsh.sh" >> ~/.zshrc
	echo "# END: Custom configuration" >> ~/.zshrc

_dev-config-iterm2:
	curl -fsSL https://raw.githubusercontent.com/stefaniuk/dotfiles/master/lib/resources/iterm/com.googlecode.iterm2.plist -o /tmp/com.googlecode.iterm2.plist
	defaults import com.googlecode.iterm2 /tmp/com.googlecode.iterm2.plist
	rm /tmp/com.googlecode.iterm2.plist

_dev-config-visual-studio-code:
	code --force --install-extension alefragnani.bookmarks
	code --force --install-extension alexkrechik.cucumberautocomplete
	code --force --install-extension ban.spellright
	code --force --install-extension coenraads.bracket-pair-colorizer
	code --force --install-extension davidanson.vscode-markdownlint
	code --force --install-extension dbaeumer.vscode-eslint
	code --force --install-extension donjayamanne.githistory
	code --force --install-extension eamodio.gitlens
	code --force --install-extension editorconfig.editorconfig
	code --force --install-extension gabrielbb.vscode-lombok
	code --force --install-extension ginfuru.ginfuru-better-solarized-dark-theme
	code --force --install-extension mauve.terraform
	code --force --install-extension mhutchie.git-graph
	code --force --install-extension ms-azuretools.vscode-docker
	code --force --install-extension ms-python.anaconda-extension-pack
	code --force --install-extension ms-python.python
	code --force --install-extension ms-vsliveshare.vsliveshare-pack
	code --force --install-extension msjsdiag.debugger-for-chrome
	code --force --install-extension msjsdiag.vscode-react-native
	code --force --install-extension oderwat.indent-rainbow
	code --force --install-extension pivotal.vscode-spring-boot
	code --force --install-extension redhat.java
	code --force --install-extension streetsidesoftware.code-spell-checker
	code --force --install-extension timonwong.shellcheck
	code --force --install-extension tomoki1207.pdf
	code --force --install-extension vscjava.vscode-spring-boot-dashboard
	code --force --install-extension vscjava.vscode-spring-initializr
	code --force --install-extension vscode-icons-team.vscode-icons
	code --list-extensions --show-versions

_dev-config-visual-studio-code-disable-java-extensions:
	# TODO: This currently doesn't work well and needs investigation. There seems to be a bug in an extension implementation
	# code --disable-extension gabrielbb.vscode-lombok
	# code --disable-extension pivotal.vscode-boot-dev-pack
	# code --disable-extension pivotal.vscode-spring-boot
	# code --disable-extension pivotal.vscode-spring-boot
	# code --disable-extension redhat.java
	# code --disable-extension vscjava.vscode-java-debug
	# code --disable-extension vscjava.vscode-java-dependency
	# code --disable-extension vscjava.vscode-java-pack
	# code --disable-extension vscjava.vscode-java-test
	# code --disable-extension vscjava.vscode-maven
	# code --disable-extension vscjava.vscode-spring-boot-dashboard
	# code --disable-extension vscjava.vscode-spring-initializr

_dev-config-command-line:
	sudo chown -R $$(id -u) $$(brew --prefix)/*
	# configure Python
	brew link python
	rm -f $$(brew --prefix)/bin/python
	ln $$(brew --prefix)/bin/python3 $$(brew --prefix)/bin/python
	curl -s https://bootstrap.pypa.io/get-pip.py | sudo $$(brew --prefix)/bin/python3
	$$(brew --prefix)/bin/pip3 install \
		black \
		boto3 \
		bpython \
		configparser \
		flake8 \
		mypy \
		pygments \
		pylint
	# configure Go
	curl -sSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash ||:
	# configure Java
	eval "$$(jenv init -)"
	jenv enable-plugin export
	jenv add $$(/usr/libexec/java_home)
	jenv versions # ls -1 /Library/Java/JavaVirtualMachines
	jenv global $$(jenv versions | sed 's/*//' | sed 's/^[ \t]*//;s/[ \t]*$$//' | grep '^[0-9]' | awk '{ print $$1 }' | sort -n | head -n 1)
	# configure Git
	make git-config
	# configure shell
	mkdir -p ~/{.aws,.kube/configs,.ssh,bin,tmp,projects}
	[ ! -f ~/.aws/config ] && echo "[default]\noutput = json\nregion = eu-west-2\n\n# TODO: Add AWS accounts\n" > ~/.aws/config
	[ ! -f ~/.aws/credentials ] && echo "[default]\naws_access_key_id = xxx\naws_secret_access_key = xxx\n\n# TODO: Add AWS credentials" > ~/.aws/credentials
	cp $(BIN_DIR)/* ~/bin
	chmod 700 ~/.ssh
	rm -f ~/.zcompdump*
	mkdir -p $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)
	(
		echo
		echo "# Completion"
		echo "zstyle ':completion:*:make:*:targets' call-command true"
		echo "zstyle ':completion:*:make:*' tag-order targets variables"
		echo "zstyle ':completion:*' group-name ''"
		echo "zstyle ':completion:*:descriptions' format '%B%d%b'"
		echo
		echo "# Alises"
		echo "alias tx-mfa='~/bin/texas-mfa.py'"
		echo "alias tx-mfa-clear='source ~/bin/texas-mfa-clear.sh'"
		echo "alias tns='~/bin/toggle-natural-scrolling.sh'"
		echo
		echo "# Variables"
		echo "export PATH=/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/findutils/libexec/gnubin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/gnu-tar/libexec/gnubin:/usr/local/opt/grep/libexec/gnubin:/usr/local/opt/make/libexec/gnubin:/usr/local/Cellar/python/$$(python3 --version | grep -Eo '[0-9.]*')/Frameworks/Python.framework/Versions/Current/bin:\$$PATH"
		echo "export GPG_TTY=\$$(tty)"
		echo "export KUBECONFIG=\$$(ls -1 ~/.kube/configs/*-$(or $(AWS_ACCOUNT_NAME), nonprod)*kubeconfig) 2> /dev/null"
		echo
		echo "# env: Python"
		echo "export PATH=\$$HOME/.pyenv/bin:\$$PATH"
		echo "export MYPY_CACHE_DIR=\$$HOME/.mypy_cache"
		echo "eval \"\$$(pyenv init -)\""
		echo "eval \"\$$(pyenv virtualenv-init -)\""
		echo "# env: Go"
		echo ". $$HOME/.gvm/scripts/gvm"
		echo "# env: Java"
		echo "export PATH=\$$HOME/.jenv/bin:\$$PATH"
		echo "eval \"\$$(jenv init -)\""
		echo "# env: Node"
		echo "export NVM_DIR=\$$HOME/.nvm"
		echo ". /usr/local/opt/nvm/nvm.sh"
		echo ". /usr/local/opt/nvm/etc/bash_completion.d/nvm"
		echo
		echo "# AWS platform"
		echo "source $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform.zsh"
		echo
	) > $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/$(DEVOPS_PROJECT_NAME).plugin.zsh
	if [ ! -f $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform.zsh ]; then
		(
			echo
			echo "# export: AWS platform variables"
			echo "export AWS_ACCOUNT_ID_MGMT=123456789"
			echo "export AWS_ACCOUNT_ID_NONPROD=123456789"
			echo "export AWS_ACCOUNT_ID_PROD=123456789"
			echo
		) > $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform.zsh
	fi
	if [ -f $(PROJECT_DIR)/*.code-workspace.template ] && [ ! -f $(PROJECT_DIR)/$(PROJECT_NAME).code-workspace ]; then
		cp $(PROJECT_DIR)/*.code-workspace.template $(PROJECT_DIR)/$(PROJECT_NAME).code-workspace
	fi

_dev-fix-vagrant-virtualbox:
	plugin=/opt/vagrant/embedded/gems/2.2.6/gems/vagrant-2.2.6/plugins/providers/virtualbox/plugin.rb
	meta=/opt/vagrant/embedded/gems/2.2.6/gems/vagrant-2.2.6/plugins/providers/virtualbox/driver/meta.rb
	if [ -f $$plugin ] && [ -f $$meta ]; then
		sudo sed -i 's;autoload :Version_4_0, File.expand_path("../driver/version_4_0", __FILE__);autoload :Version_6_1, File.expand_path("../driver/version_6_1", __FILE__);g' $$plugin
		sudo sed -i 's;"4.0" => Version_4_0,;"6.1" => Version_6_1,;g' $$meta
		sudo cp $(LIB_DIR)/fix/version_6_1.rb /opt/vagrant/embedded/gems/2.2.6/gems/vagrant-2.2.6/plugins/providers/virtualbox/driver
	fi

# ==============================================================================

.SILENT: \
	dev-check \
	dev-config \
	dev-info \
	dev-install-additional \
	dev-install-corporate \
	dev-install-essential \
	dev-prepare \
	dev-setup \
	dev-update
