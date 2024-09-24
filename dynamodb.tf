#################################################################################################
# This file describes the DynamoDB resources: dynamodb table, dynamodb endpoint
#################################################################################################

#Dynamodb Table
resource "aws_dynamodb_table" "test_table" {
    name                = "leavedays"
    billing_mode        = "PAY_PER_REQUEST"
    hash_key            = "leave_id"
    attribute {
        name            = "leave_id"
        type            = "N"
    }
    tags = {
        Name = "${random_string.string.id}-leavedays-dydb"
    }
}

#DynamoDB Endpoint
resource "aws_vpc_endpoint" "dynamodb_Endpoint" {
    vpc_id              = aws_vpc.vpc.id
    service_name        = "com.amazonaws.${var.region}.dynamodb"
    vpc_endpoint_type   = "Gateway"
    route_table_ids     = [aws_route_table.private.id]
    policy              = jsonencode({
        "Version"       : "2012-10-17",
        "Statement"     : [
            {
                "Effect"    : "Allow",
                "Principal" : "*",
                "Action"    : "*",
                "Resource"  : "*"
            }
        ]
    })
}
