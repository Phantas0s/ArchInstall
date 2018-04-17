#!/bin/bash

# COLORS
Bold=$(tput bold)
Underline=$(tput sgr 0 1)
Reset=$(tput sgr0)
# Regular Colors
Red=$(tput setaf 1)
Green=$(tput setaf 2)
Yellow=$(tput setaf 3)
Blue=$(tput setaf 4)
Purple=$(tput setaf 5)
Cyan=$(tput setaf 6)
White=$(tput setaf 7)
# Bold
BRed=${Bold}${Red}
BGreen=${Bold}${Green}
BYellow=${Bold}${Yellow}
BBlue=${Bold}${Blue}
BPurple=${Bold}${Purple}
BCyan=${Bold}${Cyan}
BWhite=${Bold}${White}

check_boot_system()
{
    if [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Inc.' ]] || [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Computer, Inc.' ]]; then
        modprobe -r -q efivars || true  # if MAC
    else
        modprobe -q efivarfs            # all others
    fi

    if [[ -d "/sys/firmware/efi/" ]]; then
        ## Mount efivarfs if it is not already mounted
        if [[ -z $(mount | grep /sys/firmware/efi/efivars) ]]; then
            mount -t efivarfs efivarfs /sys/firmware/efi/efivars
        fi
        UEFI=1
        echo "UEFI Mode detected"
    else
        UEFI=0
        echo "BIOS Mode detected"
    fi
}

check_root() {
    if [[ "$(id -u)" != "0" ]]; then
        error_msg "ERROR! You must execute the script as the 'root' user."
    fi
}

XPINGS = 0
check_connection(){
    XPINGS=$(( $XPINGS + 1 ))
    connection_test() {
      ping -q -w 1 -c 1 `ip r | grep default | awk 'NR==1 {print $3}'` &> /dev/null && return 1 || return 0
    }
    WIRED_DEV=`ip link | grep "ens\|eno\|enp" | awk '{print $2}'| sed 's/://' | sed '1!d'`
    WIRELESS_DEV=`ip link | grep wlp | awk '{print $2}'| sed 's/://' | sed '1!d'`
    if connection_test; then
      print_warning "ERROR! Connection not Found."
      print_info "Network Setup"
      local _connection_opts=("Wired Automatic" "Wired Manual" "Wireless" "Configure Proxy" "Skip")
      PS3="$prompt1"
      select CONNECTION_TYPE in "${_connection_opts[@]}"; do
        case "$REPLY" in
          1)
            systemctl start dhcpcd@${WIRED_DEV}.service
            break
            ;;
          2)
            systemctl stop dhcpcd@${WIRED_DEV}.service
            read -p "IP Address: " IP_ADDR
            read -p "Submask: " SUBMASK
            read -p "Gateway: " GATEWAY
            ip link set ${WIRED_DEV} up
            ip addr add ${IP_ADDR}/${SUBMASK} dev ${WIRED_DEV}
            ip route add default via ${GATEWAY}
            $EDITOR /etc/resolv.conf
            break
            ;;
          3)
            wifi-menu ${WIRELESS_DEV}
            break
            ;;
          4)
            read -p "Enter your proxy e.g. protocol://adress:port: " OPTION
            export http_proxy=$OPTION
            export https_proxy=$OPTION
            export ftp_proxy=$OPTION
            echo "proxy = $OPTION" > ~/.curlrc
            break
            ;;
          5)
            break
            ;;
          *)
            invalid_option
            ;;
        esac
      done
      if [[ $XPINGS -gt 2 ]]; then
        print_warning "Can't establish connection. exiting..."
        exit 1
      fi
      [[ $REPLY -ne 5 ]] && check_connection
    fi
}
