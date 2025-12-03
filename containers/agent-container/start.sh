#!/bin/bash

# Start script for Claude Code Agent with DeepSeek API
# This script sets up the environment and starts the agent

# Set DeepSeek API configuration
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=${DEEPSEEK_API_KEY}
export API_TIMEOUT_MS=600000
export ANTHROPIC_MODEL="deepseek-reasoner"                # Custom model name to use
export ANTHROPIC_SMALL_FAST_MODEL="deepseek-chat"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export ANTHROPIC_MODEL="deepseek-reasoner"                # Custom model name to use
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-reasoner" # Default Sonnet model alias
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-reasoner"     # Default Opus model alias
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-reasoner"     # Default Opus model alias
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-chat"
# Check if DEEPSEEK_API_KEY is set
if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo "Error: DEEPSEEK_API_KEY environment variable is not set"
    echo "Please run the container with: -e DEEPSEEK_API_KEY=your_api_key"
    exit 1
fi

echo "======================================"
echo "Claude Code Agent with DeepSeek API"
echo "======================================"
echo "Base URL: $ANTHROPIC_BASE_URL"
echo "Model: $ANTHROPIC_MODEL"
echo "Small/Fast Model: $ANTHROPIC_SMALL_FAST_MODEL"
echo "API Timeout: ${API_TIMEOUT_MS}ms"
echo "======================================"
echo ""

# Start interactive bash shell
exec /bin/bash
