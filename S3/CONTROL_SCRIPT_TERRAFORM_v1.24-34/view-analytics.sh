```bash
#!/bin/bash

# Story 29: View Storage Analytics Configuration

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  View Storage Analytics Config${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

view_analytics() {
    echo -e "${YELLOW}Retrieving analytics configuration...${NC}"
    echo ""
    
    ANALYTICS=$(aws s3api list-bucket-analytics-configurations \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Analytics Configurations:${NC}"
        echo "$ANALYTICS" | jq .
        return 0
    else
        echo -e "${YELLOW}⚠ No analytics configurations found${NC}"
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
    view_analytics
}

main "$@"
```
