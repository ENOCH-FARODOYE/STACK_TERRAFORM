```bash
#!/bin/bash

# Story 34: View Bucket Policy

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  View Bucket Policy${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

view_policy() {
    echo -e "${YELLOW}Retrieving bucket policy...${NC}"
    echo ""
    
    POLICY=$(aws s3api get-bucket-policy \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --query 'Policy' \
        --output text 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Bucket Policy:${NC}"
        echo "$POLICY" | jq .
        return 0
    else
        if echo "$POLICY" | grep -q "NoSuchBucketPolicy"; then
            echo -e "${YELLOW}⚠ No bucket policy configured${NC}"
        else
            echo -e "${RED}✗ Error retrieving policy${NC}"
        fi
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
    view_policy
}

main "$@"
```
