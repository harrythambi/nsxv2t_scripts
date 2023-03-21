<#
Example Command:
.\nsxv2t-premigration-nsxt-patch-segments.ps1

#>

$segmentList = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.segments

$segmentsArray = Get-Content -Raw -Path "nsxv2t-segments-audit.json" | ConvertFrom-Json

foreach($segment in $segmentsArray) {

    if (($segmentList.list().results.where{($_.display_name -eq $segment.display_name)}).count -ne 0) {
        try {
            $segmentList.delete($segment.display_name)
            Write-output $segment.display_name" Segment was deleted"
        }
        catch {
            Write-Output $segment.display_name" Unable to delete Segment"
            pause
        }
    }
    $segmentSpec = $segmentList.Help.patch.segment.Create()
    if ($segment.gateway_address) {
        $subnetSpec = $segmentList.Help.patch.segment.subnets.Element.create()
        $subnetSpec.gateway_address = $segment.gateway_address
        $segmentSpec.subnets.add($subnetSpec)
    }
    if ($segment.connectivity_path) {
        $segmentSpec.connectivity_path = $segment.connectivity_path
    }
    $segmentSpec.display_name = $segment.display_name
    $segmentSpec.resource_type = $segment.resource_type
    $segmentSpec.replication_mode = $segment.replication_mode
    $segmentSpec.admin_state = $segment.admin_state
    $segmentSpec.id = $segment.display_name
    $segmentSpec.transport_zone_path = $segment.transport_zone_path
    if ($segment.overlay_id) {
        $segmentSpec.overlay_id = $segment.overlay_id
    }

    try {
        $segmentList.patch($segmentSpec.id, $segmentSpec) | out-null
        Write-output $segment.display_name" Segment was created"
    }
    catch {
        Write-Output $segment.display_name" Unable to create Segment"
        pause
    }
    
}
