FROM alpine:latest

# Use Tsinghua mirror
RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
RUN apk update && apk upgrade
# Install dependencies
# nb requires bash, and some GNU tools for full functionality
RUN apk add --no-cache \
    bash \
    bash-completion \
    ca-certificates \
    curl \
    git \
    grep \
    sed \
    gawk \
    ncurses \
    fzf \
    bat \
    pandoc \
    vim \
    util-linux \
    nmap-ncat \
    ripgrep \
    tig \
    w3m \
    socat

# Install nb
RUN curl -L https://raw.githubusercontent.com/xwmx/nb/master/nb -o /usr/local/bin/nb \
    && chmod +x /usr/local/bin/nb

# Set up notes directory
WORKDIR /notes

# Explicitly set NB_DIR to make it clear where notes are stored
ENV NB_DIR=/notes

# Pre-configure .nbrc to allow external access
RUN echo "NB_SERVER_HOST=0.0.0.0" > /root/.nbrc
RUN echo "NB_SERVER_PORT=6789" >> /root/.nbrc

ENTRYPOINT ["/bin/bash"]
