<#
Example Command:
.\nsxt-login.ps1 -VcIP "lab4-vcsa01.thmb.local" -VcUser "Administrator@vsphere.local" -NSXtIP "lab4-nsxtlmgr01.thmb.local" -NSXtUser "admin"
.\nsxt-login.ps1 -VcIP "lab4-vcsa01.thmb.local" -VcUser "Administrator@vsphere.local" -VcPass "Asdlkj1234!" -NSXtIP "lab4-nsxtlmgr01.thmb.local" -NSXtUser "admin" -NSXtPass "VMware1!VMware1!"
#>

# Param (
#     [Parameter(Mandatory=$True)][String]$VcIP,
#     [Parameter(Mandatory=$True)][String]$VcUser,
#     [Parameter]$VcPass,
#     [Parameter(Mandatory=$True)][String]$NSXtIP,
#     [Parameter(Mandatory=$True)][String]$NSXtUser,
#     [Parameter]$NSXtPass    
# )
param($VcIP, $VcUser, $VcPass, $NSXtIP, $NSXtUser, $NSXtPass)

#Ignore Self Signed Certs
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# if (-not $VcPass) {
#     $VcPass = Read-Host 'VC Password' -AsSecureString
#     $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($VcPass)
#     $VcPassValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
#     Connect-VIServer $VcIP -User $VcUser -Password $VcPassValue
# } else {
#     Connect-VIServer $VcIP -User $VcUser -Password $VcPass
# }


if (-not $NSXtPass) {
    $NSXtPass = Read-Host 'NSXT Password' -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NSXtPass)
    $NSXtPassValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    Connect-NsxtServer -Server $NSXtIP -User $NSXtUser -Password $NSXtPassValue
} else {
    Connect-NsxtServer -Server $NSXtIP -User $NSXtUser -Password $NSXtPass

}