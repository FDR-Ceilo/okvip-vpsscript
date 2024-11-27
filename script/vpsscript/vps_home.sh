#!/bin/bash

# Kiểm tra quyền root
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Vui lòng chạy script này với quyền root."
  exit 1
fi

logfile="/var/log/vps_status_detailed.log"

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$logfile"
}

log_message "---------------------------------"
log_message "VPS Detailed Status Summary"
log_message "---------------------------------"

# Load Average
load_avg=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
log_message "Load Average: $load_avg"

# CPU Usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8 "%"}')
log_message "CPU Usage: $cpu_usage"

# RAM Usage
total_ram=$(free -m | awk '/^Mem/ {print $2}')
used_ram=$(free -m | awk '/^Mem/ {print $3}')
ram_percent=$(awk "BEGIN {printf \"%.2f\", ($used_ram/$total_ram)*100}")
log_message "RAM Usage: $used_ram MB / $total_ram MB ($ram_percent%)"

# Disk Usage (Root Partition)
disk_usage=$(df -h / | grep '/' | awk '{print $5}' | sed 's/%//g')
log_message "Disk Usage (Root Partition): $disk_usage%"

# Website Information
log_message "Websites Hosted:"
website_dir="/var/www/html"
if [ -d "$website_dir" ]; then
  websites=$(ls -l "$website_dir" | grep '^d' | awk '{print $NF}')
  website_count=$(echo "$websites" | wc -l)
  log_message "Number of Websites: $website_count"
  log_message "Website List:"
  echo "$websites" | while read site; do
    log_message " - $site"
  done
else
  log_message "No websites found in $website_dir"
fi

# FTP Account Information (Pure-FTPd)
log_message "FTP Account Information:"
ftp_list=$(pure-pw list 2>/dev/null)
if [ $? -eq 0 ]; then
  ftp_active=$(echo "$ftp_list" | wc -l)
  ftp_inactive=$(echo "$ftp_list" | grep -i 'disabled' | wc -l)
  log_message "Number of FTP Accounts: $ftp_active active, $ftp_inactive inactive"
  log_message "FTP Accounts List:"
  echo "$ftp_list" | while read account; do
    log_message " - $account"
  done
else
  log_message "Error: Unable to retrieve FTP account list. Pure-FTPd may not be installed or configured."
fi

# Lấy mật khẩu MySQL từ wp-config.php hoặc config.php
db_password=""
wp_config="/var/www/html/wp-config.php"  # Đường dẫn tới wp-config.php của WordPress
config_file="/var/www/html/config.php"  # Đường dẫn tới config.php của bạn

# Kiểm tra wp-config.php
if [ -f "$wp_config" ]; then
  db_password_wp=$(grep -oP "['\"]DB_PASSWORD['\"]\s*=>\s*['\"]\K[^'\"]+" "$wp_config")
  if [ -n "$db_password_wp" ]; then
    db_password="$db_password_wp"
    log_message "MySQL Password Found in wp-config.php."
  fi
fi

# Nếu không tìm thấy trong wp-config.php, thử tìm trong config.php
if [ -z "$db_password" ] && [ -f "$config_file" ]; then
  db_password_config=$(grep -oP "['\"]DB_PASSWORD['\"]\s*=>\s*['\"]\K[^'\"]+" "$config_file")
  if [ -n "$db_password_config" ]; then
    db_password="$db_password_config"
    log_message "MySQL Password Found in config.php."
  fi
fi

# Nếu không tìm thấy mật khẩu trong cả hai file
if [ -z "$db_password" ]; then
  log_message "Error: MySQL password not found in wp-config.php or config.php."
else
  log_message "Using MySQL password: $db_password"
fi

# Database Information (MySQL/MariaDB) - Sử dụng mật khẩu MySQL từ file cấu hình
log_message "Database Information:"
if [ -n "$db_password" ]; then
  db_list=$(mysql -u root -p"$db_password" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")
  if [ $? -eq 0 ]; then
    db_count=$(echo "$db_list" | wc -l)
    log_message "Number of Databases: $db_count"
    log_message "Database List:"
    echo "$db_list" | while read db; do
      log_message " - $db"
    done
  else
    log_message "Error: Unable to retrieve database list. Check MySQL credentials."
  fi
else
  log_message "Error: MySQL password is not available. Skipping database retrieval."
fi

# Firewall Status
ufw_status=$(ufw status | grep "Status" | awk '{print $2}')
log_message "Firewall Status: $ufw_status"

log_message "---------------------------------"
log_message "VPS Detailed Status Check Completed."
