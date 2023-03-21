<#
Example Command:
.\nsxv2t-audit-nsxv-secgroups.ps1

#>

$NsxSecuityTags = Get-NsxSecurityTag
$NsxSecuityGroups = Get-NsxSecurityGroup
$NsxSecuityGroupsArray = @()


$NsxTGroups = (Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.domains.groups).list("default").results

Foreach($SG in $NsxSecuityGroups) {
    Write-Output ("SG Name: "+$SG.Name)
    Write-Output ("---------------------")
    Write-Output ("")
    Write-Output ("SG Members: ")
    Write-Output ("---------")
    Write-Output ($SG.Member | select Name,objectTypeName )
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")

    $sg_members = @()
    $vm_members = @()
    foreach($member in $SG.Member){
        if($member.objectTypeName -eq "IPSet" -Or $member.objectTypeName -eq "SecurityGroup"){
            if($NsxTGroups.where({$_.display_name -eq $member.name}).count -ne 0){
                $sg_member = [PSCustomObject]@(
                "/infra/domains/default/groups/"+$NsxTGroups.where({$_.display_name -eq $member.name}).id
                )
            }
            else{
                $sg_member = [PSCustomObject]@(
                "/infra/domains/default/groups/"+$member.name
                )
            }
            
            $sg_members += $sg_member
        }
        if($member.objectTypeName -eq "VirtualMachine"){
            $vm_member = [PSCustomObject]@(
                $member.name
            )
            
            $vm_members += $vm_member
        }        
        if($member.objectTypeName -eq "SecurityTag"){
            $vms = (Get-NsxSecurityTagAssignment -SecurityTag $member).VirtualMachine
            foreach($vm in $vms){
                if($NsxTGroups.where({$_.display_name -eq $vm.name}).count -ne 0){
                    $sg_member = [PSCustomObject]@(
                    "/infra/domains/default/groups/"+$NsxTGroups.where({$_.display_name -eq $vm.name}).id
                    )
                }
                else{
                    $sg_member = [PSCustomObject]@(
                    "/infra/domains/default/groups/"+$vm.name
                    )
                }
                $sg_members += $sg_member
            }
        }
        if($member.objectTypeName -eq "VirtualWire"){
            if($NsxTGroups.where({$_.display_name -eq $member.name}).count -ne 0){
                $sg_member = [PSCustomObject]@(
                "/infra/domains/default/groups/"+$NsxTGroups.where({$_.display_name -eq $member.name}).id
                )
            }
            else{
                $sg_member = [PSCustomObject]@(
                "/infra/domains/default/groups/"+$member.name
                )
            }
            $sg_members += $sg_member
        } 

    }

    $expression = @()
    if ($vm_members.count -gt 0) {
        $expression += [PSCustomObject]@{
            resource_type = "ExternalIDExpression"
            vm_names = $vm_members
        }
    } else {
        continue
    }
    
    if ($sg_members.count -gt 0) {
        $expression += [PSCustomObject]@{
            resource_type = "PathExpression"
            paths = $sg_members
        }
    }
    
    $NsxSecuityGroupsObject = [PSCustomObject]@{
        display_name = $SG.Name
        expression = $expression
    }

    $NsxSecuityGroupsArray += $NsxSecuityGroupsObject
    }

$NsxParentSGOutput = [PSCustomObject]@{
    sg_sec_groups = $NsxSecuityGroupsArray
}
$NsxParentSGOutput | ConvertTo-Json -Depth 10 | Out-File ".\nsxv-sg-output.json"



    # $VMs = Get-VM | Where PowerState -EQ PoweredOn | Select Name | ConvertTo-Json -Depth 10 | Out-File ".\nsxv-sg-output.json"