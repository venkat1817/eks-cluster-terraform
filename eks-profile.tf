resource "aws_eks_node_group" "demo-node" {
  cluster_name    = aws_eks_cluster.demo-cluster.name
  node_group_name = "demo-nodegroup"
  node_role_arn   = aws_iam_role.demo-eks-role.arn
#   subnet_ids      = ["subnet-0e755ed6f030f1699"]
  subnet_ids      = [aws_subnet.datasubnet[1].id]


  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.demo-example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-example-AmazonEC2ContainerRegistryReadOnly,
  ]
}