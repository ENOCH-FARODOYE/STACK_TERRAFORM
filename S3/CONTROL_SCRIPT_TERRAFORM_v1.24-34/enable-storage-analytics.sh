#!/bin/bash

# Story 29: Enable Storage Class Analysis

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Enable Storage Class Analysis${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

enable_analytics() {
    echo -e "${YELLOW}Enabling storage class analysis...${NC}"
    
    ANALYTICS_CONFIG=$(cat <<EOF
{
  "Id": "EntireBucketAnalysis",
  "StorageClassAnalysis": {
    "DataExport": {
      "OutputSchemaVersion": "V_1",
      "Destination": {
        "S3BucketDestination": {
          "Format": "CSV",
          "BucketArn": "arn:aws:s3:::$BUCKET_NAME",
          "Prefix": "analytics/"
        }
      }
    }
  }
}
EOF
)
    
    echo "$ANALYTICS_CONFIG" | aws s3api put-bucket-analytics-configuration \
        --bucket "$BUCKET_NAME" \
        --id "EntireBucketAnalysis" \
        --analytics-configuration file:///dev/stdin \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Storage analytics enabled${NC}"
        echo ""
        echo -e "${GREEN}Analytics reports will be in: s3://$BUCKET_NAME/analytics/${NC}"
        echo -e "${YELLOW}Note: First report available in 24-48 hours${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to enable analytics${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    enable_analytics
}

main "$@"
