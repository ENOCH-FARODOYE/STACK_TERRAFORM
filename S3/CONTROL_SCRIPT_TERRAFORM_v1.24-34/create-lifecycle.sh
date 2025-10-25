#!/bin/bash

# Story 26: Create Lifecycle Policy

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Create S3 Lifecycle Policy${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

create_lifecycle() {
    echo -e "${YELLOW}Creating lifecycle configuration...${NC}"
    
    LIFECYCLE_CONFIG=$(cat <<'EOF'
{
  "Rules": [
    {
      "Id": "transition-to-ia",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "documents/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ]
    },
    {
      "Id": "delete-old-logs",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "logs/"
      },
      "Expiration": {
        "Days": 90
      }
    },
    {
      "Id": "cleanup-multipart",
      "Status": "Enabled",
      "Filter": {},
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
EOF
)
    
    echo "$LIFECYCLE_CONFIG" | aws s3api put-bucket-lifecycle-configuration \
        --bucket "$BUCKET_NAME" \
        --lifecycle-configuration file:///dev/stdin \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Lifecycle policy created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create lifecycle policy${NC}"
        return 1
    fi
}

display_rules() {
    echo ""
    echo -e "${BLUE}Lifecycle Rules Created:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}Rule 1: transition-to-ia${NC}"
    echo -e "  • Prefix: documents/"
    echo -e "  • Day 30: Move to STANDARD_IA"
    echo -e "  • Day 90: Move to GLACIER"
    echo ""
    echo -e "${GREEN}Rule 2: delete-old-logs${NC}"
    echo -e "  • Prefix: logs/"
    echo -e "  • Day 90: Delete objects"
    echo ""
    echo -e "${GREEN}Rule 3: cleanup-multipart${NC}"
    echo -e "  • Delete incomplete uploads after 7 days"
    echo -e "${BLUE}----------------------------------------${NC}"
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    
    create_lifecycle || exit 1
    display_rules
}

main "$@"
