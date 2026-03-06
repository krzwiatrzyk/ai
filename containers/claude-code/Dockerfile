FROM ubuntu:24.04

ENV NONINTERACTIVE=1
ENV HOMEBREW_NO_AUTO_UPDATE=1

RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    build-essential \
    procps \
    gosu \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash linuxbrew
RUN useradd -m -s /bin/bash -G linuxbrew,sudo claude
RUN echo 'claude ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/claude

USER linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

RUN brew install --cask claude-code
RUN chmod -R g+rx /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/Cellar

USER root
COPY yolo-settings.json /opt/claude-config/settings.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
