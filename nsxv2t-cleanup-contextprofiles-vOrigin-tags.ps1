<#
Example Command:
.\nsxv2t-cleanup-contextprofile-vOrigin-tags.ps1

#>

# Param (
#     [Parameter(Mandatory=$True)][String]$ImportFile
# )

$NsxTContextProfiles = (Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.context_profiles).list().results
# $vOriginContextProfiles = $NsxTContextProfiles.where({$_.tags.scope -eq "v_origin" -AND $_.display_name -match "ct-test-harry"})
$vOriginContextProfiles = $NsxTContextProfiles.where({$_.tags.scope -eq "v_origin"})
# Loop through each  inputgroup
foreach ($vOriginContextProfile in $vOriginContextProfiles) {
    Write-Output ($vOriginContextProfile.display_name)
    Write-Output ($vOriginContextProfile.id)
    Write-Output ("========================================")

    $contextprofiledata = Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.context_profiles

    $contextprofilespec = $contextprofiledata.Help.update.policy_context_profile.Create()

    $contextprofilespec.id = $vOriginContextProfile.id
    $contextprofilespec.display_name = $vOriginContextProfile.display_name
    $contextprofilespec.description = $vOriginContextProfile.description
    $contextprofilespec.resource_type = $vOriginContextProfile.resource_type

    # Tags
    foreach ($t in $vOriginContextProfile.tags){
        if ($t.scope -ne "v_origin"){
            $contextprofiletag = $servicedata.Help.patch.service.tags.Element.Create()
            $contextprofiletag.tag = $t.tag
            $contextprofiletag.scope = $t.scope
            $contextprofilespec.tags.Add($contextprofiletag) | Out-Null
            Write-Output ("Tag has been added")
        } 
    }

    # Attributes
    $existingAttributes = $vOriginContextProfile.attributes
    foreach ($att in $existingAttributes) {
        $attributeSpec = $contextprofiledata.Help.update.policy_context_profile.attributes.element.create()
        $attributeSpec.attribute_source = $att.attribute_source
        $attributeSpec.datatype = $att.datatype
        $attributeSpec.description = $att.description
        $attributeSpec.value = $att.value
        $attributeSpec.key = $att.key
        $attributeSpec.sub_attributes = $att.sub_attributes
        $contextprofilespec.attributes.Add($attributeSpec) | Out-Null
    }

    # Patch ContextProfile
    try {
        $contextprofiledata.patch($contextprofilespec.id, $contextprofilespec)
        Write-Host -ForegroundColor Green $vOriginContextProfile.display_name ' successfully patched' 

    } catch {
        Write-Host -ForegroundColor Red $vOriginContextProfile.display_name ' FAILED...Investigate'
        Write-Output ("contextprofilespec...........................................")
        $contextprofilespec
    }

    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")


}

