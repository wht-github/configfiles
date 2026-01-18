FROM alpine:latest

# Use Tsinghua mirror
RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
RUN apk update && apk upgrade
# Install dependencies
# nb requires bash, and some GNU tools for full functionality
RUN apk add --no-cache \
    bash \
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
    util-linux

# Install nb
RUN curl -L https://raw.githubusercontent.com/xwmx/nb/master/nb -o /usr/local/bin/nb \
    && chmod +x /usr/local/bin/nb

# Set up notes directory
WORKDIR /notes

# Explicitly set NB_DIR to make it clear where notes are stored
ENV NB_DIR=/notes

ENTRYPOINT ["/bin/bash"]
