# Azure DNS Demos

## How does Azure Private DNS auto registration look like?

- Setup a simple hub and spoke vnet architecture.
- Create a VM on each vnet.
 - Each VM does support AAD login. 
- Create a single private DNS zone.
- Link each vnet to the private DNS zone with auto registration turned on.
- Create bastion host
- Verify if A-records are auto populated into the private dns zone
- log into vm and test dns resolution

Target Enviroment.

~~~ mermaid
classDiagram
pDNS1 --> hub : link/autoreg
pDNS1 --> spoke1 : link/autoreg
pDNS1 --> spoke2 : link/autoreg
pDNS1: pzone1.myedge.org
pDNS2 --> hub : link/resolve
pDNS2: pzone2.myedge.org
hub --> spoke1 : peering
hub --> spoke2 : peering
hub : bastion
hub : cidr 10.0.0.0/16
spoke1 : cidr 10.1.0.0/16
spoke2 : cidr 10.2.0.0/16
hub : vm 10.0.0.4
spoke1 : vm 10.1.0.4
spoke2 : vm 10.2.0.4
~~~

Create enviroment. 

~~~ bash
prefix=cptddns
location=eastus
az group create -l eastus -n cptddns
myid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) # my obj id
# Create the enviroment
az deployment group create -g $prefix -n create --template-file deploy.bicep --parameters myObjectId=$myid location=$location prefix=$prefix
az group delete -n $prefix -y
~~~

Verify vnet peering.

~~~ bash
az network vnet list --query "[?resourceGroup=='${prefix}'].{name:name,subnets:subnets[].name,virtualNetworkPeering:virtualNetworkPeerings[].name}"
~~~

Result:

~~~ json
[
  {
    "name": "cptddnshub",
    "subnets": [
      "cptddnshub",
      "AzureBastionSubnet"
    ],
    "virtualNetworkPeering": [
      "hub-spoke2",
      "hub-spoke1"
    ]
  },
  {
    "name": "cptddnsspoke1",
    "subnets": [
      "cptddnsspoke1"
    ],
    "virtualNetworkPeering": [
      "spoke1-hub"
    ]
  },
  {
    "name": "cptddnsspoke2",
    "subnets": [
      "cptddnsspoke2"
    ],
    "virtualNetworkPeering": [
      "spoke2-hub"
    ]
  }
]
~~~

List vn names.

~~~ bash
az vm list -g $prefix --query '[].{name:name,networkProfile:networkProfile.networkInterfaces[].id}' --query [].name -o tsv
~~~

Result

~~~ json
[
  "cptddnshub",
  "cptddnsspoke1",
  "cptddnsspoke2"
]
~~~

List VM/NICs ips.

~~~ bash
az network nic list -g $prefix --query '[].{name:name,privateIpAddress:ipConfigurations[0].privateIpAddress}'
~~~

Result.

~~~ json
[
  {
    "name": "cptddnshub",
    "privateIpAddress": "10.0.0.4"
  },
  {
    "name": "cptddnsspoke1",
    "privateIpAddress": "10.1.0.4"
  },
  {
    "name": "cptddnsspoke2",
    "privateIpAddress": "10.2.0.4"
  }
]
~~~

Verify private DNS Zone

~~~ bash
az network private-dns zone list -g $prefix --query '[].{name:name,numberOfRecordSets:numberOfRecordSets}'
~~~

Result

~~~ json
[
  {
    "name": "pzone1.myedge.org",
    "numberOfRecordSets": 6
  },
  {
    "name": "pzone2.myedge.org",
    "numberOfRecordSets": 1
  }
]
~~~

### Why 6 a records?

When you enable autoregistration on a virtual network link, the DNS records for the virtual machines in that virtual network are registered in the private zone. When autoregistration gets enabled, Azure DNS will update the zone record whenever a virtual machine gets created, changes its' IP address, or gets deleted.

List all A Records

~~~ bash
z1=$(az network private-dns zone list -g $prefix --query '[0].name' -o tsv)
az network private-dns record-set a list -g $prefix -z $z1 --query '[].{aRecords:aRecords[0].ipv4Address,fqdn:fqdn}'
~~~

