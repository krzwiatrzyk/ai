FROM ubuntu:24.04

ENV NONINTERACTIVE=1

RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    build-essential \
    procps \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash -G sudo claude
RUN echo 'claude ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/claude

# Install mise, Node.js, and Claude Code as claude user
USER claude
RUN curl https://mise.run | bash
ENV PATH="/home/claude/.local/bin:${PATH}"
RUN mise use --global node@24
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN mkdir -p /home/claude/.claude \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc \
    && echo 'eval "$(~/.local/bin/mise activate bash 2>/dev/null)"' >> ~/.bashrc

COPY --chown=claude:claude entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER claude
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
