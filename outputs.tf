output "vpc_id" {
    value = aws_vpc.main_id
}

output "vpc_peering_connection_id" {
    value = aws_vpc_peering_connection.peer.id
}