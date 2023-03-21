<#
Example Command:
.\nsxv2t-cleanup-services-vOrigin-tags.ps1

#>

# Param (
#     [Parameter(Mandatory=$True)][String]$ImportFile
# )

$NsxTServices = (Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.services).list().results
# $vOriginServices = $NsxTServices.where({$_.tags.scope -eq "v_origin" -AND $_.display_name -match "s-test-harry"})
# $vOriginServices = $NsxTServices.where({$_.tags.scope -eq "v_origin"})
$vOriginServices = $NsxTServices.where({$_.tags.scope -eq "v_origin" -AND $_.display_name -match "IPv6-ICMP Echo"})
# Loop through each  inputgroup
foreach ($vOriginService in $vOriginServices) {
    Write-Output ($vOriginService.display_name)
    Write-Output ($vOriginService.id)
    Write-Output ("========================================")

    $servicedata = Get-NsxtpolicyService -Name com.vmware.nsx_policy.infra.services

    $servicespec = $servicedata.Help.update.service.Create()

    $servicespec.id = $vOriginService.id
    $servicespec.display_name = $vOriginService.display_name
    $servicespec.description = $vOriginService.description
    $servicespec.resource_type = $vOriginService.resource_type
    # $servicespec.service_entries = $vOriginService.service_entries
    $servicespec.service_type = $vOriginService.service_type

    # Tags
    foreach ($t in $vOriginService.tags){
        if ($t.scope -ne "v_origin"){
            $servicetag = $servicedata.Help.patch.service.tags.Element.Create()
            $servicetag.tag = $t.tag
            $servicetag.scope = $t.scope
            $servicespec.tags.Add($servicetag) | Out-Null
        } 
    }

    $existingServiceEntries = $vOriginService.service_entries
    # PS D:\OneDrive\Repos\nsxv2t> $vOriginServices.service_entries.resource_type | sort | unique
    # ALGTypeServiceEntry
    # ICMPTypeServiceEntry
    # IPProtocolServiceEntry       
    # L4PortSetServiceEntry        
    # NestedServiceServiceEntry   
    foreach ($es in $existingServiceEntries) { 
        # Existing ALGTypeServiceEntry Echo

        if ($es.resource_type -eq "ALGTypeServiceEntry"){
            $serviceEntrySpec = $servicedata.Help.patch.service.service_entries.element.ALG_type_service_entry.Create()
            $serviceEntrySpec.resource_type = $es.resource_type
            $serviceEntrySpec.id = $es.id
            $serviceEntrySpec.display_name = $es.display_name
            $serviceEntrySpec.description = $es.description
            $serviceEntrySpec.alg = $es.alg
            $serviceEntrySpec.destination_ports = $es.destination_ports
            $serviceEntrySpec.source_ports = $es.source_ports
            try {
                $servicespec.service_entries.Add($serviceEntrySpec) | Out-Null
                Write-Output ("ALGTypeServiceEntry has been added")
            } catch {
                Write-Output ("ALGTypeServiceEntry Failed to be added")
            }               
        }
        if ($es.resource_type -eq "ICMPTypeServiceEntry"){
            $serviceEntrySpec = $servicedata.Help.patch.service.service_entries.element.ICMP_type_service_entry.Create()
            $serviceEntrySpec.resource_type = $es.resource_type
            $serviceEntrySpec.id = $es.id
            $serviceEntrySpec.display_name = $es.display_name
            $serviceEntrySpec.description = $es.description
            $serviceEntrySpec.protocol = $es.protocol
            $serviceEntrySpec.icmp_type = $es.icmp_type
            try {
                #$servicespec.service_entries.Add($serviceEntrySpec) | Out-Null
                Write-Output ("ICMPTypeServiceEntry has been added")
            } catch {
                Write-Output ("ICMPTypeServiceEntry Failed to be added")
            }               
        }        
        if ($es.resource_type -eq "IPProtocolServiceEntry"){
            $serviceEntrySpec = $servicedata.Help.patch.service.service_entries.element.IP_protocol_service_entry.Create()
            $serviceEntrySpec.resource_type = $es.resource_type
            $serviceEntrySpec.id = $es.id
            $serviceEntrySpec.display_name = $es.display_name
            $serviceEntrySpec.description = $es.description
            $serviceEntrySpec.protocol_number = $es.protocol_number
            try {
                #$servicespec.service_entries.Add($serviceEntrySpec) | Out-Null
                Write-Output ("IPProtocolServiceEntry has been added")
            } catch {
                Write-Output ("IPProtocolServiceEntry Failed to be added")
            }            
        }
        if ($es.resource_type -eq "L4PortSetServiceEntry"){
            $serviceEntrySpec = $servicedata.Help.patch.service.service_entries.element.l4_port_set_service_entry.Create()
            $serviceEntrySpec.resource_type = $es.resource_type
            $serviceEntrySpec.id = $es.id
            $serviceEntrySpec.display_name = $es.display_name
            $serviceEntrySpec.description = $es.description
            $serviceEntrySpec.l4_protocol = $es.l4_protocol
            $serviceEntrySpec.destination_ports = $es.destination_ports
            $serviceEntrySpec.source_ports = $es.source_ports
            try {
                $servicespec.service_entries.Add($serviceEntrySpec) | Out-Null
                Write-Output ("L4PortSetServiceEntry has been added")
            } catch {
                Write-Output ("L4PortSetServiceEntry Failed to be added")
            }
        }                
        if ($es.resource_type -eq "NestedServiceServiceEntry"){
            $serviceEntrySpec = $servicedata.Help.patch.service.service_entries.element.nested_service_service_entry.Create()
            $serviceEntrySpec.resource_type = $es.resource_type
            $serviceEntrySpec.id = $es.id
            $serviceEntrySpec.display_name = $es.display_name
            $serviceEntrySpec.description = $es.description
            $serviceEntrySpec.nested_service_path = $es.nested_service_path
            try {
                $servicespec.service_entries.Add($serviceEntrySpec) | Out-Null
                Write-Output ("NestedServiceServiceEntry has been added")
            } catch {
                Write-Output ("NestedServiceServiceEntry Failed to be added")
            }
        }                  
    }


    # Patch Service
    try {
        # $servicespec
        $servicedata.patch($servicespec.id, $servicespec)
        Write-Host -ForegroundColor Green $vOriginService.display_name ' successfully patched' 

    } catch {
        Write-Host -ForegroundColor Red $vOriginService.display_name ' FAILED...Investigate'
        Write-Output ("GroupSpec...........................................")
        $servicespec
    }

    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
    Write-Output ("")
}