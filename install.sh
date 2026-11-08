#!/usr/bin/env bash
# Installs this dotfiles repo onto the current machine (macOS or Linux).
# Copy-based: files are copied into place, not symlinked. Re-run any time
# to pick up repo changes; existing files are backed up with a .bak suffix.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

backup_and_copy() {
	local src="$1" dest="$2"
	mkdir -p "$(dirname "$dest")"
	if [ -e "$dest" ] && [ ! -L "$dest" ]; then
		cp "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
	fi
	cp "$src" "$dest"
}

install_packages() {
	local pkgs=("$@")
	if [ "$OS" = "Darwin" ]; then
		command -v brew >/dev/null 2>&1 || {
			log "Installing Homebrew"
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		}
		brew install "${pkgs[@]}"
	elif command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update -y
		sudo apt-get install -y "${pkgs[@]}"
	else
		log "No supported package manager found; install manually: ${pkgs[*]}"
	fi
}

log "Installing prerequisites (zsh, git, curl)"
case "$OS" in
Darwin) install_packages zsh git curl ;;
Linux) install_packages zsh git curl ;;
*)
	echo "Unsupported OS: $OS" >&2
	exit 1
	;;
esac

if [ ! -d "$HOME/.oh-my-zsh" ]; then
	log "Installing oh-my-zsh"
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

OMZ_CUSTOM="$HOME/.oh-my-zsh/custom"
[ -d "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting" ] ||
	git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
[ -d "$OMZ_CUSTOM/plugins/zsh-autosuggestions" ] ||
	git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$OMZ_CUSTOM/plugins/zsh-autosuggestions"

# Linux: user-level tools go to ~/.local/bin (no sudo prompt from their installers)
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v starship >/dev/null 2>&1; then
	log "Installing starship"
	if [ "$OS" = "Darwin" ]; then
		install_packages starship
	else
		curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
	fi
fi

if ! command -v eza >/dev/null 2>&1; then
	log "Installing eza"
	install_packages eza
fi

if ! command -v mcfly >/dev/null 2>&1; then
	log "Installing mcfly"
	if [ "$OS" = "Darwin" ]; then
		install_packages mcfly
	else
		curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh |
			sh -s -- --git cantino/mcfly --to "$HOME/.local/bin"
	fi
fi

log "Installing tmux, ripgrep, fd, jq"
case "$OS" in
Darwin) install_packages tmux ripgrep fd jq ;;
Linux)
	install_packages tmux ripgrep fd-find jq
	ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
	;;
esac

# Installs a single-binary tool from its latest GitHub release (Linux x86_64 only).
# Usage: install_github_release <owner/repo> <binary> <asset-name-template>
# The template uses {v} for the version without the leading "v".
install_github_release() {
	local repo="$1" bin="$2" template="$3" tag version tmp
	tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")"
	version="${tag##*/v}"
	tmp="$(mktemp -d)"
	curl -fsSL "https://github.com/$repo/releases/download/v$version/${template//\{v\}/$version}" |
		tar -xz -C "$tmp"
	install -m 755 "$(find "$tmp" -type f -name "$bin" | head -n1)" "$HOME/.local/bin/$bin"
	rm -rf "$tmp"
}

log "Installing gh, wget, uv"
case "$OS" in
Darwin) install_packages gh wget uv ;;
Linux)
	install_packages gh wget
	command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
	;;
esac

if ! command -v glow >/dev/null 2>&1; then
	log "Installing glow (markdown viewer)"
	if [ "$OS" = "Darwin" ]; then
		install_packages glow
	else
		install_github_release charmbracelet/glow glow "glow_{v}_Linux_x86_64.tar.gz"
	fi
fi

if ! command -v lazygit >/dev/null 2>&1; then
	log "Installing lazygit"
	if [ "$OS" = "Darwin" ]; then
		install_packages lazygit
	else
		install_github_release jesseduffield/lazygit lazygit "lazygit_{v}_Linux_x86_64.tar.gz"
	fi
fi

if ! command -v nvim >/dev/null 2>&1; then
	log "Installing neovim"
	if [ "$OS" = "Darwin" ]; then
		install_packages neovim
	else
		# apt's neovim is too old for LazyVim; use the official release build
		curl -fsSLo /tmp/nvim.tgz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
		rm -rf "$HOME/.local/nvim" && mkdir -p "$HOME/.local/nvim"
		tar -xzf /tmp/nvim.tgz -C "$HOME/.local/nvim" --strip-components=1
		ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
	fi
fi

