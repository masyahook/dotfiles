# dotfiles

My personal shell setup: zsh + [oh-my-zsh](https://ohmyz.sh/) + [starship](https://starship.rs/) prompt + [mcfly](https://github.com/cantino/mcfly) history search + [eza](https://github.com/eza-community/eza) for `ls`, plus a simplified copy of my [Claude Code](https://claude.com/claude-code) settings.

## Layout

| Path | Installs to |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `git/.gitconfig.template` | `~/.gitconfig` (rendered with your name/email) |
| `env/.env.example` | `~/.env` (template — fill in your own keys) |
| `claude/settings.json`, `keybindings.json`, `statusline.sh`, `subagent-statusline.sh` | `~/.claude/` |

`install.sh` **copies** these into place (it does not symlink), backing up any existing file at the destination as `<file>.bak.<timestamp>` first. Re-run it any time after pulling repo changes to re-apply them.

## Install

### macOS

```sh
git clone https://github.com/masyahook/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

Requires [Homebrew](https://brew.sh) — the script installs it automatically if missing, then uses it to install `zsh`, `starship`, `eza`, and `mcfly`.

### Linux (Debian/Ubuntu-based)

```sh
git clone https://github.com/masyahook/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

Uses `apt-get` for `zsh`/`git`/`curl`, and upstream install scripts for `starship` and `mcfly` (no Homebrew dependency). For other distros, install `zsh`, `starship`, `eza`, and `mcfly` manually first, then run `./install.sh`.

## What the installer does

1. Installs `zsh`, `git`, `curl` via the system package manager
2. Installs `oh-my-zsh` plus the `zsh-syntax-highlighting` and `zsh-autosuggestions` plugins
3. Installs `starship`, `eza`, `mcfly` if not already present
4. Copies `.zshrc`, `starship.toml`, and the Claude Code config files into place (backing up existing files)
5. Prompts for your git name/email and writes `~/.gitconfig` from the template (skipped if `~/.gitconfig` already exists)
6. Copies `env/.env.example` to `~/.env` **only if `~/.env` doesn't already exist** — it will not touch or overwrite real secrets

## Secrets

`~/.env` is sourced by `.zshrc` but is **never committed** — `env/.env.example` only ships placeholder values for `GITHUBTOKEN`, `GITHUBEMAIL`, `GITHUBUSERNAME`, `GITHUB_PERSONAL_ACCESS_TOKEN`, and `WANDB_API_KEY`. After install, edit `~/.env` and fill in your real keys.

## Claude Code config

`claude/` holds just the personal-preference pieces of a Claude Code setup — status line scripts, key bindings, and top-level `settings.json` — not the full `~/.claude` directory (which also holds session history, caches, and other machine/account-specific state that isn't portable).
