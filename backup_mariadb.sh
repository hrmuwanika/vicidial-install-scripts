#!/bin/bash

# Define the directory where backup files will be stored
BACKUP_DIR="/var/backups/mysql"

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Define the filename for the backup file (include date in the filename)
BACKUP_FILE="$BACKUP_DIR/mysql_backup_$(date +%Y-%m-%d_%H-%M-%S).sql"

# Define the compressed filename
COMPRESSED_FILE="$BACKUP_FILE.gz"

# Define MySQL username and password (replace with your MySQL credentials)
DB_USER="USERNAME"
DB_PASS="PASSWORD"

# Dump all databases into a single SQL file
mysqldump -u "$DB_USER" -p"$DB_PASS" --all-databases > "$BACKUP_FILE"

# Add permissions to the backup file
chmod 600 "$BACKUP_FILE"

# Compress the backup file
gzip "$BACKUP_FILE"
echo "Database backup completed. Backup stored in: $COMPRESSED_FILE"
