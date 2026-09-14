# dotfiles

My personal shell setup: zsh + [oh-my-zsh](https://ohmyz.sh/) + [starship](https://starship.rs/) prompt + [mcfly](https://github.com/cantino/mcfly) history search + [eza](https://github.com/eza-community/eza) for `ls`, a simplified copy of my [Claude Code](https://claude.com/claude-code) settings (including personal agents/commands/skills/rules shared across projects), and my [iTerm2](https://iterm2.com/) preferences (macOS only).

## Layout

| Path | Installs to |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `git/.gitconfig.template` | `~/.gitconfig` (rendered with your name/email) |
| `env/.env.example` | `~/.env` (template — fill in your own keys) |
| `claude/settings.json`, `keybindings.json`, `statusline.sh`, `subagent-statusline.sh` | every `CLAUDE_CONFIG_DIR` account dir found (`~/.claude`, `~/.claude-*`) |
| `claude/agents/`, `commands/`, `output-styles/`, `rules/`, `skills/` | same account dirs — personal-default agents/commands/output-styles/rules/skills available in every project, unless a project defines its own |
| `iterm2/com.googlecode.iterm2.plist` | imported into the `com.googlecode.iterm2` preferences domain (macOS only) |

`install.sh` **copies** these into place (it does not symlink), backing up any existing file at the destination as `<file>.bak.<timestamp>` first. Re-run it any time after pulling repo changes to re-apply them.

## Install

### macOS

```sh
git clone https://github.com/masyahook/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

Requires [Homebrew](https://brew.sh) — the script installs it automatically if missing, then uses it to install `zsh`, `starship`, `eza`, `mcfly`, and `iTerm2` (via `brew install --cask iterm2`, skipped if already installed).

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
4. Copies `.zshrc` and `starship.toml` into place (backing up existing files)
5. Copies the Claude Code config into every `CLAUDE_CONFIG_DIR` account directory it finds under `$HOME` (`~/.claude`, plus any `~/.claude-<alias>` from a `CLAUDE_CONFIG_DIR=... claude` shell alias) — settings, key bindings, status line scripts, and the personal agents/commands/output-styles/rules/skills
6. On macOS: installs iTerm2 (if missing) and imports `iterm2/com.googlecode.iterm2.plist` into its preferences (restart iTerm2 to pick it up)
7. Prompts for your git name/email and writes `~/.gitconfig` from the template (skipped if `~/.gitconfig` already exists)
8. Copies `env/.env.example` to `~/.env` **only if `~/.env` doesn't already exist** — it will not touch or overwrite real secrets

## Secrets

`~/.env` is sourced by `.zshrc` but is **never committed** — `env/.env.example` only ships placeholder values for `GITHUBTOKEN`, `GITHUBEMAIL`, `GITHUBUSERNAME`, `GITHUB_PERSONAL_ACCESS_TOKEN`, and `WANDB_API_KEY`. After install, edit `~/.env` and fill in your real keys.

## Claude Code config

`claude/` holds just the personal-preference pieces of a Claude Code setup — status line scripts, key bindings, top-level `settings.json`, and personal-default agents/commands/output-styles/rules/skills — not the full `~/.claude` directory (which also holds session history, caches, and other machine/account-specific state that isn't portable).

I run Claude Code under two accounts via shell aliases (`CLAUDE_CONFIG_DIR=~/.claude-personal claude`, `CLAUDE_CONFIG_DIR=~/.claude-chairon claude`, see `zsh/.zshrc`), so `install.sh` installs the same `claude/` content into every `~/.claude*` directory it finds — a project's own `.claude/` (agents, commands, rules, skills) still takes precedence over these personal defaults when both define something with the same name.

## iTerm2 (macOS only)

`iterm2/com.googlecode.iterm2.plist` is a `defaults export com.googlecode.iterm2` snapshot of my iTerm2 preferences (profiles, colors, key mappings). `install.sh` installs iTerm2 via Homebrew if it's missing and imports this file with `defaults import`; restart iTerm2 afterwards to pick it up. Skipped entirely on Linux — no terminal emulator to install there (e.g. on a headless cluster box).
