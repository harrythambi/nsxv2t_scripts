<#
Example Command:
.\nsxv2t-audit-nsxv-vmtags.ps1

#>

# The following audits every NSXv Rule whether non Security Group objects are being referenced.

$NsxSecuityTags = Get-NsxSecurityTag
$NsxSecuityTagsArray = @()

ForEach($tag in $NsxSecuityTags){
    $vms = (Get-NsxSecurityTagAssignment -SecurityTag $tag).VirtualMachine
    ForEach($vm in $vms) {
        $NsxSecuityTagsObject = [PSCustomObject]@{ 
            tag_name = $tag.name
            vm_name = $vm.name
        }
        $NsxSecuityTagsArray += $NsxSecuityTagsObject
    }
}
$NsxSecuityTagsArray.count 

$NsxSecuityTagsArray | ConvertTo-Json -Depth 10 | Out-File ".\nsxv-sectags-audit.json"
