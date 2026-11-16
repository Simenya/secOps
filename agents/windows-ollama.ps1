# Run on the Windows host (PowerShell as Administrator). Makes the local Ollama
# model reachable from the Hyper-V Kali VM only, not the campus network.
$ip = (Get-NetIPAddress -InterfaceAlias "vEthernet (Default Switch)" -AddressFamily IPv4).IPAddress
Write-Host "Hyper-V Default Switch address: $ip  (use http://${ip}:11434/v1 as OLLAMA_URL if it is not 172.21.48.1)"
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "${ip}:11434", "User")
if (-not (Get-NetFirewallRule -DisplayName "Ollama API (Hyper-V Default Switch)" -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -DisplayName "Ollama API (Hyper-V Default Switch)" -Direction Inbound `
    -Protocol TCP -LocalPort 11434 -LocalAddress $ip `
    -InterfaceAlias "vEthernet (Default Switch)" -Action Allow -Profile Any
}
ollama pull qwen3:1.7b
Write-Host "Restart Ollama so OLLAMA_HOST takes effect, then: ollama list"
