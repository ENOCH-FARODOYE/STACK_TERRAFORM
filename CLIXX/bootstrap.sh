#!/bin/bash -xe

##############################################################################
# Pulls configuration from Management Account SSM Parameter Store
##############################################################################

exec > >(tee /var/log/clixx-bootstrap.log)
exec 2>&1

echo "=========================================="
echo "CliXX Bootstrap Started: $(date)"
echo "=========================================="

##############################################################################
# 1. Install Required Packages
##############################################################################

sudo dnf update -y
sudo dnf install -y aws-cli jq git httpd php php-mysqlnd php-fpm php-json mariadb105 amazon-efs-utils

##############################################################################
# 2. Configure Apache DirectoryIndex
##############################################################################

# Set Apache to prioritize index.php
sudo sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/httpd/conf/httpd.conf

##############################################################################
# 3. Start Apache and Create Health Check
##############################################################################

sudo systemctl start httpd
sudo systemctl enable httpd

echo "OK" | sudo tee /var/www/html/health.html
sudo chmod 644 /var/www/html/health.html

##############################################################################
# 4. Get AWS Region
##############################################################################

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
echo "Region: $REGION"

##############################################################################
# 5. Fetch Configuration from Management Account SSM
##############################################################################

# Management Account ID
MGMT_ACCOUNT="978820380225"

# Assume role in Management Account to access SSM parameters
ROLE_ARN="arn:aws:iam::${MGMT_ACCOUNT}:role/SSMParameterAccessRole"

echo "Assuming role: $ROLE_ARN"

# Get temporary credentials
CREDENTIALS=$(aws sts assume-role \
    --role-arn $ROLE_ARN \
    --role-session-name "clixx-bootstrap-$(date +%s)" \
    --external-id "clixx-ssm-access" \
    --region $REGION \
    --output json)

if [ $? -ne 0 ]; then
    echo "✗ Failed to assume role in Management Account"
    exit 1
fi

# Extract credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

echo "✓ Successfully assumed role"

# Fetch SSM parameters individually
echo "Fetching individual parameters..."

EFS_ID=$(aws ssm get-parameter --name "/clixx/efs/id" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
RDS_ENDPOINT=$(aws ssm get-parameter --name "/clixx/rds/endpoint" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
DB_NAME=$(aws ssm get-parameter --name "/clixx/rds/database" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
DB_USER=$(aws ssm get-parameter --name "/clixx/rds/username" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
DB_PASSWORD=$(aws ssm get-parameter --name "/clixx/rds/password" --with-decryption --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)

# Verify we got all parameters
if [ -z "$EFS_ID" ] || [ -z "$RDS_ENDPOINT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "✗ Failed to retrieve one or more SSM parameters"
    echo "  EFS_ID: ${EFS_ID:-MISSING}"
    echo "  RDS_ENDPOINT: ${RDS_ENDPOINT:-MISSING}"
    echo "  DB_NAME: ${DB_NAME:-MISSING}"
    echo "  DB_USER: ${DB_USER:-MISSING}"
    echo "  DB_PASSWORD: ${DB_PASSWORD:+SET}"
    exit 1
fi

echo "✓ SSM parameters retrieved"
echo "  EFS ID: $EFS_ID"
echo "  RDS Endpoint: $RDS_ENDPOINT"
echo "  Database: $DB_NAME"

# Unset temporary credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

##############################################################################
# 6. Mount EFS
##############################################################################

EFS_MOUNT="/var/www/html/efs-data"
sudo mkdir -p $EFS_MOUNT

if sudo mount -t efs -o tls $EFS_ID:/ $EFS_MOUNT; then
    echo "✓ EFS mounted"
    echo "$EFS_ID:/ $EFS_MOUNT efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
else
    echo "✗ EFS mount failed"
fi

##############################################################################
# 7. Deploy Application
##############################################################################

if [ -f "$EFS_MOUNT/.app_deployed" ]; then
    # Copy from EFS
    echo "Copying from EFS..."
    sudo cp -r $EFS_MOUNT/* /var/www/html/
else
    # First deployment
    echo "First deployment - cloning from GitHub..."
    cd $EFS_MOUNT
    sudo git clone https://github.com/stackitgit/CliXX_Retail_Repository.git
    sudo cp -r CliXX_Retail_Repository/* $EFS_MOUNT/
    sudo rm -rf CliXX_Retail_Repository

    # Configure database
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_HOST'[^;]*;/define('DB_HOST', '$RDS_ENDPOINT');/" {} \;
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_NAME'[^;]*;/define('DB_NAME', '$DB_NAME');/" {} \;
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_USER'[^;]*;/define('DB_USER', '$DB_USER');/" {} \;
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_PASSWORD'[^;]*;/define('DB_PASSWORD', '$DB_PASSWORD');/" {} \;

    sudo touch $EFS_MOUNT/.app_deployed
    sudo cp -r $EFS_MOUNT/* /var/www/html/
fi

##############################################################################
# 8. Configure WordPress Permalinks
##############################################################################

# Create .htaccess
sudo tee /var/www/html/.htaccess > /dev/null <<'HTACCESS'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
HTACCESS

# Enable AllowOverride in Apache
sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf

# Set permissions
sudo chown -R apache:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;

##############################################################################
# 9. Update WordPress Site URLs
##############################################################################

echo "Updating WordPress site URLs..."
mysql -h ${RDS_ENDPOINT%:*} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} <<EOF
UPDATE wp_options SET option_value = 'http://dev.clixx.enoch-stack.com' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://dev.clixx.enoch-stack.com' WHERE option_name = 'home';
EOF

if [ $? -eq 0 ]; then
    echo "✓ WordPress URLs updated"
else
    echo "⚠ Warning: Could not update WordPress URLs"
fi

##############################################################################
# 10. Restart Apache
##############################################################################

sudo systemctl restart httpd

##############################################################################
# 11. Final Verification
##############################################################################

if curl -f http://localhost/health.html > /dev/null 2>&1; then
    echo "✓ Health check: PASS"
else
    echo "✗ Health check: FAIL"
fi

if sudo systemctl is-active --quiet httpd; then
    echo "✓ Apache: Running"
else
    echo "✗ Apache: Not running"
fi

if mountpoint -q $EFS_MOUNT; then
    echo "✓ EFS: Mounted"
else
    echo "✗ EFS: Not mounted"
fi

echo "=========================================="
echo "Bootstrap Completed: $(date)"
echo "=========================================="

# Cleanup
unset DB_PASSWORD
