resource "aws_s3_bucket" "raw" {
  bucket = "raw-beira-mar"
}

resource "aws_s3_bucket" "trusted" {
  bucket = "trusted-beira-mar"
}

resource "aws_s3_object" "trusted_pastas" {
  count   = length(var.trusted_folders)
  bucket  = aws_s3_bucket.trusted.id
  key     = "${var.trusted_folders[count.index]}/"
  content = ""
  etag    = md5("") 
}

resource "aws_s3_bucket" "refined" {
  bucket = "refined-beira-mar"
}

resource "aws_s3_object" "refined_pastas" {
  count   = length(var.refined_folders)
  bucket  = aws_s3_bucket.refined.id
  key     = "${var.refined_folders[count.index]}/"
  content = ""
  etag    = md5("")
}

# ---------------------------------------------------------
# --- VARIÁVEIS ---
# ---------------------------------------------------------

variable "trusted_folders" {
  description = "Lista de pastas a serem criadas no bucket trusted"
  type        = list(string)
  default     = ["clima", "clinica"]
}

variable "refined_folders" {
  description = "Lista de pastas a serem criadas no bucket refined"
  type        = list(string)
  default     = ["clinica_com_clima"]
}
