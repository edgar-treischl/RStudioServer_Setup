
#I tried:
#scp -r /Users/edgar/Documents/GitHub/AmtSchulDocs/_site treischl@10.155.36.195:/var/www/html/amtschuldocs/

#I did
#sudo chown -R www-data:www-data /var/www/html/amtschuldocs

#I did not
#sudo chown -R your_user:your_user /var/www/html/amtschuldocs
#sudo chmod -R 755 /var/www/html/amtschuldocs

#!/bin/bash

#And I removed the directory
#sudo rm -rf /var/www/html/amtschuldocs



# Set the target directory path
TARGET_DIR="/var/www/html/amtschuldocs"

# 1. Ensure the directory exists and is owned by root
# If the directory doesn't exist, create it and set the correct ownership (root)
if [ ! -d "$TARGET_DIR" ]; then
    echo "Directory does not exist. Creating directory $TARGET_DIR."
    sudo mkdir -p "$TARGET_DIR"
    sudo chown root:root "$TARGET_DIR"   # Set root as the owner and group
    sudo chmod 755 "$TARGET_DIR"         # Set permissions (rwx for owner, rx for others)
else
    echo "Directory already exists."
fi

# 2. Add the user `treischl` to the group `www-data` (which Apache uses)
echo "Adding user 'treischl' to the group 'www-data'."
sudo usermod -a -G www-data treischl

# 3. Set correct permissions:
# - Directory permissions: `755` (rwx for owner, rx for group and others)
# - File permissions: `644` (rw for owner, r for group and others)

# Set directory permissions to `755`
echo "Setting directory permissions to 755 for $TARGET_DIR"
sudo find "$TARGET_DIR" -type d -exec sudo chmod 755 {} \;

# Set file permissions to `644`
echo "Setting file permissions to 644 for files inside $TARGET_DIR"
sudo find "$TARGET_DIR" -type f -exec sudo chmod 644 {} \;

# 4. Confirm the final permissions and ownership
echo "Final directory structure and permissions:"
ls -ld "$TARGET_DIR"
ls -l "$TARGET_DIR"

