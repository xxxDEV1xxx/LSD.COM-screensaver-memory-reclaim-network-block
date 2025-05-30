# DeleteBlockAllTraffic.ps1
# Purpose: Deletes Windows Firewall rules 'BlockAllTraffic_Inbound' and 'BlockAllTraffic_Outbound'
# Requirements: Must run as Administrator



# Delete firewall rules
try {
    Remove-NetFirewallRule -Name "BlockAllTraffic_Inbound" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -Name "BlockAllTraffic_Outbound" -ErrorAction SilentlyContinue
    Write-Host "Firewall rules 'BlockAllTraffic_Inbound' and 'BlockAllTraffic_Outbound' deleted successfully."
}
catch {
    Write-Host "Error deleting firewall rules: $($_.Exception.Message)"
}