param(
    [string]$Prompt = 'Hello',
    [string]$Model = 'qwen3:4b'
)
Write-Host 'Starting pipeline execution...' -ForegroundColor Cyan
if (Test-Path 'D:\local-ai-pipeline\services\ai-api\client.py') {
    python 'D:\local-ai-pipeline\services\ai-api\client.py' "$Prompt"
} else {
    Write-Error 'Core AI service client.py not found.'
}
