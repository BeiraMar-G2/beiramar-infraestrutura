
# ---------------------------------------------------------
# --- GLUE DATABASE ---
# ---------------------------------------------------------

resource "aws_glue_catalog_database" "refined_db" {
  name        = "refined_beira_mar"
  description = "Database com dados integrados (clima + consultas)"
}

resource "aws_glue_catalog_database" "star_schema_db" {
  name        = "star_schema_beira_mar"
  description = "Database com modelagem estrela"
}

# ---------------------------------------------------------
# --- GLUE CRAWLER ---
# ---------------------------------------------------------

resource "aws_glue_crawler" "refined_crawler" {
  name          = "refined-clinica-clima-crawler"
  role          = data.aws_iam_role.lab_role.arn
  database_name = aws_glue_catalog_database.refined_db.name
  
  s3_target {
    path = "s3://${aws_s3_bucket.refined.id}/clinica_com_clima/"
  }
  
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}
