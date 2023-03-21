<#
Example Command:
.\nsxv2t-audit-nsxt-segmentVdnIds.ps1

#>

$segmentList = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.segments
$segments = $segmentList.list().results.where{($_.transport_zone_path -match "f20e8cd2-2f0b-42e7-9cff-a9fcc19b741b")}

$segmentsArray = @()
$segmentsNotFound = @()
foreach($segment in $segments) {
    $logicalSwitch = Get-NsxLogicalSwitch -Name $segment.display_name
    if ($logicalSwitch.count -eq 0) {
        $segmentsNotFound += $segment.display_name
    }
    $segmentObject = [PSCustomObject]@{ 
        id = $segment.id
        display_name = $segment.display_name
        overlay_id = $logicalSwitch.vdnId # grom nsx-v
        resource_type = $segment.resource_type
        replication_mode = $segment.replication_mode
        admin_state = $segment.admin_state
        connectivity_path = $segment.connectivity_path
        transport_zone_path = $segment.transport_zone_path
        gateway_address = $segment.subnets.gateway_address
    }
    $segmentsArray += $segmentObject

}

$segmentsArray | ConvertTo-Json -Depth 4 | Out-File ".\nsxv2t-segments-audit.json"

Write-Output "Following Logical Switches cannot be found"
Write-Output $segmentsNotFound
Write-Output "  "
Write-Output "  "
Write-Output "  "
Write-Output "Check the output, and then proceed to patch Segments in NSX-T"
