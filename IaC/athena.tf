
# ---------------------------------------------------------
# --- ATHENA WORKGROUP ---
# ---------------------------------------------------------

resource "aws_athena_workgroup" "beira_mar_workgroup" {
  name = "beira-mar-analytics"
  
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/output/"
    }
    enforce_workgroup_configuration = true
  }
}

# ---------------------------------------------------------
# --- OUTPUTS ---
# ---------------------------------------------------------

output "bucket_raw" {
  value = aws_s3_bucket.raw.id
}

output "bucket_trusted" {
  value = aws_s3_bucket.trusted.id
}

output "bucket_refined" {
  value = aws_s3_bucket.refined.id
}

output "instrucoes" {
  value = <<-EOT
    ✅ Infraestrutura criada!
    Próximos passos:
    1. Execute o arquivo .py 01_envio_bucket_raw.py
    2. Execute no bash: ./01run_pipeline.sh
  EOT
}