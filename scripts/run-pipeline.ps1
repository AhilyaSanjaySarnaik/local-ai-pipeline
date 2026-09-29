param([string]$Prompt = 'Confirm state.', [string]$Model = 'qwen3:4b')
Write-Host '=============================' -Foreground Cyan
Write-Host '      LOCAL AI PIPELINE' -Foreground Cyan
Write-Host '=============================' -Foreground Cyan
Write-Host '
Running AI Generation...'
$VenvPython = 'D:\local-ai-pipeline\templates\python\venv\Scripts\python.exe'
$ClientScript = 'D:\local-ai-pipeline\services\ai-api\client.py'
$Start = Get-Date
try {
    $Response = & $VenvPython $ClientScript "$Prompt" 2>&1
    $Elapsed = [math]::Round(((Get-Date) - $Start).TotalSeconds, 1)
    Write-Host "✨ SUCCESS ($Elapsed seconds)"
    $Response | Set-Content -Path 'D:\local-ai-pipeline\projects\pipeline_Output.md' -Encoding utf8
    Write-Host '
Output saved to projects\pipeline_output.md' -Foreground Gray
} catch {
    Write-Host '╌ FAILED' -Foreground Red
}