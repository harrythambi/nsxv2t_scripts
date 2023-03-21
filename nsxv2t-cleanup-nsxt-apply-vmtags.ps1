<#
Example Command:
.\nsxv2t-cleanup-nsxt-apply-vmtags.ps1
#>


# Param (
#     [Parameter(Mandatory=$True)][String]$ImportFile
# )

$NSXvTagsImport = Get-Content -Raw -Path "nsxv-sectags-audit.json" | ConvertFrom-Json

$vmdata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.realized_state.enforcement_points.virtual_machines
$vmdataResults = $vmdata.list("default").results

foreach($tagImport in $NSXvTagsImport){
    if($vmdataResults.where{($_.display_name -eq $tagImport.vm_name)}.count -gt 0) {
        Write-Output ($tagImport.vm_name)
        $vmdataspec = $vmdata.help.updatetags.virtual_machine_tags_update.create()
        $vmexternalid = $vmdata.list("default").results.where{($_.display_name -eq $tagImport.vm_name)}.external_id.value
        $vmdataspec.virtual_machine_id = $vmexternalid
        
        $existingTags = @((Get-NsxtService -Name com.vmware.nsx.fabric.virtual_machines).list().results.where{($_.display_name -eq $tagImport.vm_name)}.tags.tag)
        $tagImportTags = @($NSXvTagsImport.where{($_.vm_name -eq $tagImport.vm_name)}.tag_name)
        if($existingTags.count -gt 0) {
            $tagImportTags += $existingTags
        }
    
        foreach($tag in $tagImportTags){
            $vmdatatagspec = $vmdata.help.updatetags.virtual_machine_tags_update.tags.Element.Create()
            $vmdatatagspec.tag = $tag
            $vmdatatagspec.scope = " "
            $vmdataspec.tags.Add($vmdatatagspec) | Out-Null
        }
        $vmdata.updatetags("default", $vmdataspec)
        Write-Output (" ")
    }
}