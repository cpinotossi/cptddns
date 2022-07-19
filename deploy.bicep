targetScope='resourceGroup'

var parameters = json(loadTextContent('parameters.json'))
param location string
param prefix string
param myObjectId string = '00000000-0000-0000-0000-0000-000000000000'

resource vnethub 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: '${prefix}hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${prefix}hub'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource vnetspoke1 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: '${prefix}spoke1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${prefix}spoke1'
        properties: {
          addressPrefix: '10.1.0.0/16'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource vnetspoke2 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: '${prefix}spoke2'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${prefix}spoke2'
        properties: {
          addressPrefix: '10.2.0.0/16'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource nichub 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${prefix}hub'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}hub'
        properties: {
          privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnethub.id}/subnets/${prefix}hub'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource nicspoke1 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${prefix}spoke1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}spoke1'
        properties: {
          privateIPAddress: '10.1.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnetspoke1.id}/subnets/${prefix}spoke1'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource nicspoke2 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${prefix}spoke2'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}spoke2'
        properties: {
          privateIPAddress: '10.2.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnetspoke2.id}/subnets/${prefix}spoke2'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource vmhub 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: '${prefix}hub'
  location: location
  zones: [
    '1'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      osDisk: {
        name: '${prefix}hub'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${prefix}hub'
      adminUsername: parameters.login
      adminPassword: parameters.password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nichub.id
        }
      ]
    }
  }
}

resource vmspoke1 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: '${prefix}spoke1'
  location: location
  zones: [
    '1'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      osDisk: {
        name: '${prefix}spoke1'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${prefix}spoke1'
      adminUsername: parameters.login
      adminPassword: parameters.password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicspoke1.id
        }
      ]
    }
  }
}

resource vmspoke2 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: '${prefix}spoke2'
  location: location
  zones: [
    '1'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      osDisk: {
        name: '${prefix}spoke2'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${prefix}spoke2'
      adminUsername: parameters.login
      adminPassword: parameters.password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicspoke2.id
        }
      ]
    }
  }
}


var vmAADSSHLoginExName = 'AADSSHLoginForLinux'

resource vmhubaadextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmhub
  name: '${vmAADSSHLoginExName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: '${vmAADSSHLoginExName}'
    typeHandlerVersion: '1.0'
  }
  dependsOn:[
    vmhub
  ]
}

resource vmspoke1aadextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmspoke1
  name: '${vmAADSSHLoginExName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: '${vmAADSSHLoginExName}'
    typeHandlerVersion: '1.0'
  }
  dependsOn:[
    vmspoke1
  ]
}

resource vmspoke2aadextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmspoke2
  name: '${vmAADSSHLoginExName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: '${vmAADSSHLoginExName}'
    typeHandlerVersion: '1.0'
  }
  dependsOn:[
    vmspoke2
  ]
}

var roleVirtualMachineAdministratorName = '1c0163c0-47e6-4577-8991-ea5c82e286e4' //Virtual Machine Administrator Login

resource raMe2VMHub 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id,'raMe2VMHub')
  properties: {
    principalId: myObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions',roleVirtualMachineAdministratorName)
  }
}

resource bastionpubip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: prefix
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    dnsName:'${prefix}.bastion.azure.com'
    enableTunneling: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionpubip.id
          }
          subnet: {
            id: '${vnethub.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

resource VnetPeeringhubspoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnethub
  name: 'hub-spoke1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetspoke1.id
    }
  }
}

resource VnetPeeringspoke1hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetspoke1
  name: 'spoke1-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnethub.id
    }
  }
}

resource vnetpeeringhhubspoke2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnethub
  name: 'hub-spoke2'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetspoke2.id
    }
  }
}

resource VnetPeeringspoke2hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetspoke2
  name: 'spoke2-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnethub.id
    }
  }
}

resource pDNS1 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'pzone1.myedge.org'
  location: 'global'
}

resource pDNS2 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'pzone2.myedge.org'
  location: 'global'
}

resource dnslinkhub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: pDNS1
  name: 'z1hub'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnethub.id
    }
  }
}

resource dnslinkspoke1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: pDNS1
  name: 'z1spoke1'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetspoke1.id
    }
  }
}

resource dnslinkspoke2 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: pDNS1
  name: 'z1spoke2'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetspoke2.id
    }
  }
}
