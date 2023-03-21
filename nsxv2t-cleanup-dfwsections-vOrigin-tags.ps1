<#
Example Command:
.\nsxv2t-cleanup-contextprofile-vOrigin-tags.ps1

#>

# Param (
#     [Parameter(Mandatory=$True)][String]$ImportFile
# )
$NsxTDFWSections = (Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.security_policies).list("default").results
# $vOriginContextProfiles = $NsxTContextProfiles.where({$_.tags.scope -eq "v_origin" -AND $_.display_name -match "ct-test-harry"})
$vOriginDFWSections = $NsxTDFWSections.where({$_.tags.scope -eq "v_origin"})[10]
# Loop through each  inputgroup
foreach ($vOriginDFWSection in $vOriginDFWSections) {
    Write-Output ($vOriginDFWSection.display_name)
    Write-Output ($vOriginDFWSection.id)
    Write-Output ("========================================")


    $dfwsectiondata = Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.domains.security_policies

    $dfwsectionspec = $dfwsectiondata.Help.update.security_policy.Create()

    $dfwsectionspec.id = $vOriginDFWSection.id
    $dfwsectionspec.display_name = $vOriginDFWSection.display_name
    $dfwsectionspec.resource_type = $vOriginDFWSection.resource_type
    $dfwsectionspec.description = $vOriginDFWSection.resource_type
    $dfwsectionspec.category = $vOriginDFWSection.category
    $dfwsectionspec.stateful = $vOriginDFWSection.stateful
    $dfwsectionspec.sequence_number = $vOriginDFWSection.sequence_number
    $dfwsectionspec.locked = $vOriginDFWSection.locked
    $dfwsectionspec.tcp_strict = $vOriginDFWSection.tcp_strict
    $dfwsectionspec.scope = $vOriginDFWSection.scope
    $dfwsectionspec.logging_enabled = $vOriginDFWSection.logging_enabled

    # Tags
    foreach ($t in $vOriginDFWSection.tags){
        if ($t.scope -ne "v_origin"){
            $dfwsectiontag = $dfwsectiondata.Help.patch.security_policy.tags.Element.Create()
            $dfwsectiontag.tag = $t.tag
            $dfwsectiontag.scope = $t.scope
            $dfwsectionspec.tags.Add($dfwsectiontag) | Out-Null
            Write-Output ("Tag has been added")
        } 
    }

    # Patch DFW Sections
    try {
        $dfwsectiondata.patch($dfwsectionspec.id, $dfwsectionspec)
        Write-Host -ForegroundColor Green $dfwsectionspec.display_name ' successfully patched' 

    } catch {
        Write-Host -ForegroundColor Red $dfwsectionspec.display_name ' FAILED...Investigate'
        Write-Output ("contextprofilespec...........................................")
        $dfwsectionspec
    }

    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")


}

