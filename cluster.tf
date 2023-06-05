resource "aws_eks_cluster" "demo-cluster" {
  name     = "demo-ekscluster"
  role_arn = aws_iam_role.demo-role.arn
  #depends_on = [aws_cloudwatch_log_group.example]

  enabled_cluster_log_types = ["api", "audit"]



  vpc_config {
    # subnet_ids = ["subnet-0e755ed6f030f1699", "subnet-0891d161ef90bd0e4"]
    subnet_ids = ["${aws_subnet.datasubnet[1].id}", "${aws_subnet.datasubnet[2].id}"]

  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.demo-eksclusterpolicy,
    aws_iam_role_policy_attachment.demo-AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.demo-cloud-loggroup,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.demo-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.demo-cluster.certificate_authority[0].data
}




resource "aws_cloudwatch_log_group" "demo-cloud-loggroup" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/demo-ekscluster/cluster"
  retention_in_days = 7

  # ... potentially other configuration ...
}



data "tls_certificate" "demo-eks-data" {
  url = aws_eks_cluster.demo-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "demo-iamprovider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.demo-eks-data.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.demo-eks-data.url
}

data "aws_iam_policy_document" "demo-example_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.demo-iamprovider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.demo-iamprovider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "demo-assumerole" {
  assume_role_policy = data.aws_iam_policy_document.demo-example_assume_role_policy.json
  name               = "demo-assumerole"
}

# vpc_config {
#     endpoint_private_access = true
#     endpoint_public_access  = false
#     # ... other configuration ...
#   }

#   outpost_config {
#     control_plane_instance_type = "m5d.large"
#     outpost_arns                = [data.aws_outposts_outpost.example.arn]
#   }