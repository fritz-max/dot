#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resilient apt installs with retry
apt_install() {
    for i in 1 2 3; do
        sudo apt-get update -y &&
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" && return 0
        echo "    Retry $i/3..."
        sleep 5
    done
    return 1
}

echo "==> Installing packages..."
apt_install zsh stow curl wget git fzf ripgrep

# Verify critical tools
command -v zsh >/dev/null 2>&1 || { echo "zsh failed to install"; exit 1; }
command -v stow >/dev/null 2>&1 || { echo "stow failed to install"; exit 1; }

echo "==> Installing oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "    oh-my-zsh already installed"
fi

echo "==> Installing zsh plugins..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
else
    echo "    zsh-autosuggestions already installed"
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
else
    echo "    zsh-syntax-highlighting already installed"
fi

echo "==> Installing powerlevel10k theme..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
else
    echo "    powerlevel10k already installed"
fi

echo "==> Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    echo "    Homebrew already installed"
fi

echo "==> Installing brew packages..."
for pkg in zellij eza zoxide; do
    if ! command -v "$pkg" &> /dev/null; then
        echo "    Installing $pkg..."
        brew install "$pkg"
    else
        echo "    $pkg already installed"
    fi
done

echo "==> Stowing dotfiles..."
cd "$(dirname "$DOTFILES_DIR")"
stow -v -R --adopt -t "$HOME" "$(basename "$DOTFILES_DIR")"

echo "==> Setting zsh as default shell..."
ZSH_PATH="$(command -v zsh)"

if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    if sudo chsh -s "$ZSH_PATH" "$(id -un)" 2>/dev/null || chsh -s "$ZSH_PATH" 2>/dev/null; then
        echo "    Changed default shell via chsh"
    else
        echo "    chsh failed, adding fallback to .bashrc and .profile"
        # Guarded auto-switch for interactive shells only
        for f in "$HOME/.bashrc" "$HOME/.profile"; do
            if [ -f "$f" ] && ! grep -q 'exec zsh -l' "$f" 2>/dev/null; then
                printf '\n%s\n' 'if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then exec zsh -l; fi' >> "$f"
            fi
        done
    fi
fi

echo "==> Done! Restart your shell or run: exec zsh -l"
