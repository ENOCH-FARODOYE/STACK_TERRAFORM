#!/bin/bash

# Verify Same-Region Cross-Account Replication Configuration

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_BUCKET=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Verify Same-Region Cross-Account CRR${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

verify_replication() {
    echo -e "${YELLOW}Checking same-region cross-account replication configuration...${NC}"
    echo ""
    
    REPLICATION=$(aws s3api get-bucket-replication \
        --bucket "$SOURCE_BUCKET" \
        --region "$AWS_REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Replication is configured${NC}"
        echo ""
        
        if command -v jq &> /dev/null; then
            echo "$REPLICATION" | jq .
            echo ""
            
            ROLE=$(echo "$REPLICATION" | jq -r '.ReplicationConfiguration.Role')
            DEST_BUCKET=$(echo "$REPLICATION" | jq -r '.ReplicationConfiguration.Rules[].Destination.Bucket')
            DEST_ACCOUNT=$(echo "$REPLICATION" | jq -r '.ReplicationConfiguration.Rules[].Destination.Account')
            STATUS=$(echo "$REPLICATION" | jq -r '.ReplicationConfiguration.Rules[].Status')
            PRIORITY=$(echo "$REPLICATION" | jq -r '.ReplicationConfiguration.Rules[].Priority')
            
            echo -e "${GREEN}Configuration Summary:${NC}"
            echo -e "  Role: $ROLE"
            echo -e "  Destination Bucket: $DEST_BUCKET"
            echo -e "  Destination Account: $DEST_ACCOUNT"
            echo -e "  Status: $STATUS"
            echo -e "  Priority: $PRIORITY"
        else
            echo "$REPLICATION"
            echo ""
            echo -e "${YELLOW}Tip: Install 'jq' for better formatting${NC}"
        fi
        
        return 0
    else
        if echo "$REPLICATION" | grep -q "NoSuchReplicationConfiguration"; then
            echo -e "${RED}✗ No replication configuration found${NC}"
            echo -e "${YELLOW}Run setup script to configure replication${NC}"
        else
            echo -e "${RED}✗ Error checking replication configuration${NC}"
            echo "$REPLICATION"
        fi
        return 1
    fi
}

check_versioning() {
    echo ""
    echo -e "${YELLOW}Checking bucket versioning...${NC}"
    
    VERSIONING=$(aws s3api get-bucket-versioning \
        --bucket "$SOURCE_BUCKET" \
        --region "$AWS_REGION" \
        --query 'Status' \
        --output text)
    
    if [ "$VERSIONING" == "Enabled" ]; then
        echo -e "${GREEN}✓ Versioning is enabled${NC}"
    else
        echo -e "${RED}✗ Versioning is NOT enabled (required for replication)${NC}"
    fi
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Source bucket name required${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo -e "  $0 <source-bucket>"
        echo ""
        echo -e "${YELLOW}Example:${NC}"
        echo -e "  $0 advanced-bucket-enoch-v125"
        exit 1
    fi
    
    SOURCE_BUCKET="$1"
    
    verify_replication
    check_versioning
    
    echo ""
    echo -e "${GREEN}Verification complete!${NC}"
}

main "$@"

