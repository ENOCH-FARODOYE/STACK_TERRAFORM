```bash
#!/bin/bash

# Story 35: Test Transfer Acceleration

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Transfer Acceleration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

create_test_file() {
    echo -e "${BLUE}Step 1: Creating test file (10MB)...${NC}"
    
    dd if=/dev/urandom of=test-acceleration.dat bs=1M count=10 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test file created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create test file${NC}"
        return 1
    fi
}

upload_standard() {
    echo ""
    echo -e "${BLUE}Step 2: Uploading via standard endpoint...${NC}"
    
    START=$(date +%s)
    aws s3 cp test-acceleration.dat "s3://$BUCKET_NAME/test-standard.dat" --region "$AWS_REGION" > /dev/null 2>&1
    END=$(date +%s)
    STANDARD_TIME=$((END - START))
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Standard upload completed in ${STANDARD_TIME}s${NC}"
        return 0
    else
        echo -e "${RED}✗ Standard upload failed${NC}"
        return 1
    fi
}

upload_accelerated() {
    echo ""
    echo -e "${BLUE}Step 3: Uploading via accelerated endpoint...${NC}"
    
    START=$(date +%s)
    aws s3 cp test-acceleration.dat "s3://$BUCKET_NAME/test-accelerated.dat" \
        --endpoint-url https://s3-accelerate.amazonaws.com > /dev/null 2>&1
    END=$(date +%s)
    ACCELERATED_TIME=$((END - START))
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Accelerated upload completed in ${ACCELERATED_TIME}s${NC}"
        return 0
    else
        echo -e "${RED}✗ Accelerated upload failed${NC}"
        return 1
    fi
}

compare_results() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Results Comparison${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Standard Endpoint: ${STANDARD_TIME}s${NC}"
    echo -e "${GREEN}Accelerated Endpoint: ${ACCELERATED_TIME}s${NC}"
    
    if [ $ACCELERATED_TIME -lt $STANDARD_TIME ]; then
        IMPROVEMENT=$((STANDARD_TIME - ACCELERATED_TIME))
        PERCENT=$((IMPROVEMENT * 100 / STANDARD_TIME))
        echo -e "${GREEN}✓ Acceleration improved speed by ${IMPROVEMENT}s (${PERCENT}%)${NC}"
    else
        echo -e "${YELLOW}⚠ No improvement (may be close to region)${NC}"
    fi
    echo -e "${BLUE}========================================${NC}"
}

cleanup() {
    echo ""
    echo -e "${BLUE}Cleanup: Removing test files...${NC}"
    rm -f test-acceleration.dat
    aws s3 rm "s3://$BUCKET_NAME/test-standard.dat" --region "$AWS_REGION" > /dev/null 2>&1
    aws s3 rm "s3://$BUCKET_NAME/test-accelerated.dat" \
        --endpoint-url https://s3-accelerate.amazonaws.com > /dev/null 2>&1
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    
    create_test_file || exit 1
    upload_standard || exit 1
    upload_accelerated || exit 1
    compare_results
    cleanup
}

main "$@"
```
