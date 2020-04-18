if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo "Installing pacman-contrib if not installed"
pacman -S --needed --noconfirm pacman-contrib

echo ""
read -p "Would you like to create a backup of the current mirrorlist? [y/n] " backup
if [ backup == "y" ]; then
 file=mirrorlist.$(date +"%Y-%m-%d-%T").backup
 echo "Backing up mirrorlist to /etc/pacman.d/$file"
 mv /etc/pacman.d/mirrorlist /etc/pacman.d/$file
else
 echo "No backup created"
fi
echo ""

read -p "Country (two letter string): " country
read -p "How much Servers: " amount

$(curl -s "https://www.archlinux.org/mirrorlist/?country=${country^^}&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n $amount - > /etc/pacman.d/mirrorlist)& PID=$!

i=1
sp="/-\|"
echo -n 'Loading mirrors. Please wait  '
while [ -d /proc/$PID ]
do
  printf "\b${sp:i++%${#sp}:1}"
done

echo "  Finished!"

echo -n "Updating pacman mirrors"
pacman -Sy
