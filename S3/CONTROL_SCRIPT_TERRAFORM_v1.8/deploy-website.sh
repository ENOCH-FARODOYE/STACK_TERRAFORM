

#!/bin/bash

#######################################
# Script: deploy-website.sh
# Purpose: Deploy website files to S3 bucket
# Story: CONTROL_SCRIPT_TERRAFORM_v1.8
#######################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUCKET_NAME=""
AWS_REGION="us-east-1"
WEBSITE_DIR="website"

#######################################
# Function: print_header
# Description: Print formatted header
#######################################
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Static Website Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

#######################################
# Function: validate_bucket_exists
# Description: Check if bucket exists
#######################################
validate_bucket_exists() {
    echo -e "${YELLOW}Validating bucket existence...${NC}"

    if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
        echo -e "${GREEN}✓ Bucket '$BUCKET_NAME' exists${NC}"
        return 0
    else
        echo -e "${RED}✗ Bucket '$BUCKET_NAME' not found${NC}"
        return 1
    fi
}

#######################################
# Function: validate_website_files
# Description: Check if website files exist
#######################################
validate_website_files() {
    echo -e "${YELLOW}Validating website files...${NC}"

    if [ ! -d "$WEBSITE_DIR" ]; then
        echo -e "${RED}✗ Website directory '$WEBSITE_DIR' not found${NC}"
        return 1
    fi

    if [ ! -f "$WEBSITE_DIR/index.html" ]; then
        echo -e "${RED}✗ index.html not found in $WEBSITE_DIR${NC}"
        return 1
    fi

    if [ ! -f "$WEBSITE_DIR/error.html" ]; then
        echo -e "${YELLOW}⚠ error.html not found (optional but recommended)${NC}"
    fi

    echo -e "${GREEN}✓ Website files validated${NC}"
    return 0
}

#######################################
# Function: upload_website_files
# Description: Upload files to S3 bucket
#######################################
upload_website_files() {
    echo -e "${YELLOW}Uploading website files to S3...${NC}"

    # Sync website directory to S3
    aws s3 sync "$WEBSITE_DIR/" "s3://$BUCKET_NAME/" \
        --region "$AWS_REGION" \
        --delete \
        --exclude ".DS_Store" \
        --exclude "*.md"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Website files uploaded successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Error uploading files${NC}"
        return 1
    fi
}

#######################################
# Function: set_content_types
# Description: Set proper content types for files
#######################################
set_content_types() {
    echo -e "${YELLOW}Setting content types...${NC}"

    # Set content type for HTML files
    aws s3 cp "s3://$BUCKET_NAME/" "s3://$BUCKET_NAME/" \
        --exclude "*" \
        --include "*.html" \
        --content-type "text/html" \
        --metadata-directive REPLACE \
        --recursive \
        --region "$AWS_REGION" \
        --quiet

    # Set content type for CSS files
    aws s3 cp "s3://$BUCKET_NAME/" "s3://$BUCKET_NAME/" \
        --exclude "*" \
        --include "*.css" \
        --content-type "text/css" \
        --metadata-directive REPLACE \
        --recursive \
        --region "$AWS_REGION" \
        --quiet

    echo -e "${GREEN}✓ Content types set${NC}"
}

#######################################
# Function: get_website_url
# Description: Get and display website URL
#######################################
get_website_url() {
    echo ""
    echo -e "${BLUE}Website Information:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    # Get website configuration
    WEBSITE_CONFIG=$(aws s3api get-bucket-website --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        WEBSITE_ENDPOINT="${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"
        WEBSITE_URL="http://${WEBSITE_ENDPOINT}"

        echo -e "${GREEN}  Website Endpoint: $WEBSITE_ENDPOINT${NC}"
        echo -e "${GREEN}  Website URL: $WEBSITE_URL${NC}"
        echo -e "${BLUE}----------------------------------------${NC}"
        echo ""
        echo -e "${YELLOW}🌐 Visit your website at:${NC}"
        echo -e "${GREEN}   $WEBSITE_URL${NC}"
    else
        echo -e "${RED}✗ Website hosting not configured${NC}"
    fi
}

#######################################
# Function: list_uploaded_files
# Description: List all uploaded files
#######################################
list_uploaded_files() {
    echo ""
    echo -e "${BLUE}Uploaded Files:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    aws s3 ls "s3://$BUCKET_NAME/" --region "$AWS_REGION" --recursive --human-readable

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: main
# Description: Main execution function
#######################################
main() {
    print_header

    # Check if bucket name is provided
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 website-storage-enoch-v18${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"

    # Validate bucket exists
    validate_bucket_exists || exit 1

    echo ""

    # Validate website files
    validate_website_files || exit 1

    echo ""

    # Upload files
    upload_website_files || exit 1

    echo ""

    # Set content types
    set_content_types

    # Get website URL
    get_website_url

    # List uploaded files
    list_uploaded_files

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Website deployment completed!${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Execute main function
main "$@"
