<#
Example Command:
.\nsxv2t-cleanup-secgroups-vorigin-tags.ps1

#>

# Param (
#     [Parameter(Mandatory=$True)][String]$ImportFile
# )

$groupobjectsreturn = (Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.domains.groups).list("default")

$NsxTGroups = $groupobjectsreturn.results
do  {
    $groupobjectsreturn = (Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.domains.groups).list("default",$groupobjectsreturn.cursor)
    $NsxTGroups += $groupobjectsreturn.results
} while ($groupobjectsreturn.cursor)


#$vOriginGroups = $NsxTGroups.where({$_.tags.scope -eq "v_origin" -AND $_.display_name -match "sg-test-harry"})
#$vOriginGroups = $NsxTGroups.where({$_.display_name -eq "UFRNDMZMMP01"})
$vOriginGroups = $NsxTGroups.where({$_.tags.scope -match "v_origin"})

# Loop through each  inputgroup
foreach ($vOriginGroup in $vOriginGroups) {
    $groupdata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.groups
    $extidexpressiondata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.groups.external_id_expressions
    $expressiondata = (Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.groups.ip_address_expressions)
    $vmdata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.realized_state.enforcement_points.virtual_machines
    
    Write-Output ($vOriginGroup.display_name)
    Write-Output ("========================================")

    $groupspec = $groupdata.Help.patch.group.Create()
    $groupspec.display_name = $vOriginGroup.display_name
    $groupspec.id = $vOriginGroup.id
    $groupspec.resource_type = "Group"
    
    # Existing 
    $existingGroupSpec = $vOriginGroup

    # Tags
    foreach ($t in $vOriginGroup.tags){
        if ($t.scope -ne "v_origin"){
            $grouptag = $groupdata.Help.patch.group.tags.Element.Create()
            $grouptag.tag = $t.tag
            $grouptag.scope = $t.scope
            $groupspec.tags.Add($grouptag) | Out-Null
        } 
    }


    $existingExpression = $vOriginGroup.expression
    foreach ($ee in $existingExpression) {
        # Existing PathExpression
        if ($ee.resource_type -eq "PathExpression"){
            Write-Output ("PathExpression exists")
            $expressionSpec = $groupdata.Help.patch.group.expression.Element.path_expression.Create()
            $expressionSpec.paths = $ee.paths
            $expressionSpec.resource_type = $ee.resource_type
            # Write-Output ("Creating PathExpression")
            try {
                $groupspec.expression.Add($expressionSpec) | Out-Null
                Write-Output ("PathExpression has been added")
            } catch {
                Write-Output ("PathExpression Failed to be added")
            }            
        }

        # Existing IPAddressExpression
        if ($ee.resource_type -eq "IPAddressExpression"){
            Write-Output ("IPAddressExpression exists")
            if ($ee.resource_type -eq "IPAddressExpression"){
                $expressionSpec = $groupdata.Help.patch.group.expression.Element.IP_address_expression.Create()
                $expressionSpec.ip_addresses = $ee.ip_addresses
                $expressionSpec.id = $ee.id
                $expressionSpec.resource_type = $ee.resource_type
                # Write-Output ("Creating IPAddressExpression")
                try {
                    $groupspec.expression.Add($expressionSpec) | Out-Null
                    Write-Output ("IPAddressExpression has been added")
                } catch {
                    Write-Output ("IPAddressExpression Failed to be added")
                }
            }
        }

        # Existing ExternalIDExpression
        if ($ee.resource_type -eq "ExternalIDExpression"){
            Write-Output ("ExternalIDExpression exists")
                $expressionSpec = $extidexpressiondata.help.patch.external_ID_expression.create()
                $expressionSpec.member_type = $ee.member_type
                $expressionSpec.external_ids = $ee.external_ids
                if($expressionSpec.external_ids.count -eq 0){
                    continue
                }                
                Write-Output ("Debug 1")
                $expressionSpec.id = $ee.id
                $expressionSpec.resource_type = $ee.resource_type
                # Write-Output ("Creating ExternalIDExpression")
                try {
                    $groupspec.expression.Add($expressionSpec) | Out-Null
                    # $extidexpressiondata.patch('default', $Groupid, $expressionSpec.id, $expressionSpec)
                    Write-Output ("ExternalIDExpression has been added")
                } catch {
                    Write-Output ("ExternalIDExpression Failed to be added")
                }
        }     

        # Existing Condition
        if ($ee.resource_type -eq "Condition"){
            Write-Output ("Condition exists")
            $expressionSpec = $groupdata.Help.patch.group.expression.Element.condition.Create()
                $expressionSpec.member_type = $ee.member_type
                $expressionSpec.value = $ee.value
                $expressionSpec.key = $ee.key
                $expressionSpec.operator = $ee.operator
                $expressionSpec.resource_type = $ee.resource_type
                # Write-Output ("Creating Condition")
                try {
                    $groupspec.expression.Add($expressionSpec) | Out-Null
                    Write-Output ("Condition has been added")
                } catch {
                    Write-Output ("Condition Failed to be added")
                }
        }        

        # Existing ConjunctionOperator
        if ($ee.resource_type -eq "ConjunctionOperator"){
            Write-Output ("ConjunctionOperator exists")
            $ConjunctionOperatorExists = $true
                $expressionSpec = $groupdata.Help.patch.group.expression.Element.conjunction_operator.Create()
                $expressionSpec.conjunction_operator = $ee.conjunction_operator
                $expressionSpec.resource_type = $ee.resource_type
                # Write-Output ("Creating ConjunctionOperator")
                try {
                    $groupspec.expression.Add($expressionSpec) | Out-Null
                    Write-Output ("ConjunctionOperator has been added")
                } catch {
                    Write-Output ("ConjunctionOperator Failed to be added")
                }
        }
    }

    # Patch Group
    try {
        # $groupspec
        $groupdata.patch("default", $groupspec.id, $groupspec)
        Write-Host -ForegroundColor Green $group_name ' successfully patched' 

    } catch {
        Write-Host -ForegroundColor Red $group_name ' FAILED...Investigate'
        Write-Output ("GroupSpec...........................................")
        $groupspec
    }

    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")



}
