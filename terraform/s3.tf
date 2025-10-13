resource "aws_s3_bucket" "demo_bucket" {
    bucket="${var.project_name}-forntend"
    region=var.aws_region
    
}
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket = aws_s3_bucket.demo_bucket.id
    
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
  
}
resource "aws_s3_bucket_policy" "newpolicy" {
    bucket=aws_s3_bucket.demo_bucket.id
    policy = jsonencode(
        {
    Version= "2012-10-17",
    Statement= [
        {
            Sid= "PublicReadGetObject",
            Effect= "Allow",
            Principal= "*",
            Action="s3:GetObject"
            
            Resource= "arn:aws:s3:::${aws_s3_bucket.demo_bucket.bucket}/*"
            
        }
    ]
}
        
    )
    
  
}

resource "aws_s3_bucket_website_configuration" "static" {
    bucket=aws_s3_bucket.demo_bucket.id

    index_document {
        suffix="index.html"
    }
    error_document {
      key="index.html"
    }
  
}