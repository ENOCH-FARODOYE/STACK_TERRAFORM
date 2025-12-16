#!/bin/bash -x

##############################################################################
# CliXX Bootstrap - Pulls configuration from Management Account SSM
##############################################################################

exec > >(tee /var/log/clixx-bootstrap.log)
exec 2>&1

echo "=========================================="
echo "CliXX Bootstrap Started: $(date)"
echo "=========================================="

##############################################################################
# Install Required Packages
##############################################################################

sudo dnf update -y
sudo dnf install -y aws-cli jq git httpd php php-mysqlnd php-fpm php-json mariadb105 amazon-efs-utils

##############################################################################
# Configure Apache
##############################################################################

sudo sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/httpd/conf/httpd.conf

##############################################################################
# Start Apache and Create Health Check
##############################################################################

sudo systemctl start httpd
sudo systemctl enable httpd

echo "OK" | sudo tee /var/www/html/health.html
sudo chmod 644 /var/www/html/health.html

##############################################################################
# Get AWS Region
##############################################################################

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
echo "Region: $REGION"

##############################################################################
# Assume Role and Get Credentials from Management Account SSM
##############################################################################

MGMT_ACCOUNT="978820380225"
ROLE_ARN="arn:aws:iam::$MGMT_ACCOUNT:role/ClixxSSMParameterAccessRole"

echo "Assuming role: $ROLE_ARN"

CREDENTIALS=$(aws sts assume-role \
  --role-arn $ROLE_ARN \
  --role-session-name clixx-bootstrap-$(date +%s) \
  --external-id "clixx-ssm-access" \
  --region $REGION \
  --output json)

if [ -z "$CREDENTIALS" ]; then
    echo "Failed to assume role"
    exit 1
fi

export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

echo "Role assumed successfully"

##############################################################################
# Fetch Configuration from SSM Parameter Store
##############################################################################

echo "Fetching parameters from SSM"

EFS_ID=$(aws ssm get-parameter --name "/clixx/efs/id" --region $REGION --query 'Parameter.Value' --output text)
RDS_ENDPOINT=$(aws ssm get-parameter --name "/clixx/rds/endpoint" --region $REGION --query 'Parameter.Value' --output text)
DB_NAME=$(aws ssm get-parameter --name "/clixx/rds/database" --region $REGION --query 'Parameter.Value' --output text)
DB_USER=$(aws ssm get-parameter --name "/clixx/rds/username" --region $REGION --query 'Parameter.Value' --output text)
DB_PASSWORD=$(aws ssm get-parameter --name "/clixx/rds/password" --with-decryption --region $REGION --query 'Parameter.Value' --output text)


# Unset temporary credentials
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "Configuration loaded from SSM"
echo "  EFS ID: $EFS_ID"
echo "  RDS Endpoint: $RDS_ENDPOINT"
echo "  Database: $DB_NAME"

##############################################################################
# Mount EFS
##############################################################################

EFS_MOUNT="/var/www/html"
sudo mkdir -p $EFS_MOUNT

if sudo mount -t efs -o tls $EFS_ID:/ $EFS_MOUNT; then
    echo " EFS mounted"
    echo "$EFS_ID:/ $EFS_MOUNT efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
else
    echo " EFS mount failed"
    exit 1
fi

##############################################################################
#  Deploy Application (First Instance Only)
##############################################################################

LOCK_FILE="$EFS_MOUNT/.deployment.lock"
DEPLOY_FLAG="$EFS_MOUNT/.app_deployed"

