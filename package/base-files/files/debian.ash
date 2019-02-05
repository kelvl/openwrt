#!/bin/ash
sed -re 's/^boot_run_hook/#\0/g' -i /etc/preinit
PREINIT=1 . /etc/preinit
preinit_config_board    # set up the switch and lan ports on eth0.2, and create ip link
json_select switch
json_select switch0
json_add_boolean reset 0   # do not reset when setting up wan ports on eth0.1
json_select ..
json_select ..
preinit_config_switch switch0 eth0.1   # set up wan ports
preinit_ip_config eth0.1               # create ip link
ip address flush dev eth0    # del default address
for pi_ifname in eth0.1 eth0.2; do
    ip -4 address flush dev $pi_ifname    # del default address
    ip link set dev $pi_ifname down
done
mkdir -pv /mnt
[ -b /dev/sda ] || mknod /dev/sda b 8 0
sed -re 's/\xFF//g' < /dev/mtdblock4 | egrep ^admin2_passphrase= | sed -re 's/^[^=]*=//g' | tr -d '\r' | tr -d '\n' | cryptsetup --key-file=- open /dev/sda usb &&
vgchange -ay vol_grp1 &&
mount /dev/vol_grp1/logical_vol1 /mnt -o ro &&
exec switch_root /mnt /sbin/init
exec /bin/ash
