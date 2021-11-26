targetScope='resourceGroup'

var parameters = json(loadTextContent('parameters.json'))

resource vnethub 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: '${parameters.prefix}-hub'
  location: parameters.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'hub-sn'
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
  name: '${parameters.prefix}-spoke1'
  location: parameters.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'spoke1-sn'
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
  name: '${parameters.prefix}-spoke2'
  location: parameters.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'spoke2-sn'
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
  name: '${parameters.prefix}hub-nic'
  location: parameters.location
  properties: {
    ipConfigurations: [
      {
        name: '${parameters.prefix}hub-ipconfig1'
        properties: {
          privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnethub.id}/subnets/hub-sn'
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
  name: '${parameters.prefix}spoke1-nic'
  location: parameters.location
  properties: {
    ipConfigurations: [
      {
        name: '${parameters.prefix}spoke1-ipconfig1'
        properties: {
          privateIPAddress: '10.1.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnetspoke1.id}/subnets/spoke1-sn'
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
  name: '${parameters.prefix}spoke2-nic'
  location: parameters.location
  properties: {
    ipConfigurations: [
      {
        name: '${parameters.prefix}spoke2-ipconfig1'
        properties: {
          privateIPAddress: '10.2.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnetspoke2.id}/subnets/spoke2-sn'
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
  name: '${parameters.prefix}vmhub'
  location: parameters.location
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
        name: '${parameters.prefix}vmhub-disc'
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
      computerName: '${parameters.prefix}vmhub'
      adminUsername: 'chpinoto'
      adminPassword: 'demo!pass123'
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
  name: '${parameters.prefix}vmspoke1'
  location: parameters.location
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
        name: '${parameters.prefix}vmspoke1-disc'
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
      computerName: '${parameters.prefix}vmspoke1'
      adminUsername: 'chpinoto'
      adminPassword: 'demo!pass123'
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
  name: '${parameters.prefix}vmspoke2'
  location: parameters.location
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
        name: '${parameters.prefix}vmspoke2-disc'
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
      computerName: '${parameters.prefix}vmspoke2'
      adminUsername: 'chpinoto'
      adminPassword: 'demo!pass123'
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
  location: parameters.location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: '${vmAADSSHLoginExName}'
    typeHandlerVersion: '1.0'
  }
}

resource vmspoke1aadextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmspoke1
  name: '${vmAADSSHLoginExName}'
  location: parameters.location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: '${vmAADSSHLoginExName}'
    typeHandlerVersion: '1.0'
  }
}

resource vmspoke2aadextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmspoke2
  name: '${vmAADSSHLoginExName}'
  location: parameters.location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: '${vmAADSSHLoginExName}'
    typeHandlerVersion: '1.0'
  }
}

var roleVirtualMachineAdministratorName = '1c0163c0-47e6-4577-8991-ea5c82e286e4' //Virtual Machine Administrator Login

resource raMe2VMHub 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id,'raMe2VMHub')
  properties: {
    principalId: parameters.myObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions',roleVirtualMachineAdministratorName)
  }
}

resource pubip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: parameters.prefix
  location: parameters.location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: parameters.prefix
  location: parameters.location
  sku: {
    name:'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: '${parameters.prefix}-ipconfig'
        properties: {
          publicIPAddress: {
            id: pubip.id
          }
          subnet: {
            id: '${vnethub.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

resource VnetPeering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
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

resource VnetPeering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
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

resource pDNS1 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'pzone1.myedge.org'
  location: 'global'
}

resource dnslinkhub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: pDNS1
  name: 'link2hub'
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
  name: 'link2spoke1'
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
  name: 'link2spoke2'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetspoke2.id
    }
  }
}
