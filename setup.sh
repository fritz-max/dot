#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Wait for any existing apt processes to finish
echo "==> Waiting for apt locks..."
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    sleep 2
done

# Clean apt cache to fix broken state from failed installs
echo "==> Cleaning apt cache..."
sudo apt-get clean
sudo apt-get update --fix-missing || true

# Start Docker daemon if not running
if command -v dockerd &>/dev/null && ! pgrep -x dockerd &>/dev/null; then
    echo "==> Starting Docker daemon..."
    nohup sudo dockerd > /dev/null 2>&1 &
fi

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
apt_install zsh stow curl wget git ripgrep direnv uuid-runtime \
    openjdk-17-jdk libmagic1 postgresql-client poppler-utils lsof

# Verify critical tools
command -v zsh >/dev/null 2>&1 || { echo "zsh failed to install"; exit 1; }
command -v stow >/dev/null 2>&1 || { echo "stow failed to install"; exit 1; }

# Install fzf from binary (better than apt version)
echo "==> Installing fzf..."
if ! command -v fzf &>/dev/null || [[ "$(fzf --version 2>/dev/null | cut -d' ' -f1)" < "0.50" ]]; then
    FZF_VERSION="0.65.2"
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" -o /tmp/fzf.tar.gz
    tar -xzf /tmp/fzf.tar.gz -C /tmp
    sudo mkdir -p /usr/local/bin && sudo mv /tmp/fzf /usr/local/bin/
    sudo chmod +x /usr/local/bin/fzf
    rm -f /tmp/fzf.tar.gz
else
    echo "    fzf already installed"
fi

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
cd "$DOTFILES_DIR"
# Remove default configs that would conflict with our dotfiles
[ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && rm -f "$HOME/.zshrc"
stow -v -t "$HOME" .

# First-run initialization
if [ ! -f "$HOME/.init_done" ]; then
    echo "==> First-run setup..."

    # SSH config for GitHub
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/config" ]; then
        cat > "$HOME/.ssh/config" <<EOF
Host github.com
    StrictHostKeyChecking no
EOF
        chmod 600 "$HOME/.ssh/config"
    fi

    # Clone code repo
    if [ ! -d "$HOME/code" ]; then
        git clone git@github.com:bwllaming/code.git "$HOME/code" || true
    fi

    touch "$HOME/.init_done"
fi

echo "==> Setting zsh as default shell..."
ZSH_PATH="$(command -v zsh)"

# Always add zsh auto-switch to .bashrc/.profile (in case chsh doesn't persist)
for f in "$HOME/.bashrc" "$HOME/.profile"; do
    if [ -f "$f" ] && ! grep -q 'exec zsh -l' "$f" 2>/dev/null; then
        printf '\n%s\n' 'if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then exec zsh -l; fi' >> "$f"
    fi
done

# Also try chsh
if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$(id -un)" 2>/dev/null || chsh -s "$ZSH_PATH" 2>/dev/null || true
fi

echo "==> Done! Restart your shell or run: exec zsh -l"
