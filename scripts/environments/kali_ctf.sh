#!/bin/bash

# cd into user dir
cd /home/laboratory

# Add bash startup flag
echo "echo \"Shell starts (vA5kwQxF)\"" >> .zshrc
echo "vA5kwQxF" >> /tmp/flags.txt

# Add environment flag
echo "export FLAG=Dm6ELvkr" >> .zshrc
echo "Dm6ELvkr" >> /tmp/flags.txt

# ASCII Art
base64 -d <<< "ICAgIC4tLS4gICAgICAgICAgICAgIC4tLS4KICAgOiAoXCAiLiBfLi4uLi4uXyAuIiAvKSA6CiAg
ICAnLiAgICBgICAgICAgICBgICAgIC4nCiAgICAgLycgICBfICAgICAgICBfICAgYFwKICAgIC8g
ICAgIDB9ICAgICAgezAgICAgIFwKICAgfCAgICAgICAvICAgICAgXCAgICAgICB8CiAgIHwgICAg
IC8nICAgICAgICBgXCAgICAgfAogICAgXCAgIHwgLiAgLj09LiAgLiB8ICAgLwogICAgICcuXyBc
LicgXF9fLyAnLi8gXy4nCiAgICAgLyAgYGAnLl8tJyctXy4nYGAgIFwK" > /flag.txt
echo "bear" >> /tmp/flags.txt

# Hidden file
echo "flag:egFE2W5R" >> .hidden_flag
echo "egFE2W5R" >> /tmp/flags.txt

# Flag in archived file
mkdir -p flags
echo "flag:Edm3jiDz" >> flags/flag.txt
tar -zcvf flags.tar.gz flags
rm flags/flag.txt
echo "Edm3jiDz" >> /tmp/flags.txt

# Composed flag, user must combine them with cat to find correct order
echo "bA2y" >> flags/part.txt
echo "26sg" >> flags/another_part.txt
echo "bA2y26sg" >> /tmp/flags.txt

# Flag to be truncated
echo "82iwnJaxn7LrDG5g8B6m" >> flags/truncate.txt
echo "82iwnJax" >> /tmp/flags.txt

# Flag in history
echo "echo TUj4xXYj >> /home/laboratory/.bash_history" >> .bashrc
echo "TUj4xXYj" >> /tmp/flags.txt

# Representations
cat >> flags/representation.txt <<EOF
base64:UXNoTVQ2VGgK
EOF
echo "QshMT6Th" >> /tmp/flags.txt

cat >> flags/checksums.txt <<EOF
first 8 characters of:
md5sum:cVNKVpq5
sha256sum:m8XTdKUD
sha512sum:Z39GUHBE
EOF

echo "a7a7f6b4" >> /tmp/flags.txt
echo "ba508457" >> /tmp/flags.txt
echo "1e7180ed" >> /tmp/flags.txt

# Other
# /usr/bin/msfconsole
# 0644
# shadow
cat >> flags/other.txt <<EOF
flag:path of the msfconsole tool
flag:access rights of /etc/passwd in octal notation
flag:group of /etc/shadow
EOF

echo "/usr/bin/msfconsole" >> /tmp/flags.txt
echo "0644" >> /tmp/flags.txt
echo "shadow" >> /tmp/flags.txt