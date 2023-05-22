function cleanup {
    rm "$HOME/en-tool.sh"
    rm "/root/en-tool.sh"
    unset variables
}
trap cleanup exit


clear && echo && echo && echo " _____            _                _   ___   ____  __ " \
    && echo -e "| ____|_  ___ __ | | ___  _ __ ___| \ | \ \ / /  \/  |" && echo -e "|  _| \ \/ / '_ \| |/ _ \| '__/ _ \  \| |\ V /| |\/| |" \
    && echo -e "| |___ >  <| |_) | | (_) | | |  __/ |\  | | | | |  | |" && echo -e "|_____/_/\_\ .__/|_|\___/|_|  \___|_| \_| |_| |_|  |_|" \
    && echo -e "           |_| \033[4mhttps://explorenym.net/official-links\033[0m" && echo

    echo -e '\033[1mBash tool initialized please be patient checking and updating server.\033[22m' && echo

# Ipv6 check
if ip -6 addr show | grep -q "inet6"; then
    echo -e "\xE2\x9C\x93 IPv6 enabled"
else
    echo -e "\xE2\x9C\x97 No IPv6 address found!"
    echo
    echo '! Force Exit !'
    exit 0
fi


# Ubuntu check
if ! [ "$(lsb_release -rs)" == "20.04" ]; then
    echo -e "\xE2\x9C\x97 Ubuntu $(lsb_release -rs)."
    echo
    echo "! Warning script and nym binaries are tested on Ubuntu 20.04 !"
    echo
    read -p "Run script anyway (Y/n) " perm
    if ! [[ "$perm" == "Y" || "$perm" == "y" || "$perm" == "" ]]; then
    echo
    echo '! Force Exit !'
    exit 0
    fi
else
  echo -e "\xE2\x9C\x93 Ubuntu 20.04 "
  echo
fi



# Set ip info
bind_ip=$(hostname -I | awk '{print $1}')
announce_ip=$(curl -s ifconfig.me)


# Check user
case "$(groups)" in
  *sudo*)
    sudo rm -f /root/en-tool.sh > /dev/null 2>&1
    echo
    echo -e "\xE2\x9C\x93 $USER has Sudo privileges."
    echo
    ;;
  *root*)
    echo -e "\xE2\x9C\x97 Root user."
    echo
    echo '! Warning you should create a sudo user for running nym !'
    echo
    read -p "Make a new sudo user (Y/n) " perm
    if [[ "$perm" == "Y" || "$perm" == "y" || "$perm" == "" ]]; then
    
    while [[ -z "$new_user" ]]; do
    read -p "Enter new username: " new_user
    done
    sudo adduser --gecos GECOS  $new_user
    usermod -aG sudo $new_user
    echo
    echo "!Reconnecting as new user please re run script after connecting!"
    echo
    ssh "$new_user@$announce_ip"
    exit

    fi
    ;;
  *)
    echo -e "\xE2\x9C\x97 $USER has no priveleges"
    echo
    echo '! Force Exit !'
    exit 0
    ;;
esac


# Update server
echo 'Updating server please be patient...'
    sudo apt update -qq > '/dev/null' 2>&1
    sudo apt upgrade -y -qq > '/dev/null' 2>&1
    echo
    echo -e "\xE2\x9C\x93 Server up to date."
    echo

# Latest release
nym_release=$(curl -s "https://github.com/nymtech/nym/releases/" | grep -oEm 1 "nym-binaries-v[0-9]+\.[0-9]+\.[0-9]+")
nym_release_url="https://github.com/nymtech/nym/releases/download/$nym_release"


# Check for .nym folder
nym_path=$(find / -type d -name ".nym" 2>/dev/null)

echo $nym_path

if [ -n "$nym_path" ]; then
    echo -e "\xE2\x9C\x93 NYM folder found."


