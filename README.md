# Azure DNS

## How does Azure Private DNS auto registration look like?

### Goal

- Setup a simple hub and spoke vnet architecture.
- Create a VM on each vnet.
 - Each VM does support AAD login. 
- Create a single private DNS zone.
- Link each vnet to the private DNS zone with auto registration turned on.
- Create bastion host
- Verify if A-records are auto populated into the private dns zone
- log into vm and test dns resolution

### Create resource group

~~~bash
az group create -l eastus -n cptddns
~~~

### Modify Parameters File

Retrieve your Object ID

~~~bash
az ad user list --query '[?displayName==`ga`].objectId'
~~~

### Create the enviroment

~~~bash
az deployment group create -g cptddns -n create --template-file dns01.bicep
~~~

### Verify hub and spoke peering of vnet´s

~~~bash
az network vnet list --query '[?resourceGroup==`cptddns`].{name:name,subnets:subnets[].name,virtualNetworkPeering:virtualNetworkPeerings[].name}'
[
  {
    "name": "cptddns-hub",
    "subnets": [
      "hub-sn",
      "AzureBastionSubnet"
    ],
    "virtualNetworkPeering": [
      "hub-spoke1",
      "hub-spoke2"
    ]
  },
  {
    "name": "cptddns-spoke1",
    "subnets": [
      "spoke1-sn"
    ],
    "virtualNetworkPeering": []
  },
  {
    "name": "cptddns-spoke2",
    "subnets": [
      "spoke2-sn"
    ],
    "virtualNetworkPeering": []
  }
]
~~~

### List all VMs

~~~bash
az vm list -g cptddns --query '[].{name:name,networkProfile:networkProfile.networkInterfaces[].id}'
[
  {
    "name": "cptddnsvmhub",
    "networkProfile": [
      "/subscriptions/MY-SUB-ID/resourceGroups/cptddns/providers/Microsoft.Network/networkInterfaces/cptddnshub-nic"
    ]
  },
  {
    "name": "cptddnsvmspoke1",
    "networkProfile": [
      "/subscriptions/MY-SUB-ID/resourceGroups/cptddns/providers/Microsoft.Network/networkInterfaces/cptddnsspoke1-nic"
    ]
  },
  {
    "name": "cptddnsvmspoke2",
    "networkProfile": [
      "/subscriptions/MY-SUB-ID/resourceGroups/cptddns/providers/Microsoft.Network/networkInterfaces/cptddnsspoke2-nic"
    ]
  }
]
~~~

### List all NICs inside the resource Group

~~~bash
az network nic list -g cptddns --query '[].{name:name,priavteIpAddress:ipConfigurations[0].privateIpAddress}'
[
  {
    "name": "cptddnshub-nic",
    "priavteIpAddress": "10.0.0.4"
  },
  {
    "name": "cptddnsspoke1-nic",
    "priavteIpAddress": "10.1.0.4"
  },
  {
    "name": "cptddnsspoke2-nic",
    "priavteIpAddress": "10.2.0.4"
  }
]
~~~

### Verify new private DNS Zone

~~~bash
az network private-dns zone list -g cptddns --query '[].{name:name,numberOfRecordSets:numberOfRecordSets}'
[
  {
    "name": "pzone1.myedge.org",
    "numberOfRecordSets": 6
  }
]
~~~

### Why 6 a records?

List all A Records

~~~bash
az network private-dns record-set a list -gcptddns -z pzone1.myedge.org --query '[].{aRecords:aRecords[0].ipv4Address,fqdn:fqdn,ttl:ttl}'
[
  {
    "aRecords": "10.0.0.4",
    "fqdn": "cptddnsvmhub.pzone1.myedge.org.",
    "ttl": 10
  },
  {
    "aRecords": "10.1.0.4",
    "fqdn": "cptddnsvmspoke1.pzone1.myedge.org.",
    "ttl": 10
  },
  {
    "aRecords": "10.2.0.4",
    "fqdn": "cptddnsvmspoke2.pzone1.myedge.org.",
    "ttl": 10
  },
  {
    "aRecords": "10.0.1.5",
    "fqdn": "vm000000.pzone1.myedge.org.",
    "ttl": 10
  },
  {
    "aRecords": "10.0.1.4",
    "fqdn": "vm000001.pzone1.myedge.org.",
    "ttl": 10
  }
]
~~~

ANSWER:
vm000000 and vm000001 belong to Azure Bastion Host.


### Verify how the private DNS zone is linked with vnets

~~~bash
az network private-dns link vnet list -g cptddns -z pzone1.myedge.org --query '[].{name:name,virtualNetwork:virtualNetwork.id, registrationEnabled:registrationEnabled}'
[
  {
    "name": "link2hub",
    "registrationEnabled": true,
    "virtualNetwork": "/subscriptions/MY-SUB-ID/resourceGroups/cptddns/providers/Microsoft.Network/virtualNetworks/cptddns-hub"
  },
  {
    "name": "link2spoke1",
    "registrationEnabled": true,
    "virtualNetwork": "/subscriptions/MY-SUB-ID/resourceGroups/cptddns/providers/Microsoft.Network/virtualNetworks/cptddns-spoke1"
  },
  {
    "name": "link2spoke2",
    "registrationEnabled": true,
    "virtualNetwork": "/subscriptions/MY-SUB-ID/resourceGroups/cptddns/providers/Microsoft.Network/virtualNetworks/cptddns-spoke2"
  }
]
~~~

NOTE: 
> "registrationEnabled": true 
The value "true" indicates that we used "autoregistration".

### Resolve from Hub vnet

Retrieve VM resource Id

~~~bash
vmhub=$(az vm show -g cptddns -n cptddnsvmhub --query id|sed 's/"//g')
~~~

Log into VM via Bastion

~~~bash
az network bastion ssh -n cpddns -g cptddns --target-resource-id $vmhub --auth-type AAD
~~~

IMPORTANT: Did not work via my WSL. So I did went through the azure portal to use bastion.

Execute DNS lookup inside the vm

~~~bash
chpinoto@cptddnsvmhub:~$ dig cptddnsvmspoke1.pzone1.myedge.org

; <<>> DiG 9.11.3-1ubuntu1.16-Ubuntu <<>> cptddnsvmspoke1.pzone1.myedge.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4360
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;cptddnsvmspoke1.pzone1.myedge.org. INA

;; ANSWER SECTION:
cptddnsvmspoke1.pzone1.myedge.org. 10 IN A10.1.0.4

;; Query time: 12 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Fri Nov 26 12:29:14 UTC 2021
;; MSG SIZE  rcvd: 78
~~~






