<#
Example Command:
.\nsxv2t-cleanup-nsxt-delete-tempgroups.ps1

#>

#set proxy cmdlets.
$groupdata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.groups
$groupassociationdata = Get-NsxtpolicyService -name com.vmware.nsx_policy.global_infra.group_associations
$grouppathexpressiondata = Get-NsxtpolicyService -name com.vmware.nsx_policy.infra.domains.groups.path_expressions

# # $groupsproxy = Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.domains.groups
# $groupassocsproxy = Get-NsxtpolicyService -name com.vmware.nsx_policy.global_infra.group_associations
# $grouppathexpressiondata = Get-NsxtpolicyService -name com.vmware.nsx_policy.infra.domains.groups.path_expressions

#retrieve all policy based groups.
$groups = $groupdata.list("default").results

#filter v_temporary objects from all groups based on tag scope "v_temporary"

$tempGroups = $groups.where({$_.tags.scope -eq "v_temporary"})
$tempGroups += $groups.where({$_.description -eq "Temporary Applied_To Security Group for Migration"})

Write-Output ("Found $($tempGroups.Count) v_temporary groups.")

foreach ($tempGroup in $tempGroups) {
    
    Write-Output ("retrieve parent group target from temporary group object ""$($tempGroup.display_name)"".")
    $parentGroups = $groupassociationdata.list($tempGroup.path).results

    if ($parentGroups) {
        foreach ($parentGroupId in $parentGroups.target_id) {
            #retrieve group object from parent group target id
            $parentGroup = $groupdata.get("default", $parentGroupId.Split("/")[5])
            Write-Output ("group ""$($tempGroup.display_name)"" is member from parent group ""$($parentGroup.display_name)"".")
            
            $expressionSpec = $grouppathexpressiondata.help.patch.path_expression.Create()
            $expressionSpec.paths = $parentGroup.expression.where({$_.resource_type -eq "PathExpression"}).paths.value.where({$_ -ne $tempGroup.path})
            $expressionSpec.resource_type = $parentGroup.expression.where({$_.resource_type -eq "PathExpression"}).resource_type
            $expressionSpec.id = $parentGroup.expression.where({$_.resource_type -eq "PathExpression"}).id
            
            $expressionSpec.paths.count

            # Start-Sleep -Seconds 60
            #patch parent group with new path expression (remove temporary group from path expression)
            if($expressionSpec.paths.count -eq 0) {
                $grouppathexpressiondata.delete("default", $parentGroup.id, $expressionSpec.id)
            } else {
                $grouppathexpressiondata.patch("default", $parentGroup.id, $expressionSpec.id, $expressionSpec)
            }
            Write-Output ("$($tempGroup.display_name) removed as a member from (parent) group $($parentGroup.display_name)")
        }
    } else {
        Write-Output ("group ""$($tempGroup.display_name)"" is not a member from a parent group.")
    }
    $groupdata.delete("default",$tempGroup.id)
    Write-Output  ("removing v_temporary group $($tempGroup.display_name)")
    Write-Output ("")
    Write-Output ("")

}