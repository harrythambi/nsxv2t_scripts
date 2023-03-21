<#
Example Command:
.\nsxv2t-cleanup-nsxt-update-secgroups.ps1

#>

# Param (
#     [Parameter(Mandatory=$True)][String]$ImportFile
# )

$NsxTGroups = (Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.domains.groups).list("default").results
$NSXvSGGroupsImport = Get-Content -Raw -Path "nsxv-sg-output.json" | ConvertFrom-Json
$NSXvVMGroupsImport = Get-Content -Raw -Path "nsxv-vm-output.json" | ConvertFrom-Json
$NSXvGroups = $NSXvSGGroupsImport.sg_sec_groups + $NSXvVMGroupsImport.sg_sec_groups

# Start-Sleep -Seconds 70

# Loop through each  inputgroup
foreach ($nsxvgroup in $NSXvGroups) {
    #Retrieve Group Information
    $groupdata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.groups
    $extidexpressiondata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.groups.external_id_expressions
    $expressiondata = (Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.domains.groups.ip_address_expressions)
    $vmdata = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.realized_state.enforcement_points.virtual_machines
    Write-Output ($nsxvgroup.display_name)
    Write-Output ("========================================")
    Write-Output ("Check if Group name exists in NSX-T.....")
    # Define Group Spec
    $groupExists = $false
    if($NsxTGroups.where({$_.display_name -eq $nsxvgroup.display_name}).count -ne 0){
        Write-Output ("Group exists in NSX-T - Patching existing Group")
        $groupExists = $true    
    } else {
        Write-Output ("Group does not exist in NSX-T - Creating new Group")
   }

    # Define GroupSpec
    $groupspec = $groupdata.Help.patch.group.Create()
    $groupspec.display_name = $nsxvgroup.display_name
    $groupspec.resource_type = "Group"

    # If group exists capture existing spec
    $expressionExists = $false
    $PathExpressionExists = $false
    $IPAddressExpressionExists = $false
    $ConditionExists = $false
    $ConjunctionOperatorExists = $false
    $ExternalIDExpressionExists = $false
    if($groupExists) {
        $existingGroupSpec = $NsxTGroups.where({$_.display_name -eq $nsxvgroup.display_name})
        $groupspec.display_name = $existingGroupSpec.display_name
        $groupspec.id = $existingGroupSpec.id
        $existingGroupSpec.id
        $groupspec.description = $existingGroupSpec.description
        if($existingGroupSpec.tags) {
            $grouptag = $groupdata.Help.patch.group.tags.Element.Create()
            $grouptag.tag = $existingGroupSpec.tags.tag
            $grouptag.scope = $existingGroupSpec.tags.scope
            $groupspec.tags.Add($grouptag) | Out-Null
        }

        if($NsxTGroups.where({$_.display_name -eq $nsxvgroup.display_name}).expression) {
            $expressionExists = $true
            $existingExpression = $NsxTGroups.where({$_.display_name -eq $nsxvgroup.display_name}).expression
        }

        $expressionCount = 0
        # Populate Existing expressions if any
        foreach ($ee in $existingExpression) {
            # Existing PathExpression
            if ($ee.resource_type -eq "PathExpression"){
                $PathExpressionExists = $true
                $expressionSpec = $groupdata.Help.patch.group.expression.Element.path_expression.Create()
                $expressionSpec.paths = $ee.paths
                $expressionSpec.resource_type = $ee.resource_type
                if($nsxvgroup.expression.where({$_.resource_type -eq "PathExpression"}).count -ne 0) {
                    $newPaths = $nsxvgroup.expression.where({$_.resource_type -eq "PathExpression"}).paths.value
                    $expressionSpec.paths += @($newPaths) | Select-Object -Unique
                }
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
                $IPAddressExpressionExists = $true
                $expressionSpec = $groupdata.Help.patch.group.expression.Element.IP_address_expression.Create()
                $expressionSpec.ip_addresses = $ee.ip_addresses
                $expressionSpec.id = $ee.id
                $expressionSpec.resource_type = $ee.resource_type
                if($nsxvgroup.expression.where({$_.resource_type -eq "IPAddressExpression"}).count -ne 0) {
                    $newIPAddresses = $nsxvgroup.expression.where({$_.resource_type -eq "IPAddressExpression"}).ip_addresses.value
                    $expressionSpec.ip_addresses += @($newIPAddresses) | Select-Object -Unique
                }
                # Write-Output ("Creating IPAddressExpression")
                try {
                    $groupspec.expression.Add($expressionSpec) | Out-Null
                    Write-Output ("IPAddressExpression has been added")
                } catch {
                    Write-Output ("IPAddressExpression Failed to be added")
                }
            }

            # Existing ExternalIDExpression
            if ($ee.resource_type -eq "ExternalIDExpression"){
                $ExternalIDExpressionExists = $true
                $expressionSpec = $extidexpressiondata.help.patch.external_ID_expression.create()
                $expressionSpec.member_type = $ee.member_type
                $expressionSpec.external_ids = $ee.external_ids
                foreach($id in $expressionSpec.external_ids.value) {
                    if($vmdata.list("default").results.where{($_.external_id.value -eq $id)}.count -eq 0){
                        $expressionSpec.external_ids = $expressionSpec.external_ids.where({$_ -ne $id})
                    }
                }
                if($expressionSpec.external_ids.count -eq 0){
                    $ExternalIDExpressionExists = $false
                    continue
                }
                $expressionSpec.id = $ee.id
                $expressionSpec.resource_type = $ee.resource_type
                if($nsxvgroup.expression.where({$_.resource_type -eq "ExternalIDExpression"}).count -ne 0) {
                    $vmNames = $nsxvgroup.expression.where({$_.resource_type -eq "ExternalIDExpression"}).vm_names.value
                    foreach($vmName in $vmNames) {
                        if($vmdata.list("default").results.where{($_.display_name -eq $vmName)}.count -gt 0){
                            $externalID = $vmdata.list("default").results.where{($_.display_name -eq $vmName)}.external_id.value
                            $expressionSpec.external_ids += $externalID | Select-Object -Unique
                        } else {
                            continue
                        }
                    }
                }
                # Write-Output ("Creating ExternalIDExpression")
                try {
                    $extidexpressiondata.patch('default', $Groupid, $expressionSpec.id, $expressionSpec)
                    Write-Output ("ExternalIDExpression has been added")
                } catch {
                    Write-OUtput "DEBUG1"
                    Write-Output ("ExternalIDExpression Failed to be added")
                    $expressionSpec
                }
            }            

            # Existing Condition        
            if ($ee.resource_type -eq "Condition"){
                $ConditionExists = $true
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
    }
    
    foreach ($expression in $nsxvgroup.expression) {

        $expressionCount = $groupspec.expression.GetValue().count
        # PathExpression
        if ($expression.resource_type -eq "PathExpression" -AND -not $PathExpressionExists){
            if($expressionCount -gt 0){
                if($groupspec.expression.GetValue()[-1].resource_type -ne "ConjunctionOperator") {
                    $expressionSpec = $groupdata.Help.patch.group.expression.Element.conjunction_operator.Create()
                    $expressionSpec.conjunction_operator = "OR"
                    $expressionSpec.resource_type = "ConjunctionOperator"
                    # Write-Output ("Creating ConjunctionOperator")
                    try {
                        $groupspec.expression.Add($expressionSpec) | Out-Null
                        Write-Output ("ConjunctionOperator has been added")
                    } catch {
                        Write-Output ("ConjunctionOperator Failed to be added")
                    } 
                }
            }
            $expressionSpec = $groupdata.Help.patch.group.expression.Element.path_expression.Create()
            $expressionSpec.paths = @($nsxvgroup.expression.paths)
            $expressionSpec.resource_type = "PathExpression"     
            # Write-Output ("Creating PathExpression")
            try {
                $groupspec.expression.Add($expressionSpec) | Out-Null
                Write-Output ("PathExpression has been added")
            } catch {
                Write-Output ("PathExpression Failed to be added")
            }
        } 
        # IPAddressExpression
        if ($expression.resource_type -eq "IPAddressExpression" -AND -not $IPAddressExpressionExists){
            if($expressionCount -gt 0){
                if($groupspec.expression.GetValue()[-1].resource_type -ne "ConjunctionOperator") {
                    $expressionSpec = $groupdata.Help.patch.group.expression.Element.conjunction_operator.Create()
                    $expressionSpec.conjunction_operator = "OR"
                    $expressionSpec.resource_type = "ConjunctionOperator"
                    # Write-Output ("Creating ConjunctionOperator")
                    try {
                        $groupspec.expression.Add($expressionSpec) | Out-Null
                        Write-Output ("ConjunctionOperator has been added")
                    } catch {
                        Write-Output ("ConjunctionOperator Failed to be added")
                    } 
                }
            }            
            $expressionSpec = $groupdata.Help.patch.group.expression.Element.IP_address_expression.Create()
            $expressionSpec.ip_addresses = @($expression.ip_addresses) 
            $expressionSpec.resource_type = "IPAddressExpression"
            # Write-Output ("Creating IPAddressExpression")
            try {
                $groupspec.expression.Add($expressionSpec) | Out-Null
                Write-Output ("IPAddressExpression has been added")
            } catch {
                Write-Output ("IPAddressExpression Failed to be added")]
                $expressionSpec
            }                     
        } 

        # ExternalIDExpression
        if ($expression.resource_type -eq "ExternalIDExpression" -AND -not $ExternalIDExpressionExists){
            if($expressionCount -gt 0){
                if($groupspec.expression.GetValue()[-1].resource_type -ne "ConjunctionOperator") {
                    $expressionSpec = $groupdata.Help.patch.group.expression.Element.conjunction_operator.Create()
                    $expressionSpec.conjunction_operator = "OR"
                    $expressionSpec.resource_type = "ConjunctionOperator"
                    # Write-Output ("Creating ConjunctionOperator")
                    try {
                        $groupspec.expression.Add($expressionSpec) | Out-Null
                        Write-Output ("ConjunctionOperator has been added")
                    } catch {
                        Write-Output ("ConjunctionOperator Failed to be added")
                    } 
                }
            }            
            # $expressionSpec = $extidexpressiondata.help.patch.external_ID_expression.create()
            $expressionSpec = $groupdata.Help.patch.group.expression.Element.external_ID_expression.create()
            $expressionSpec.member_type = "VirtualMachine"
            # $expressionSpec.id = New-Guid
            $expressionSpec.resource_type = "ExternalIDExpression"

            $vmNames = $nsxvgroup.expression.where({$_.resource_type -eq "ExternalIDExpression"}).vm_names
            $externalIDs = @()
            foreach($vmName in $vmNames) {
                if($vmdata.list("default").results.where{($_.display_name -eq $vmName)}.count -gt 0){
                    $externalID = $vmdata.list("default").results.where{($_.display_name -eq $vmName)}.external_id.value
                    $externalIDs += $externalID
                } else {
                    continue
                }
            }
            if($externalIDs.count -eq 0){
                continue
            } else {
                $expressionSpec.external_ids = @($externalIDs)
            }             
            # Write-Output ("Creating IPAddressExpression")
            try {
                # $extidexpressiondata.patch('default', $groupspec.id, $expressionSpec.id, $expressionSpec) | Out-Null
                $groupspec.expression.Add($expressionSpec) | Out-Null
                Write-Output ("ExternalIDExpression has been added")
            } catch {
                Write-OUtput "DEBUG2"
                Write-Output ("ExternalIDExpression Failed to be added")]
                $expressionSpec
            }                     
        } 
        # Condition          
        if ($expression.resource_type -eq "Condition") {  

            if($groupspec.expression.GetValue().where({
                $_.member_type -eq $expression.member_type -AND `
                $_.value -eq $expression.value -AND `
                $_.key -eq $expression.key -AND `
                $_.operator -eq $expression.operator -AND `
                $_.resource_type -eq $expression.resource_type 
            }).count -eq 0) {


                if($expressionCount -gt 0){
                    if($groupspec.expression.GetValue()[-1].resource_type -ne "ConjunctionOperator") {
                        $expressionSpec = $groupdata.Help.patch.group.expression.Element.conjunction_operator.Create()
                        $expressionSpec.conjunction_operator = "OR"
                        $expressionSpec.resource_type = "ConjunctionOperator"
                        # Write-Output ("Creating ConjunctionOperator")
                        try {
                            $groupspec.expression.Add($expressionSpec) | Out-Null
                            Write-Output ("ConjunctionOperator has been added")
                        } catch {
                            Write-Output ("ConjunctionOperator Failed to be added")
                        } 
                    }
                }            
                $expressionSpec = $groupdata.Help.patch.group.expression.Element.condition.Create()
                $expressionSpec.member_type = $expression.member_type
                $expressionSpec.value = $expression.value
                $expressionSpec.key = $expression.key
                $expressionSpec.operator = $expression.operator
                $expressionSpec.resource_type = "Condition"
                # Write-Output ("Creating Condition")
                try {
                    $groupspec.expression.Add($expressionSpec) | Out-Null
                    Write-Output ("Condition has been added")
                } catch {
                    Write-Output ("Condition Failed to be added")
                }

            }



        } 
    }

    # Create/Patch Group
    try {
        $groupspec
        $groupspec.id
        $groupdata.patch("default", $groupspec.id, $groupspec)
        Write-Host -ForegroundColor Green $group_name ' successfully patched' 

    } catch {
        Write-Host -ForegroundColor Red $group_name ' FAILED...Investigate'
        Write-Output ("GroupSpec...........................................")
        $groupspec
        Write-Output ("GroupSpec.Expression..........................................")
        $groupspec.expression.GetValue().resource_type
        $groupspec.expression.GetValue().resource_type.value
    }

    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
}