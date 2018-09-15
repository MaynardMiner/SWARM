
while ($true)
{
    Clear-Host
    Start-Process -FilePath "nvidia-smi.exe" -WorkingDirectory ".\" -NoNewWindow
    Start-Sleep -s 3
}