if ! command -v herdr >/dev/null 2>&1; then
	log "Installing herdr"
	curl -fsSL https://herdr.dev/install.sh | sh
fi

log "Linking zsh config"
backup_and_copy "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"

backup_and_copy "$REPO_DIR/zsh/.zshenv" "$HOME/.zshenv"

log "Linking starship config"
backup_and_copy "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

log "Linking tmux config"
backup_and_copy "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

log "Linking neovim (LazyVim) config"
(cd "$REPO_DIR/nvim" && find . -type f) | while read -r f; do
	backup_and_copy "$REPO_DIR/nvim/$f" "$HOME/.config/nvim/$f"
done
log "Installing LazyVim plugins (first run takes a minute)"
nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true

log "Linking scripts into ~/.local/bin"
for f in "$REPO_DIR"/bin/*; do
	backup_and_copy "$f" "$HOME/.local/bin/$(basename "$f")"
	chmod +x "$HOME/.local/bin/$(basename "$f")"
done

log "Linking Claude Code config"
# Installs into every CLAUDE_CONFIG_DIR account directory that already exists
# (~/.claude plus any ~/.claude-<alias> set up via a `CLAUDE_CONFIG_DIR=... claude`
# alias in zsh/.zshrc), so agents/commands/skills/rules are available under every
# account, not just the default one.
CLAUDE_DIRS=("$HOME/.claude")
for d in "$HOME"/.claude-*; do
	[ -d "$d" ] && CLAUDE_DIRS+=("$d")
done

for cdir in "${CLAUDE_DIRS[@]}"; do
	log "  -> $cdir"
	backup_and_copy "$REPO_DIR/claude/settings.json" "$cdir/settings.json"
	backup_and_copy "$REPO_DIR/claude/keybindings.json" "$cdir/keybindings.json"
	backup_and_copy "$REPO_DIR/claude/statusline.sh" "$cdir/statusline.sh"
	backup_and_copy "$REPO_DIR/claude/subagent-statusline.sh" "$cdir/subagent-statusline.sh"
	chmod +x "$cdir/statusline.sh" "$cdir/subagent-statusline.sh"

	for kind in agents commands output-styles rules; do
		[ -d "$REPO_DIR/claude/$kind" ] || continue
		mkdir -p "$cdir/$kind"
		for f in "$REPO_DIR/claude/$kind"/*; do
			backup_and_copy "$f" "$cdir/$kind/$(basename "$f")"
		done
	done

	if [ -d "$REPO_DIR/claude/skills" ]; then
		mkdir -p "$cdir/skills"
		for skill_dir in "$REPO_DIR/claude/skills"/*/; do
			skill_name="$(basename "$skill_dir")"
			mkdir -p "$cdir/skills/$skill_name"
			cp -r "$skill_dir." "$cdir/skills/$skill_name/"
		done
		find "$cdir/skills" -path "*/scripts/*.sh" -exec chmod +x {} +
	fi
done

log "Installing herdr's Claude integration and skill"
# Session-restore hook + the skill that lets Claude drive herdr panes (uses ~/.claude)
herdr integration install claude
mkdir -p "$HOME/.claude/skills/herdr"
herdr --skill >"$HOME/.claude/skills/herdr/SKILL.md"

if [ "$OS" = "Darwin" ]; then
	log "Installing iTerm2"
	[ -d "/Applications/iTerm.app" ] || install_packages --cask iterm2
	log "Importing iTerm2 preferences"
	defaults import com.googlecode.iterm2 "$REPO_DIR/iterm2/com.googlecode.iterm2.plist"
	log "iTerm2 preferences imported — restart iTerm2 to pick them up"
fi

log "Writing ~/.gitconfig"
if [ -e "$HOME/.gitconfig" ]; then
	log "~/.gitconfig already exists, leaving it untouched (edit git/.gitconfig.template manually if you want it)"
else
	read -rp "Git user.name: " GIT_NAME
	read -rp "Git user.email: " GIT_EMAIL
	sed -e "s/{{GIT_NAME}}/$GIT_NAME/" -e "s/{{GIT_EMAIL}}/$GIT_EMAIL/" \
		"$REPO_DIR/git/.gitconfig.template" >"$HOME/.gitconfig"
fi

log "Setting up ~/.env"
if [ -e "$HOME/.env" ]; then
	log "~/.env already exists, leaving it untouched"
else
	cp "$REPO_DIR/env/.env.example" "$HOME/.env"
	log "Created ~/.env from template — fill in your real keys, it is not committed to git"
fi

log "Done. Restart your shell or run: exec zsh"
