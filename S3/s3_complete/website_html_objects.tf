# Automatically upload index.html to website bucket
resource "aws_s3_object" "index" {
  count        = var.enable_website ? 1 : 0
  bucket       = aws_s3_bucket.website[0].id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-EOF
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>S3 Static Website</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                text-align: center;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                color: white;
            }
            .container {
                background: rgba(255, 255, 255, 0.95);
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                color: #333;
            }
            h1 { color: #232F3E; margin-bottom: 20px; }
            p { color: #666; font-size: 18px; }
            .footer {
                margin-top: 40px;
                padding-top: 20px;
                border-top: 2px solid #eee;
                font-size: 14px;
                color: #999;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome to S3 Static Website Hosting</h1>
            <p>This is a static website hosted on Amazon S3</p>
            <p>✅ Website is working correctly!</p>
            <div class="footer">
                Designed by Enoch Farodoye
            </div>
        </div>
    </body>
    </html>
  EOF
}

# Automatically upload error.html to website bucket
resource "aws_s3_object" "error" {
  count        = var.enable_website ? 1 : 0
  bucket       = aws_s3_bucket.website[0].id
  key          = "error.html"
  content_type = "text/html"
  content      = <<-EOF
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>404 - Page Not Found</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                text-align: center;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                color: white;
            }
            .container {
                background: rgba(255, 255, 255, 0.95);
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                color: #333;
            }
            h1 { color: #D13212; margin-bottom: 20px; }
            p { color: #666; font-size: 18px; }
            a { color: #667eea; text-decoration: none; font-weight: bold; }
            a:hover { text-decoration: underline; }
            .footer {
                margin-top: 40px;
                padding-top: 20px;
                border-top: 2px solid #eee;
                font-size: 14px;
                color: #999;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>404 - Page Not Found</h1>
            <p>The page you're looking for doesn't exist.</p>
            <a href="/">← Go back to home</a>
            <div class="footer">
                Designed by Enoch Farodoye
            </div>
        </div>
    </body>
    </html>
  EOF
}

