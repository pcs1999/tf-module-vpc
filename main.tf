resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = merge(
    local.common_tags,
    { Name = "${var.env}-vpc" }
  )
}

resource "aws_subnet" "public" {
  count      = length(var.public_subnets_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets_cidr[count.index]

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-public-subnet-${count.index + 1}" }
  )
}

resource "aws_subnet" "private" {
  count      = length(var.private_subnets_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets_cidr[count.index]

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-private-subnet-${count.index + 1}" }
  )
}

resource "aws_vpc_peering_connection" "peer" {
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.main.id
  auto_accept   = true
  tags = merge(
    local.common_tags,
    { Name = "${var.env}-peering" }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-igw" }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-public-route-table" }
  )
}

resource "aws_route_table_association" "public-rt-assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "ngw-eip" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw-eip.id
  subnet_id     = aws_subnet.public.*.id[0]

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-ngw" }
  )

  //depends_on = [aws_internet_gateway.example]
}