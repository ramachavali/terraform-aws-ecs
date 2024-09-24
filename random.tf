resource "random_string" "string" {
  length           = 6
  special          = false
  upper            = false
}

resource "random_id" "tag" {
  byte_length = 6
}
