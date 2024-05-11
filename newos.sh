#/bin/bash

# Upgrades/updates
apt update
apt upgrade -y
apt autoremove -y

# Drive setup
mkdir /mnt/steamgames
mount /dev/nvme0n1p1 /mnt/steamgames
echo "

#steam library drive
UUID=87f62db8-a45d-4955-ad93-e15c70f4ec22   /mnt/steamgames   ext4    rw,users,exec,auto   0 0" >> /etc/fstab

# Gaming fixes
touch /etc/libinput/local-overrides.quirks
echo "[asdfsajngiughiughbda]
MatchName=*
ModelBouncingKeys=1
" > /etc/libinput/local-overrides.quirks

ln -s "/mnt/steamgames/.minecraft" ".minecraft"

# Packages
apt install neofetch
apt install kdenlive
apt install obs-studio
apt install steam
apt install snap
apt install audacity

# Spotify and SpotX
snap install spotify
bash <(curl -sSL https://raw.githubusercontent.com/SpotX-CLI/SpotX-Linux/main/install.sh) -ce

# Discord and Vencord
wget https://discord.com/api/download?platform=linux&format=deb
dpkg -i ~/Downloads/discord-0.0.51.deb
sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"
