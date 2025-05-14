#!/bin/bash
# sudo chmod +x backup_cron.sh

# Define the path to the backup script
BACKUP_SCRIPT="/backup_mysql.sh"

# Define the cron job command to run the backup script once a week (every Sunday at midnight)
CRON_COMMAND="0 0 * * 0 $BACKUP_SCRIPT"

# Add the cron job to the crontab
(crontab -l 2>/dev/null; echo "$CRON_COMMAND") | crontab -

echo "Backup cron job set up successfully."
