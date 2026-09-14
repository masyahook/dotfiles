#################################
########### OH-MY-ZSH ###########
#################################

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Which plugins would you like to load?
plugins=(
	git
	starship
	poetry
	copyfile
	sudo
	copypath
	gh
	pip
	web-search
	zsh-syntax-highlighting
	zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

#################################
########### Personal ############
#################################

# Load secrets/keys (never committed — see env/.env.example in this repo)
[ -f ~/.env ] && source ~/.env

# eza aliases (replacement for ls)
alias ls='eza -1 --icons --group-directories-first'  # VS Code-like list
alias lr='eza -1 --tree --icons --group-directories-first --level=2'  # VS Code-like list + recursive tree up to level 2
alias lr2='eza -1 --tree --icons --group-directories-first --level=2'
alias lr3='eza -1 --tree --icons --group-directories-first --level=3'  # ...up to level 3
alias lre='eza -1 --tree --icons --group-directories-first --level=2'
alias ll='eza -lha --icons --octal-permissions --group-directories-first --git'  # VS Code-like long list
alias lt='eza -lha --sort=modified --icons --git'  # long list sorted by modified time
alias la="eza -lha --group"  # long list, show groups

# git
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpnw="git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)"
alias gs="git status"
alias gl="git pull"
alias gco='git checkout'
alias gb='git branch'
alias gnb='git checkout -b'  # create a new branch and switch to it

# conda-based aliases (edit env names to match your own)
alias cda='conda deactivate'

# venv-based aliases
alias sup='source .venv/bin/activate'

# grep
alias grep='grep --color'  # colorized grep

# Making wget better
alias wget='wget --content-disposition'

# claude
alias clw='claude --worktree'
# Separate Claude config dirs for different personas/projects, e.g.:
# alias claude-work='CLAUDE_CONFIG_DIR=~/.claude-work claude'
alias claude-personal='CLAUDE_CONFIG_DIR=~/.claude-personal claude'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if [ -d "/opt/homebrew/Caskroom/miniconda/base" ]; then
	__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
		eval "$__conda_setup"
	else
		if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
			. "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
		else
			export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
		fi
	fi
	unset __conda_setup
fi
# <<< conda initialize <<<

# Starship prompt
eval "$(starship init zsh)"

# mcfly (better shell history search)
eval "$(mcfly init zsh)"

export PATH="$HOME/.local/bin:$PATH"