Result

~~~ json
[
  {
    "aRecords": "10.0.0.4",
    "fqdn": "cptddnshub.pzone1.myedge.org."
  },
  {
    "aRecords": "10.1.0.4",
    "fqdn": "cptddnsspoke1.pzone1.myedge.org."
  },
  {
    "aRecords": "10.2.0.4",
    "fqdn": "cptddnsspoke2.pzone1.myedge.org."
  },
  {
    "aRecords": "10.0.1.4",
    "fqdn": "vm000000.pzone1.myedge.org."
  },
  {
    "aRecords": "10.0.1.5",
    "fqdn": "vm000001.pzone1.myedge.org."
  }
]
~~~

ANSWER:
vm000000 and vm000001 belong to Azure Bastion Host.

### Resolve spoke1 vm from hub vm

~~~ bash
vmhubid=$(az vm show -g $prefix -n ${prefix}hub --query id -o tsv)
az network bastion ssh -n $prefix -g $prefix --target-resource-id $vmhubid --auth-type "AAD" # login with bastion
dig cptddnsspoke1.pzone1.myedge.org # Expect 10.1.0.4
dig cptddnsspoke2.pzone1.myedge.org # Expect 10.2.0.4
~~~

### Verify how the private DNS zone is linked with vnets

~~~bash
az network private-dns link vnet list -g $prefix -z $z1 --query '[].{name:name,virtualNetwork:virtualNetwork.id, registrationEnabled:registrationEnabled}'
~~~

Result

~~~ json
[
  {
    "name": "link2hub",
    "registrationEnabled": true,
    "virtualNetwork": "/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptddns/providers/Microsoft.Network/virtualNetworks/cptddnshub"
  },
  {
    "name": "link2spoke1",
    "registrationEnabled": true,
    "virtualNetwork": "/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptddns/providers/Microsoft.Network/virtualNetworks/cptddnsspoke1"
  },
  {
    "name": "link2spoke2",
    "registrationEnabled": true,
    "virtualNetwork": "/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptddns/providers/Microsoft.Network/virtualNetworks/cptddnsspoke2"
  }
]
~~~

NOTE: 
> "registrationEnabled": true 
The value "true" indicates that we used "autoregistration".

### Link one more private DNS zone

Link one more private dns zone to the hub vnet.

~~~ bash
z2=$(az network private-dns zone list -g $prefix --query '[1].name' -o tsv)
vnethubid=$(az network vnet show -g $prefix -n ${prefix}hub --query id -o tsv)
az network private-dns link vnet create -n z2hub -g $prefix -e false -v $vnethubid -z $z2 
az network private-dns record-set a add-record -g $prefix -z $z2 -n $prefix -a 10.10.10.10
az network private-dns record-set a list -g $prefix -z $z2 --query '[].{aRecords:aRecords[0].ipv4Address,fqdn:fqdn}'
vmhubid=$(az vm show -g $prefix -n ${prefix}hub --query id -o tsv)
az network bastion ssh -n $prefix -g $prefix --target-resource-id $vmhubid --auth-type "AAD" # login with bastion
dig cptddnsspoke1.pzone1.myedge.org # Expect 10.1.0.4
dig cptddns.pzone2.myedge.org # Expect 10.10.10.10
logout
~~~

Conclusion:
- You can link multiple private DNS zones to a single VNet for resolving. 
- You can only link one private DNS zone to a single VNet for autoregistration.
 - A single VNet cannot link with autoregistration to multiple private DNS zones. 

From the official FAQ:
- Q: Can the same private zone be used for several virtual networks for resolution?
 - A: Yes. You can link a private DNS zone with thousands of virtual networks. For more information, see Azure DNS Limits

A specific virtual network can be linked to only one private DNS zone when automatic VM DNS registration is enabled. You can, however, link multiple virtual networks to a single DNS zone
(source: https://docs.microsoft.com/en-us/azure/dns/private-dns-autoregistration#restrictions)


### Clean up

~~~ bash
az group delete -n $prefix -y
~~~

## Misc

### Git

~~~ bash
git status
git add *
git commit -m"update diagram"
git push origin master
~~~









