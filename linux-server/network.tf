resource "azurerm_resource_group" "elite_network_rg" {
  name     = "elite_network_rg"
  location = "eastus2"
}

resource "azurerm_virtual_network" "elite_linux_vnet" {
  name                = "elite_linux_vnet"
  location            = azurerm_resource_group.elite_network_rg.location
  resource_group_name = azurerm_resource_group.elite_network_rg.name
  address_space       = ["10.0.0.0/16"]
  #   dns_servers         = ["10.0.0.4", "10.0.0.5"]

  # subnet = []


  tags = {
    environment = "Development"
    Company     = "Elitesolutionit"
    ManagedWith = "Terraform"
  }
}

resource "azurerm_network_security_group" "elitedev_nsg" {
  name                = "elitedev_nsg"
  location            = azurerm_resource_group.elite_network_rg.location
  resource_group_name = azurerm_resource_group.elite_network_rg.name
}

resource "azurerm_network_security_rule" "SSH" {
  name                        = "SSH"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "84.232.141.74"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.elite_network_rg.name
  network_security_group_name = azurerm_network_security_group.elitedev_nsg.name
}

resource "azurerm_route_table" "elite_rtb" {
  name                          = "elite_rtb"
  location                      = azurerm_resource_group.elite_network_rg.location
  resource_group_name           = azurerm_resource_group.elite_network_rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "10.0.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet" "db-subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.elite_network_rg.name
  virtual_network_name = azurerm_virtual_network.elite_linux_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app-subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.elite_network_rg.name
  virtual_network_name = azurerm_virtual_network.elite_linux_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet_route_table_association" "elite_rtb_assoc_db" {
  subnet_id      = azurerm_subnet.db-subnet.id
  route_table_id = azurerm_route_table.elite_rtb.id
}

resource "azurerm_subnet_route_table_association" "elite_rtb_assoc_app" {
  subnet_id      = azurerm_subnet.app-subnet.id
  route_table_id = azurerm_route_table.elite_rtb.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc_db" {
  subnet_id                 = azurerm_subnet.db-subnet.id
  network_security_group_id = azurerm_network_security_group.elitedev_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc_app" {
  subnet_id                 = azurerm_subnet.app-subnet.id
  network_security_group_id = azurerm_network_security_group.elitedev_nsg.id
}