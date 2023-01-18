#!/bin/bash

# * target_list           :  ("<node name>") e.g: ("IAD" "MOW" "HKG")
# * target_ip_list        :  ("<node ip>")   e.g: ("fe80::c1:2" "fe80::e1:1" "fe80::a1:1")
# * target_interface_list :  ("<node nic>")  Required this if target using the local address.
# * to_path               :  ("<bird conf path>") e.g: /etc/bird/
# * to_file               :  ("<bird conf name>") e.g: latency.conf
target_list=("IAD" "MOW" "HKG")
target_ip_list=("fe80::c1:2" "fe80::e1:1" "fe80::a1:1")
target_interface_list=("SEA_IAD" "SEA_MOW" "SEA_HKG")
to_path="/etc/bird/"
to_file="latency.conf"

if [[ $(id -u) -ne 0 ]]; then
    echo "[error] Use root user please."
    exit 1
fi

if command -v ping &> /dev/null && command -v bc &> /dev/null; then
    is_have_ping_bc="1"
else
    is_have_ping_bc=""
    echo "[init] update & install bc and iputils-ping"
fi

if is_have_ping_bc="1"; then
elif is_have_ping_bc="" && command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    apt-get update > /dev/null
    apt-get install -y bc iputils-ping  > /dev/null
elif is_have_ping_bc="" && command -v yum &> /dev/null; then
    # Fedora/CentOS/RHEL
    yum update > /dev/null
    yum install -y bc iputils-ping coreutils > /dev/null
elif is_have_ping_bc="" && command -v pacman &> /dev/null; then
    # Arch Linux
    pacman -Sy > /dev/null
    pacman -S bc iputils coreutils > /dev/null
elif is_have_ping_bc="" && command -v dnf &> /dev/null; then
    # Fedora 22+ and Centos 8
    dnf update > /dev/null
    dnf install -y bc iputils coreutils > /dev/null
elif is_have_ping_bc="" && command -v zypper &> /dev/null; then
    # OpenSUSE
    zypper refresh > /dev/null
    zypper install -y bc iputils coreutils > /dev/null
elif is_have_ping_bc="" && command -v xbps-install &> /dev/null; then
    # Void Linux
    xbps-install -S bc iputils coreutils > /dev/null
elif is_have_ping_bc="" && command -v eopkg &> /dev/null; then
    # Solus OS
    eopkg update-repo > /dev/null
    eopkg install -y bc iputils coreutils > /dev/null
else
    echo "[error] Unsupport your OS."
    exit 1
fi

if [[ -w "$to_path$to_file" ]]; then
    echo "" > "$to_path$to_file"
    chmod -R 664 "$to_path$to_file"
    echo "[init] Fixed file permission"
elif [[ ! -s "$to_path$to_file" ]]; then
    echo "" > "$to_path$to_file"
    echo "[init] Overwrite file to empty."
else
    echo "[init] File is OK."
fi

echo "[load] Latency Testing."
for i in ${!target_list[@]}; do
    target=${target_list[i]}
    target_ip=${target_ip_list[i]}
    target_nic=${target_interface_list[i]}
    
    if [[ $target_interface_list == "" ]]; then
        result=$(ping -c 4 $target_ip -i 0.1 -t 255 2>/dev/null | tail -1 | awk '{print $4}' | cut -d '.' -f 1)
    else
        result=$(ping -c 4 $target_ip -I $target_nic -i 0.1 -t 255 2>/dev/null | tail -1 | awk '{print $4}' | cut -d '.' -f 1)
    fi
    
    isnum=$(echo $result | sed 's/[0-9]//g')

    # * $result = NULL / +NUM
    # * if !NULL else NULL
    if [[ ! -n "$isnum" ]]; then
        status="[ up ]"
        msg="$target OK"
        latency=$(echo "$result * 10" | bc)
    else
        status="[down]"
        msg="$target NULL"
        latency="114514"
    fi

    echo "define "$target"_OSPF_LATENCY=$latency;" >> "$to_path$to_file"
    echo "$status $msg Latency: $result ms, OSPF Cost: $latency"
done

echo "[done] bye!"
exit 0;