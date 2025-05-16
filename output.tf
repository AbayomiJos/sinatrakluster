output "cluster_id" {
  value = aws_eks_cluster.sinatra.id
}

output "node_group_id" {
  value = aws_eks_node_group.sinatra.id
}

output "vpc_id" {
  value = aws_vpc.sinatra_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.sinatra_subnet[*].id
}