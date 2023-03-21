<#
Example Command:
.\nsxv2t-audit-nsxv-vm-secgroups.ps1

#>

# $VMs = Get-VM
$NsxVMArray = @()
# $NoIpVMsArray = @()

$NSXvRuleMemberAuditImport = Get-Content -Raw -Path "nsxv-rule-member-audit.json" | ConvertFrom-Json
$NSXvRuleVMs = $NSXvRuleMemberAuditImport.where{($_.rule_member_type -eq "VirtualMachine")}.member_name

ForEach($vm in $NSXvRuleVMs){
    # $vm = Get-VM -Name $vm
    # $ipArray = @()

    # ForEach($ip in $vm.Guest.IPAddress){
    #     if($ip.contains(".")){
    #         $ipArray += $ip
    #     }
    #     $ips_comma = $ipArray -join ","
    # }    

    # Write-Output ("VM Name: "+$vm.Name)
    Write-Output ("VM Name: "+$vm)
    # Write-Output ("---------------------")
    Write-Output ("")
    # Write-Output ("IPs: "+$ips_comma)
    # Write-Output ("---------")
    # Write-Output ("")
    # Write-Output ("")
    # Write-Output ("")


    $expression = @()
    if($ipArray.count -gt 0){
        $expression += [PSCustomObject]@{
            resource_type = "IPAddressExpression"
            ip_addresses = $ipArray
        }
        $expression += [PSCustomObject]@{
            conjunction_operator = "OR"
            resource_type ="ConjunctionOperator"        
        }
    }
    # else{
    #     $NoIpVMsArray += $vm.name
    # }
    $expression += [PSCustomObject]@{
            member_type = "VirtualMachine"
            # value = $vm.Name
            value = $vm
            key = "Name"
            operator = "EQUALS"
            resource_type = "Condition"
    }
    $expression += [PSCustomObject]@{
            conjunction_operator = "OR"
            resource_type ="ConjunctionOperator"

    }    
    $expression += [PSCustomObject]@{
            member_type = "VirtualMachine"
            # value = $vm.Name+"_"
            value = $vm+"_"
            key = "Name"
            operator = "STARTSWITH"
            resource_type = "Condition"
    }    
    $NsxVMObject = [PSCustomObject]@{
        # display_name = $vm.Name
        display_name = $vm
        expression = $expression
    }
    $NsxVMArray += $NsxVMObject
}

$NsxVMOutput = [PSCustomObject]@{
    sg_sec_groups = $NsxVMArray
}
$NsxVMOutput | ConvertTo-Json -Depth 6 | Out-File ".\nsxv-vm-output.json"

# Write-Output ("The following VMs have no IPs detected")
# Write-Output ($NoIpVMsArray)


