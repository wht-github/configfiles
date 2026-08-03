# Copy this file to pwsh/secrets.local.ps1.
# secrets.local.ps1 is ignored by Git and must never be committed.

# Recommended: keep the actual value in the Windows user environment or a
# credential manager, and only map it here if another tool needs a second name.
# $env:DEEPSEEK_API_KEY = [Environment]::GetEnvironmentVariable('DEEPSEEK_API_KEY', 'User')
# $env:ANTHROPIC_AUTH_TOKEN = $env:DEEPSEEK_API_KEY

# Convenience mode for a local-only machine. This is plain text at rest, so
# prefer Windows Credential Manager / SecretManagement for valuable tokens.
# $env:DEEPSEEK_API_KEY = 'paste-token-here'
# $env:ANTHROPIC_AUTH_TOKEN = $env:DEEPSEEK_API_KEY

# Other tools can use the same file for their own environment variables:
# $env:OPENAI_API_KEY = 'paste-token-here'
# $env:GITHUB_TOKEN = 'paste-token-here'
