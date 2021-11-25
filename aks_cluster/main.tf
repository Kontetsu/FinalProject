terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.86.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.6.1"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

resource "random_pet" "prefix" {
  
}

# Create azure resource group
resource "azurerm_resource_group" "akscluster" {
  name                  = "akscluster"
  location              = "eastus"
}

resource "azurerm_kubernetes_cluster" "akscluster" {
  name                  = "${random_pet.prefix.id}-aks"
  location              = azurerm_resource_group.akscluster.location
  resource_group_name   = azurerm_resource_group.akscluster.name
  dns_prefix            = "ergetaks"

  default_node_pool {
    name                = "ergi"
    node_count          = 1
    vm_size             = "Standard_D2_v2"
    os_disk_size_gb     = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled             = true
  } 

  tags = {
    environment         = "AKS"
  }
}

provider "kubernetes" {
  config_path           = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "testenv" {
  name                    = "testenv"
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.akscluster.id
  vm_size                 = "Standard_D2_v2"
  node_count              = 1

  tags = {
    Environment = "TestENV"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "prodenv" {
  name                    = "prodenv"
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.akscluster.id
  vm_size                 = "Standard_D2_v2"
  node_count              = 1

  tags = {
    Environment = "ProdENV"
  }
}

# resource "kubernetes_namespace" "testenv" {
#   metadata {
#     name                = "testenv"
#   }
# }

# resource "kubernetes_deployment" "backend" {
#   metadata {
#     name                    = "backend"
#     namespace               = "testenv"
#   }
#   spec {
#     replicas = 1
#     selector {
#       match_labels = {
#         app = "backend"
#         tier = "backend"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "backend"
#           tier = "backend"
#         }
#       }
#       spec {
#         node_name = azurerm_kubernetes_cluster_node_pool.testenv.name
#         container {
#           image = "kontetsu/backend-update:v1"
#           image_pull_policy = "Always"
#           name = "backend"
#           port {
#             container_port = 8080
#             name = "http"
#             protocol = "TCP"
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "backend" {
#   metadata {
#     name                    = "backend"
#     namespace               = "testenv"
#   }
#   spec {
#     port {
#       port = 8080
#       protocol = "TCP"
#       target_port = 8080
#     }
#     selector = {
#       app                 = "backend"
#       tier                = "backend"
#     }
#     type = "ClusterIP"
#   }
# }

# resource "kubernetes_deployment" "frontend" {
#   metadata {
#     name                        = "frontend"
#     namespace                   = "testenv"
#   }
#   spec {
#     replicas                    = 2
#     selector {
#       match_labels              = {
#         app                     = "frontend"
#       }
#     }
#     template {
#       metadata {
#         labels                  = {
#             app                 = "frontend"
#         }
#       }
#       spec {
#         node_name = azurerm_kubernetes_cluster_node_pool.testenv.name
#         container {
#           image                 = "kontetsu/frontend-update:v1"
#           image_pull_policy     = "Always"
#           name                  = "frontend"
#           port {
#             container_port      = 80
#             protocol            = "TCP"
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "frontend" {
#   metadata {
#     name                    = "frontend"
#     namespace               = "testenv"
#   }
#   spec {
#     port {
#       port                  = 80
#       protocol              = "TCP"
#       target_port           = 80
#     }
#     selector                = {
#       app                   = "frontend"
#     }
#     type                    = "ClusterIP"
#   }
# }

# resource "helm_release" "ingress_nginx" {
#   name       = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx" 
#   chart      = "ingress-nginx"
#   namespace  = "testenv"
#   timeout    = 300

# }


# resource "kubernetes_ingress" "ingress" {
#   metadata {
#       labels                = {
#         app                 = "ingress-nginx"
#       }
#     name                    = "ingress-front-back-update"
#     namespace               = "testenv"
#     annotations             = {
#         "kubernetes.io/ingress.class": "nginx"
#         "nginx.ingress.kubernetes.io/ssl-redirect": "false"
#         "nginx.ingress.kubernetes.io/use-regex": "true"
#         "nginx.ingress.kubernetes.io/rewrite-target": "/$1"
#     }
#   }
#   spec {
#     backend {
#       service_name = "frontend"
#       service_port = 80
#     }
#     rule {
#       http {
#         path {
#           path = "/?(.*)"
#           backend {
#             service_name = "frontend"
#             service_port = 80
#           }
#         }
#         path {
#           path = "/api/quiz/select?(.*)"
#           backend {
#             service_name = "backend"
#             service_port = 8080
#           }
#         }
#       }
#     }
#   }
# }
