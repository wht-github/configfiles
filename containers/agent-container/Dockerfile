# Agent Collection Container
# Based on Node.js Alpine image with AI development tools

FROM node:alpine

# Change Alpine mirror to Tsinghua for faster downloads in China
RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
RUN apk update && apk upgrade
# Set working directory
WORKDIR /app

# Install vim, Python, and other system dependencies
RUN apk add --no-cache \
    vim \
    git \
    curl \
    bash \
    python3 \
    py3-pip


# Install global npm packages for AI agents
RUN npm install -g @anthropic-ai/claude-code

# Copy start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Note: For Podman on Windows with volume mounts, container must run as root
# Environment variables are set in start.sh
# DEEPSEEK_API_KEY must be provided at runtime via -e flag

# Set default command
CMD ["/app/start.sh"]