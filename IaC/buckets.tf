
# ---------------------------------------------------------
# --- BUCKETS S3 ---
# ---------------------------------------------------------

resource "aws_s3_bucket" "raw" {
  bucket = "raw-beira-mar-2025"
}

resource "aws_s3_bucket" "trusted" {
  bucket = "trusted-beira-mar-2025"
}

resource "aws_s3_object" "trusted_pastas" {
  count   = 2
  bucket  = aws_s3_bucket.trusted.id
  key     = "${element(["clima", "clinica"], count.index)}/"
  content = ""
  etag    = md5("") 
}

resource "aws_s3_bucket" "refined" {
  bucket = "refined-beira-mar-2025"
}

resource "aws_s3_object" "refined_pastas" {
  bucket  = aws_s3_bucket.refined.id
  key     = "clinica_com_clima/"
  content = ""
  etag    = md5("")
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "athena-results-beira-mar-2025"
}
