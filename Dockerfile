FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install SSH server + basic utilities
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo 'root:devbox' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Python build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    libpq-dev \
    default-libmysqlclient-dev \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11 and 3.12
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    python3.11 python3.11-dev python3.11-venv \
    python3.12 python3.12-dev python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/

# Install Node 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Install common dev tools
RUN apt-get update && apt-get install -y \
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

# Create directories for persistent configs
RUN mkdir -p /root/.config/claude-code \
    /root/.ssh \
    /projects

# Set working directory
WORKDIR /projects

# Git config (will be overridden by mounted file if exists)
RUN git config --global init.defaultBranch main && \
    git config --global pull.rebase false

# Better shell experience
RUN echo 'alias ll="ls -alF"' >> /root/.bashrc && \
    echo 'alias la="ls -A"' >> /root/.bashrc && \
    echo 'alias l="ls -CF"' >> /root/.bashrc && \
    echo 'alias cc="claude-code"' >> /root/.bashrc && \
    echo 'export PATH="/usr/local/bin:$PATH"' >> /root/.bashrc

# SSH port
EXPOSE 22

# Start SSH server
CMD ["/usr/sbin/sshd", "-D"]
