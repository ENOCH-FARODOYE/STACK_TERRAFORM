#!/bin/bash -xe

##############################################################################
# Enoch Blog - Bootstrap Script (Terraform Version)
##############################################################################

exec > >(tee /var/log/enoch-blog-bootstrap.log)
exec 2>&1

echo "Enoch Blog Bootstrap Started: $(date)"

##############################################################################
# Install Required Packages
##############################################################################

sudo dnf update -y
sudo dnf install -y aws-cli jq git httpd php php-mysqlnd php-fpm php-json mariadb105 amazon-efs-utils ec2-instance-connect

##############################################################################
#  Start Apache and Create Health Check
##############################################################################

sudo systemctl start httpd
sudo systemctl enable httpd

echo "OK" | sudo tee /var/www/html/health.html
sudo chmod 644 /var/www/html/health.html

##############################################################################
#  Get AWS Region
##############################################################################

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
echo "Region: $REGION"

##############################################################################
#  Fetch Configuration from Management Account SSM
##############################################################################

MGMT_ACCOUNT="978820380225"
ROLE_ARN="arn:aws:iam::$${MGMT_ACCOUNT}:role/SSMParameterAccessRole"

echo "Assuming role: $ROLE_ARN"

CREDENTIALS=$(aws sts assume-role \
    --role-arn $ROLE_ARN \
    --role-session-name "enoch-blog-bootstrap-$(date +%s)" \
    --region $REGION \
    --output json)

if [ $? -ne 0 ]; then
    echo " Failed to assume role in Management Account"
    exit 1
fi

export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

echo " Successfully assumed role"

echo "Fetching individual parameters"

EFS_ID=$(aws ssm get-parameter --name "/enoch-blog/efs-id" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
RDS_ENDPOINT="${RDS_ENDPOINT}"
DB_NAME=$(aws ssm get-parameter --name "/enoch-blog/db-name" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
DB_USER=$(aws ssm get-parameter --name "/enoch-blog/db-username" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
DB_PASSWORD=$(aws ssm get-parameter --name "/enoch-blog/db-password" --with-decryption --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
ALB_DNS=$(aws ssm get-parameter --name "/enoch-blog/alb-dns" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)

if [ -z "$EFS_ID" ] || [ -z "$RDS_ENDPOINT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "✗ Failed to retrieve one or more SSM parameters"
    exit 1
fi

echo " SSM parameters retrieved"
echo "  EFS ID: $EFS_ID"
echo "  RDS Endpoint: $RDS_ENDPOINT"
echo "  Database: $DB_NAME"
echo "  ALB DNS: $ALB_DNS"

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

##############################################################################
#  Mount EFS
##############################################################################

EFS_MOUNT="/var/www/html/efs-data"
sudo mkdir -p $EFS_MOUNT

if sudo mount -t efs -o tls $EFS_ID:/ $EFS_MOUNT; then
    echo " EFS mounted"
    echo "$EFS_ID:/ $EFS_MOUNT efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
else
    echo " EFS mount failed"
fi

##############################################################################
#  Deploy Application
##############################################################################

if [ -f "$EFS_MOUNT/.app_deployed" ]; then
    echo "Copying from EFS..."
    sudo cp -r $EFS_MOUNT/* /var/www/html/
else
    echo "First deployment - cloning from GitHub"
    cd $EFS_MOUNT
    sudo git clone https://github.com/ENOCH-FARODOYE/ENOCH-BLOG.git
    sudo cp -r ENOCH-BLOG/* $EFS_MOUNT/
    sudo rm -rf ENOCH-BLOG
    
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_HOST'[^;]*;/define('DB_HOST', '$RDS_ENDPOINT');/" {} \;
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_NAME'[^;]*;/define('DB_NAME', '$DB_NAME');/" {} \;
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_USER'[^;]*;/define('DB_USER', '$DB_USER');/" {} \;
    sudo find $EFS_MOUNT -name "wp-config.php" -exec sed -i "s/define( *'DB_PASSWORD'[^;]*;/define('DB_PASSWORD', '$DB_PASSWORD');/" {} \;
    
    sudo touch $EFS_MOUNT/.app_deployed
    sudo cp -r $EFS_MOUNT/* /var/www/html/
fi

##############################################################################
#  Update wp-config.php with Current Database Settings
##############################################################################

echo "Updating wp-config.php with current database settings..."
sudo sed -i "s/define( *'DB_HOST'[^;]*;/define('DB_HOST', '$RDS_ENDPOINT');/" /var/www/html/wp-config.php
sudo sed -i "s/define( *'DB_NAME'[^;]*;/define('DB_NAME', '$DB_NAME');/" /var/www/html/wp-config.php
sudo sed -i "s/define( *'DB_USER'[^;]*;/define('DB_USER', '$DB_USER');/" /var/www/html/wp-config.php
sudo sed -i "s/define( *'DB_PASSWORD'[^;]*;/define('DB_PASSWORD', '$DB_PASSWORD');/" /var/www/html/wp-config.php
echo "✓ wp-config.php updated"

##############################################################################
#  Configure WordPress Permalinks
##############################################################################

sudo tee /var/www/html/.htaccess > /dev/null <<'HTACCESS'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %%{REQUEST_FILENAME} !-f
RewriteCond %%{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
HTACCESS

sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf

sudo chown -R apache:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;

##############################################################################
#  Restart Apache
##############################################################################

echo "Restarting Apache"
sudo systemctl restart httpd

##############################################################################
#  Verification
##############################################################################

if curl -f http://localhost/health.html > /dev/null 2>&1; then
    echo " Health check: PASS"
else
    echo " Health check: FAIL"
fi

if sudo systemctl is-active --quiet httpd; then
    echo " Apache: Running"
else
    echo " Apache: Not running"
fi

if mountpoint -q $EFS_MOUNT; then
    echo " EFS: Mounted"
else
    echo " EFS: Not mounted"
fi

echo "=========================================="
echo "Bootstrap Completed: $(date)"
echo "=========================================="

unset DB_PASSWORD
