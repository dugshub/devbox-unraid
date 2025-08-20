FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Combine all apt operations to reduce layers and optimize caching
RUN apt-get update && apt-get install -y \
    # SSH and system utilities
    openssh-server \
    sudo \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    # Python build dependencies
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    libpq-dev \
    default-libmysqlclient-dev \
    libyaml-dev \
    # Development tools
    git \
    vim \
    nano \
    tmux \
    screen \
    htop \
    make \
    jq \
    tree \
    zip \
    unzip \
    ripgrep \
    fd-find \
    bat \
    ncdu \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo 'root:devbox' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Install Python 3.11 and 3.12
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    python3.11 python3.11-dev python3.11-venv \
    python3.12 python3.12-dev python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager) with proper PATH setup
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/ && \
    uv --version

# Install Node 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    node --version && npm --version

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code && \
    claude-code --version || true

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/* && \
    gh --version

# Create directories for persistent configs
RUN mkdir -p /root/.config/claude-code \
    /root/.ssh \
    /projects

# Set working directory
WORKDIR /projects

# Git config (will be overridden by mounted file if exists)
RUN git config --global init.defaultBranch main && \
    git config --global pull.rebase false

# Install Oh My Zsh for better shell experience
RUN apt-get update && apt-get install -y zsh && \
    rm -rf /var/lib/apt/lists/* && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    chsh -s $(which zsh) && \
    echo 'alias ll="ls -alF"' >> /root/.zshrc && \
    echo 'alias la="ls -A"' >> /root/.zshrc && \
    echo 'alias l="ls -CF"' >> /root/.zshrc && \
    echo 'alias cc="claude-code"' >> /root/.zshrc && \
    echo 'export PATH="/usr/local/bin:$PATH"' >> /root/.zshrc && \
    # Also keep bash aliases for compatibility
    echo 'alias ll="ls -alF"' >> /root/.bashrc && \
    echo 'alias la="ls -A"' >> /root/.bashrc && \
    echo 'alias l="ls -CF"' >> /root/.bashrc && \
    echo 'alias cc="claude-code"' >> /root/.bashrc && \
    echo 'export PATH="/usr/local/bin:$PATH"' >> /root/.bashrc

# Copy startup script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# SSH port
EXPOSE 22

# Start SSH server with entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