# Find config file
node_path="$nym_path/$nym_contents"

    nym_node_id=$(find "$node_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | head -n1)

    nym_config_file=$node_path/$nym_node_id/config/config.toml

    if ! [ -f "$nym_config_file" ]; then
    echo "Cant find config.toml"
    exit 1
    fi


# variables from config
nym_wallet_address=$(grep "wallet_address" "$config_file" | awk -F "'" '{print $2}')
    nym_version=$(grep "version" "$config_file" | awk -F "'" '{print $2}')

# say current version

echo "nym-mixnode current version $nym_version"


# Menu for update or back-up
while true; do
    echo
    echo -e "\033[1m nym-mixnode menu:\033[22m" && echo
    echo "1. Update nym-mixnode"
    echo "2. Backup nym-mixnode"
    echo "3. Quit"
    read -p "Enter your choice: " old_nym_menu_choice

    case $old_nym_menu_choice in
        1)
            # UPDATE NODE


            # Download latest binary
            wget -q -O $nym_binary_name "$nym_release_url/$nym_binary_name"
            chmod u+x $nym_binary_name
            sudo mv $nym_binary_name /usr/local/bin/


            # Init new binary
            nym-mixnode init --id $nym_node_id --host $bind_ip --announce-host $announce_ip --wallet-address $wallet_address
            sudo systemctl restart nym-mixnode
            
            sleep 2

            if [[ `service nym-mixnode status | grep active` =~ "running" ]]; then
                nym_version=$(grep "version" "$config_file" | awk -F "'" '{print $2}')
                echo
                sudo systemctl status nym-mixnode --no-pager
                echo
                echo -e "nym-mixnode updated to version: $nym_version, remember update the version in your wallet!"
                echo
                echo -e "Server Restart Initiated"
                sudo reboot
            else
            echo -e "nym-mixnode was not updated correctly, please re-update."
            fi

            exit
            ;;
        2)
            # BACKUP SECTION
            echo "Now copy this script and paste it in your local terminal to pull a backup of your mixnode."
            echo 
            echo "scp -r $USER@$announce_ip:$node_path/$nym_node_id/ ~/$folder_name"
            echo 
            exit
            ;;
        3)
            exit
            ;;
        *)
            echo
            echo -e "\xE2\x9C\x97 Invalid option, please try again."
            ;;
    esac
done

#updated ended


else


# Install / migrate menu

while true; do
    echo
    echo -e "\033[1m nym-mixnode menu:\033[22m" && echo
    echo "1. Install nym-mixnode"
    echo "2. Migrate nym-mixnode"
    echo "3. Quit"
    read -p "Enter your choice: " new_nym_menu_choice

    case $new_nym_menu_choice in
        1)
            # INSTALL NODE


            # Download latest binary
            wget -q -O $nym_binary_name "$nym_release_url/$nym_binary_name"
            chmod u+x $nym_binary_name
            sudo mv $nym_binary_name /usr/local/bin/

            read -p "Enter wallet Address: " wallet_address

            nym_node_id="nym-mixnode"

            # Init new binary
            nym-mixnode init --id $nym_node_id --host $bind_ip --announce-host $announce_ip --wallet-address $wallet_address

            sudo ufw allow 1789,1790,8000,22/tcp >/dev/null && yes | sudo ufw enable >/dev/null

            sudo systemctl restart ufw

            echo "Storage=persistent" | sudo tee /etc/systemd/journald.conf >/dev/null
            sudo systemctl restart systemd-journald

            sudo tee /etc/systemd/system/nym-mixnode.service >/dev/null <<EOF
            [Unit]
            Description=Nym Mixnode

            [Service]
            User=$USER
            ExecStart=/usr/local/bin/nym-mixnode run --id $nym_node_id
            KillSignal=SIGINT
            Restart=on-failure
            RestartSec=30
            StartLimitInterval=350
            StartLimitBurst=10
            LimitNOFILE=65535

            [Install]
            WantedBy=multi-user.target
EOF


            sudo sh -c 'echo "DefaultLimitNOFILE=65535" >> /etc/systemd/system.conf'
            sudo systemctl daemon-reload && sudo systemctl enable nym-mixnode && sudo systemctl restart nym-mixnode

            
            sleep 2

            if [[ `service nym-mixnode status | grep active` =~ "running" ]]; then
                nym_version=$(grep "version" "$config_file" | awk -F "'" '{print $2}')
                echo
                sudo systemctl status nym-mixnode --no-pager
                echo
                echo -e "nym-mixnode installed version: $nym_version, remember to bond your node in your wallet!"
                echo
                echo -e "Server Restart Initiated"
                sudo reboot
            else
            echo -e "nym-mixnode was not installed correctly, please re-install."
            fi

            exit
            ;;
        2)
            # MIGRATE SECTION
            



            ;;
        3)
            exit
            ;;
        *)
            echo
            echo -e "\xE2\x9C\x97 Invalid option, please try again."
            ;;
    esac
done

fi