if [ ! -f "$DEPLOY_FLAG" ]; then
    # Try to acquire lock
    if mkdir "$EFS_MOUNT/.lock" 2>/dev/null; then
        echo "Lock acquired - deploying application"

        cd $EFS_MOUNT
        sudo rm -rf CliXX_Retail_Repository 2>/dev/null || true
        sudo git clone https://github.com/stackitgit/CliXX_Retail_Repository.git

        if [ -d "CliXX_Retail_Repository" ]; then
            sudo cp -r CliXX_Retail_Repository/* $EFS_MOUNT/
            sudo rm -rf CliXX_Retail_Repository

            # Fix if files are in wordpress subdirectory
            if [ -d "$EFS_MOUNT/wordpress" ]; then
                sudo cp -r $EFS_MOUNT/wordpress/* $EFS_MOUNT/
                sudo rm -rf $EFS_MOUNT/wordpress
                echo "Moved files from wordpress subdirectory"
            fi

            # Configure wp-config.php
            if [ -f "$EFS_MOUNT/wp-config.php" ]; then
                sudo sed -i "s/define( *'DB_HOST'[^;]*;/define('DB_HOST', '$RDS_ENDPOINT');/" $EFS_MOUNT/wp-config.php
                sudo sed -i "s/define( *'DB_NAME'[^;]*;/define('DB_NAME', '$DB_NAME');/" $EFS_MOUNT/wp-config.php
                sudo sed -i "s/define( *'DB_USER'[^;]*;/define('DB_USER', '$DB_USER');/" $EFS_MOUNT/wp-config.php
                sudo sed -i "s/define( *'DB_PASSWORD'[^;]*;/define('DB_PASSWORD', '$DB_PASSWORD');/" $EFS_MOUNT/wp-config.php
                echo "wp-config.php configured"
            fi

            sudo touch $DEPLOY_FLAG
            echo "Application deployed"
        fi

        # Release lock
        rmdir "$EFS_MOUNT/.lock"
    else
        echo "Another instance is deploying, waiting..."
        # Wait for deployment to complete
        for i in {1..30}; do
            if [ -f "$DEPLOY_FLAG" ]; then
                echo "Deployment completed by another instance"
                break
            fi
            sleep 2
        done
    fi
else
    echo "Application already deployed"
fi

##############################################################################
# Update wp-config.php with Current SSM Parameters
##############################################################################

if [ -f "$EFS_MOUNT/wp-config.php" ]; then
    echo "Updating wp-config.php with current SSM parameters"
    sudo sed -i "s/define( *'DB_HOST'[^;]*;/define('DB_HOST', '$RDS_ENDPOINT');/" $EFS_MOUNT/wp-config.php
    sudo sed -i "s/define( *'DB_NAME'[^;]*;/define('DB_NAME', '$DB_NAME');/" $EFS_MOUNT/wp-config.php
    sudo sed -i "s/define( *'DB_USER'[^;]*;/define('DB_USER', '$DB_USER');/" $EFS_MOUNT/wp-config.php
    sudo sed -i "s/define( *'DB_PASSWORD'[^;]*;/define('DB_PASSWORD', '$DB_PASSWORD');/" $EFS_MOUNT/wp-config.php
    echo "wp-config.php updated with SSM parameters"
fi

##############################################################################
#  Configure WordPress Permalinks
##############################################################################

sudo tee $EFS_MOUNT/.htaccess > /dev/null <<'HTACCESS'
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

sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf

##############################################################################
#  Set Permissions
##############################################################################

sudo chown -R apache:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;

##############################################################################
#  Recreate Health Check
##############################################################################

echo "OK" | sudo tee /var/www/html/health.html > /dev/null
sudo chmod 644 /var/www/html/health.html
echo "Health check file created"

##############################################################################
#  Update WordPress Site URLs
##############################################################################

RDS_HOST="${RDS_ENDPOINT%:*}"
mysql -h "$RDS_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" <<EOF
UPDATE wp_options SET option_value = 'http://dev.clixx.enoch-stack.com' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://dev.clixx.enoch-stack.com' WHERE option_name = 'home';
EOF

if [ $? -eq 0 ]; then
    echo "WordPress URLs updated"
else
    echo "Warning: Could not update WordPress URLs"
fi

##############################################################################
#  Restart Apache
##############################################################################

sudo systemctl restart httpd

##############################################################################
#  Verification
##############################################################################

if curl -f http://localhost/health.html > /dev/null 2>&1; then
    echo "Health check: PASS"
else
    echo "Health check: FAIL"
fi

if sudo systemctl is-active --quiet httpd; then
    echo "Apache: Running"
else
    echo "Apache: Not running"
fi

if mountpoint -q $EFS_MOUNT; then
    echo "EFS: Mounted"
else
    echo "EFS: Not mounted"
fi

echo "=========================================="
echo "Bootstrap Completed: $(date)"
echo "=========================================="

unset DB_PASSWORD
