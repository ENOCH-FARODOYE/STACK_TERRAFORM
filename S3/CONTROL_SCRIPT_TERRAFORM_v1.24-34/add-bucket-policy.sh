
```bash
#!/bin/bash

# Story 34: Add Bucket Policy

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Add S3 Bucket Policy${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

add_policy() {
    echo -e "${YELLOW}Adding bucket policy (Enforce HTTPS)...${NC}"
    
    POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSSLRequestsOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF
)
    
    echo "$POLICY" | aws s3api put-bucket-policy \
        --bucket "$BUCKET_NAME" \
        --policy file:///dev/stdin \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Bucket policy added${NC}"
        echo ""
        echo -e "${GREEN}Policy enforces HTTPS-only access${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to add policy${NC}"
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
    add_policy
}

main "$@"
```

