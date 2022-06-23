resource "kubernetes_namespace" "example" {
  for_each = var.namespaces
  metadata {
  name = each.key
  }
}
