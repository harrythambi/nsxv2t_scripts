<#
Example Command:
.\nsxv-login.ps1 -VcIP "lab4-vcsa01.thmb.local" -VcUser "Administrator@vsphere.local"
.\nsxv-login.ps1 -VcIP "lab4-vcsa01.thmb.local" -VcUser "Administrator@vsphere.local" -VcPass "Asdlkj1234!"
#>


#
# Param (
#     [Parameter(Mandatory=$True)][String]$VcIP,
#     [Parameter(Mandatory=$True)][String]$VcUser,
#     [Parameter][String]$VcPass
# )

param($VcIP, $VcUser, $VcPass)


Import-Module -Name powernsx

#Ignore Self Signed Certs
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

if (-not $VcPass) {
    $VcPass = Read-Host 'VC Password' -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($VcPass)
    $VcPassValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    Connect-VIServer $VcIP -User $VcUser -Password $VcPassValue
    Connect-NsxServer -vCenterServer $VcIP -ValidateCertificate:$false -Username $VcUser -Password $VcPassValue
} else {
    Connect-VIServer $VcIP -User $VcUser -Password $VcPass
    Connect-NsxServer -vCenterServer $VcIP -ValidateCertificate:$false -Username $VcUser -Password $VcPass
}