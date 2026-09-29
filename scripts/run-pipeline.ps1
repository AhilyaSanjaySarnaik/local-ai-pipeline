param(
    [string]$Prompt = 'Hello',
    [string]$Model = 'qwen3:4b'
)
Write-Host 'Starting pipeline execution...' -ForegroundColor Cyan

$VenvPython = "D:\local-ai-pipeline\templates\python\venv\Scripts\python.exe"
$ClientScript = "D:\local-ai-pipeline\services\ai-api\client.py"

if (-not (Test-Path $VenvPython)) {
    Write-Host "Creating missing Python virtual environment..." -ForegroundColor Yellow
    python -m venv D:\local-ai-pipeline\templates\python\venv
    & $VenvPython -m pip install --quiet ollama
}

if (Test-Path $ClientScript) {
    & $VenvPython $ClientScript "$Prompt"
} else {
    Write-Error "Core AI service client.py not found at $ClientScript"
}
