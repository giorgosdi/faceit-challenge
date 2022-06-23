resource "helm_release" "metric-server" {
  name       = "metric-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/" 
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.8.2"
}

resource "helm_release" "flux" {
  name = "flux2"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart = "flux2"
  namespace = "flux-system"
  version = "0.20.0"
}

resource "helm_release" "flux-sync" {
  name = "flux2-sync"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart = "flux2-sync"
  namespace = "flux-system"
  version = "0.4.2"


  set {
    name = "gitRepository.spec.url"
    value = var.flux_sync_repo
  }

  set {
    name = "gitRepository.spec.ref.branch"
    value = var.flux_sync_branch
  }

  set {
    name = "gitRepository.spec.interval"
    value = var.flux_sync_pull_interval
  }
  set {
    name = "kustomization.spec.interval"
    value = var.flux_sync_apply_interval
  }
}

resource "helm_release" "eso" {
  name = "eso"
  repository = "https://charts.external-secrets.io"
  chart = "external-secrets"
  namespace = "test"
  version = "0.5.6"

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_secrets_irsa_role.iam_role_arn
    }

  set {
    name = "serviceAccount.name"
    value = "eso"
  }

  set {
    name = "scopedNamespace"
    value = var.eso_scoped_namespace
  }
  set {
    name = "scopedRBAC"
    value = true
  }
}

resource "helm_release" "cluster-autoscaler" {
  name = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"
  namespace = "kube-system"
  version = "9.19.1"

  set {
    name = "autoscalingGroups[0].name"
    value = module.eks.self_managed_node_groups_autoscaling_group_names[0]
  }
  
  set {
    name = "autoscalingGroups[0].minSize"
    value = var.ca_min_size
  }

  set {
    name = "autoscalingGroups[0].maxSize"
    value = var.ca_max_size
  }

  set {
    name = "rbac.serviceAccount.name"
    value = "ca"
  }

  set {
    name = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ca_irsa_role.iam_role_arn
  }

}

resource "kubernetes_service_account" "awslb_sa" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.awslb_irsa_role.iam_role_arn
    }
  }
}


resource "helm_release" "awslb" {
  name = "aws-lb-controller"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  namespace = "kube-system"
  version = "1.4.2"

  set {
    name = "clusterName"
    value = module.eks.cluster_id
  }
  set {
    name = "serviceAccount.create"
    value = false
  }
  set {
    name = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  namespace = "monitoring"
  version = "36.0.2"
}
