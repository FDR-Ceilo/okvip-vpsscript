#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Vui lòng chạy script với quyền root."
  exit 1
fi
# Kiểm tra tham số đầu vào
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <domain_or_path>"
  exit 1
fi

DOMAIN=$1
NGINX_CONF_DIR="/etc/nginx"

if [ ! -d "$NGINX_CONF_DIR" ]; then
  echo "Error: Không tìm thấy thư mục cấu hình site của Nginx."
  exit 2
fi

echo "Tìm các redirect: $DOMAIN"

# Tìm file chứa domain
conf_file=$(find "$NGINX_CONF_DIR" -type f -name "*.conf" -print0 | xargs -0 grep -l "$DOMAIN" | head -n 1)

# Kiểm tra kết quả tìm kiếm
if [ -z "$conf_file" ]; then
  echo -e "\nError: Không tìm thấy redirect nào: $DOMAIN in $NGINX_CONF_DIR."
  exit 3
fi

# Hiển thị chi tiết cấu hình nếu tìm thấy
echo -e "\nFile: $conf_file"

# Tìm redirects
echo -e "\nRedirect rules: $DOMAIN"
grep -E "^[[:space:]]*return (301|302)" "$conf_file"

echo -e "\nHoàn tất: $DOMAIN"
