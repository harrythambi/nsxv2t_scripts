<#
Example Command:
.\nsxv2t-audit-nsxv-dfwrules.ps1

#>

# The following audits every NSXv Rule whether non Security Group objects are being referenced.

$NsxVRules = Get-NSXFirewallrule
$RuleMemberArray = @()

ForEach($NsxVRule in $NsxVRules){
    #Find Member that is not security group
    $RuleMembers = $NsxVRule | Get-NSXFirewallRuleMember
    ForEach($RuleMember in $RuleMembers){
        if($RuleMember.Type -ne "SecurityGroup" -and $RuleMember.Type -ne "IPSet"){
            if($RuleMember.Type -eq "Ipv4Address"){
                $member_name = $RuleMember.Value
            }
            else{
                $member_name = $RuleMember.Name
            }
            Write-Output ("Rule ID: "+$RuleMember.ruleid)
            Write-Output ("Section ID: "+$RuleMember.SectionId)
            Write-Output ("Member Type: "+$RuleMember.Type)
            Write-Output ("Member Name: "+$member_name)
            Write-Output ("")
            Write-Output ("")
            Write-Output ("")

            $section = Get-NsxFirewallSection | where({$_.id -eq $RuleMember.SectionId })

            $RuleMemberObject = [PSCustomObject]@{ 
                section_id = $RuleMember.SectionId
                section_name = $section.name 
                rule_id = $RuleMember.ruleid
                rule_name = $NsxVRule.name
                rule_member_type = $RuleMember.Type
                member_name = $member_name
            }

            $RuleMemberArray += $RuleMemberObject
        }
    }
}

$RuleMemberArray.count

$RuleMemberArray | ConvertTo-Json -Depth 10 | Out-File ".\nsxv-rule-member-audit.json"
