#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

BUCKET_NAME="$1"
S3_PREFIX="$2"
AWS_REGION="us-east-1"
DRY_RUN=${3:-true}
LOG_FILE="logs/deleted_objects.log"

mkdir -p logs

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Bulk Object Deletion v1.13${NC}"
    echo -e "${BLUE}========================================${NC}"
}

list_objects() {
    aws s3 ls "s3://$BUCKET_NAME/$S3_PREFIX" --recursive --region "$AWS_REGION" | awk '{print $4}'
}

confirm_delete() {
    echo -e "${YELLOW}Objects to delete under s3://$BUCKET_NAME/$S3_PREFIX:${NC}"
    list_objects
    read -p "Are you sure you want to delete all these objects? [y/N]: " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo -e "${RED}Bulk deletion canceled${NC}"; exit 0; }
}

delete_bulk() {
    OBJECTS=$(list_objects)
    COUNT=0
    for obj in $OBJECTS; do
        if [ "$DRY_RUN" == true ]; then
            echo -e "${YELLOW}[Dry-Run] Would delete: $obj${NC}"
        else
            aws s3 rm "s3://$BUCKET_NAME/$obj" --region "$AWS_REGION" && echo "$obj deleted on $(date)" >> "$LOG_FILE"
            COUNT=$((COUNT+1))
        fi
    done
    [ "$DRY_RUN" == false ] && echo -e "${GREEN}✓ Total deleted objects: $COUNT${NC}"
}

main() {
    [ $# -lt 2 ] && { echo -e "${RED}Usage: $0 <bucket-name> <s3-prefix> [dry-run=true/false]${NC}"; exit 1; }
    print_header
    confirm_delete
    delete_bulk
}

main "$@"

