<#
    .SYNOPSIS
    Send Wake-on-LAN magic packets.

    .DESCRIPTION
    Send Wake-on-LAN Magic packets to WoL enabled netwowk devices over UDP.

    .PARAMETER MacAddress
    Specifies the target MAC address to send the WoL magic packet to.

    .PARAMETER IPAddress
    Specifies the target IP address to send the magic packet to.

    .PARAMETER Port
    Specifies the destination UDP port number.

    .INPUTS
    System.Net.NetworkInformation.PhysicalAddress. You can pipe PhysicalAddress objects to Send-MagicPacket.

    .OUTPUTS
    PSCustomObject. Send-MagicPacket returns an Object with the target MAC and IP addresses

    .EXAMPLE
    PS> .\Send-MagicPacket.ps1 AA-BB-CC-00-11-22
    Sends a magic packet to MAC address AA-BB-CC-00-11-22 via IP address 255.255.255.255

    .EXAMPLE
    PS> "aabb.cc00.1122" | .\Send-MagicPacket.ps1 -IPAddress 192.168.0.255
    Sends a magic packet to MAC address AA-BB-CC-00-11-22 via IP address 192.168.0.255
#>

# TODO:
# - Convert to module
# - Auto detect default interface for local boradcast
# - Option to specify physical interface
# - Option for raw ethertype 0x0842 ?

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
    [Alias("LinkLayerAddress","PhysicalAddress","ClientId")]
    [System.Net.NetworkInformation.PhysicalAddress]$MACAddress,
    [System.Net.IPAddress]$IPAddress,
    [System.Int16]$Port
)

begin {
    if (-not $IPAddress) {
        $IPAddress = [System.Net.IPAddress]"255.255.255.255"
    }

    if (-not $Port) {
        $Port = 9 # udp/9, Discard Protocol
    }

    $UdpClient = New-Object System.Net.Sockets.UdpClient
    $UdpClient.Connect($IPAddress, $Port)
}

process {
    $Output = [PSCustomObject]@{
        'MACAddress' = $MACAddress
        'IPAddress' = $IPAddress
    }

    [System.Byte[]]$Payload = @([System.Byte]0xFF) * 6 + @($MACAddress.GetAddressBytes()) * 16

    if ($PSCmdlet.ShouldProcess($Output.PhysicalAddress)) {
        $UdpClient.Send($Payload, 102) | Out-Null
        
        $Output
    }
}

end {
    $UdpClient.Close()
}
