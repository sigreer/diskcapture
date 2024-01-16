#!/bin/bash

compressionlevel=9

# Check if the user has provided an argument
if [ -z "$1" ]; then
    echo "Please provide an argument. You can specify either a disk or a partition."
    echo ""
    echo "For exmaple:"
    echo "./diskcapture.sh /dev/sdg"
    echo "./diskcapture.sh sdg"
    echo "./diskcapture.sh sdg1"
    exit 1
fi

# Get the disk name from the user input
diskname=$1
diskname=${diskname#/dev/}
disk=/dev/"$diskname"

# Initialize the type variable
type=""

# Use a regular expression to check if the input is a partition
# This regex assumes that partition names end with numbers
if [[ $$diskname =~ [0-9]+$ ]]; then
    type="partition"
else
    type="disk"
fi

# Check if the user has provided an argument
if [ -z "$2" ]; then
    echo "Please provide a filename."
    echo "./diskcapture.sh <disk|partition> <name>"
    echo "./diskcapture.sh /dev/sda myimage"
    exit 1
fi

filename="$2"

# Check if the disk exists
if [ ! -b "$disk" ]; then
    echo "The disk '$disk' does not exist."
    exit 1
fi


if [[ -e "${filename}.img.gz" || -L "${filename}.img.gz" ]]; then
    i=0
    while [[ -e "${filename}-${i}.img.gz" || -L "${filename}-${i}.img.gz" ]] ; do
        (( i++ ))
    done
    filename="${filename}-${i}"
fi
function calculatePartitionValues() {
    partition="$1"
    total_bytes=$(lsblk -b -n -o SIZE "${partition}")
    total_sectors=$(lsblk -n -o SECTORS "${partition}")
}

function calculateValues() {
    if [[ $type == "disk" ]]; then
        total_sectors=$(blockdev --getsz "${disk}")
        total_bytes=$(blockdev --getsize64 "${disk}")
        mapfile -t partitions < <(ls /dev/ | grep -Eo "${diskname}"'[0-9]{1,4}')
        echo "${partitions[@]}"
        block_size=$(blockdev --getbsz "$disk")
    elif [[ $type == "partition" ]]; then
        calculatePartitionValues "$diskname"
    else
        echo "Unknown type: $type"
        return 1
    fi
}
# Iterate over the partitions and calculate the total number of bytes
# Then calculate the total number of sectors according to block size
total_sectors=0
total_bytes=0
for partition in "${partitions[@]}"; do
    bytes=$(blockdev --getsize64 "/dev/${partition}")
    sectors=$((bytes / block_size))
    total_bytes=$((total_bytes + bytes))
    total_sectors=$((total_sectors + sectors))
    echo "Partition $partition: $bytes bytes     $sectors sectors       Block size: $block_size"
done
echo "$disk"
echo "$total_bytes bytes"
echo "$total_sectors sectors"

function ddPvGzip() {
    echo "dd if=${disk} bs=${block_size} count=${total_sectors} | pv -s ${total_bytes} | gzip -${compressionlevel} > ${filename}"
    dd if="${disk}" bs="${block_size}" count=${total_sectors} | pv -s ${total_bytes} | gzip -${compressionlevel} > "${filename}"
}

function ddDefaultBlockProgress() {
    echo "dd if=${disk} bs=${block_size} count=${total_sectors} of=${filename} status=progress"
    dd if="${disk}" bs="${block_size}" count=${total_sectors} of="${filename}" status="progress"
}

function ddDefaultBlockProgressGzip() {
    echo "dd if=${disk} bs=${block_size} count=${total_sectors} | gzip -c > ${filename}"
    dd if="${disk}" bs="${block_size}" count=${total_sectors} | gzip -c > "${filename}"
}

function ddBigBlockGzip() {
    echo "dd bs=1M iflag=fullblock if=${disk} status=progress | gzip >${filename}"
    dd bs=1M iflag=fullblock if="${disk}" status=progress | gzip >"${filename}"
}

function ddBigBlockZst() {
    echo "dd bs=1M iflag=fullblock if=${disk} status=progress | zstd -16v >${filename}"
    dd bs=1M iflag=fullblock if="${disk}" status=progress | zstd -16v >"${filename}"
}

function partcloneGzip() {
    fstype=$(blkid -o value -s TYPE "${disk}") 
    if [ -z "$fstype" ]; then
        echo "Unable to determine the filesystem type automatically."
        read -p "Please enter the filesystem type (e.g., ntfs, ext4): " fstype
    fi
    echo "partclone.$fstype -c -s ${disk} | pv | gzip > ${filename}"
    partclone.$fstype -c -s "${disk}" | pv | gzip > "${filename}"
}

function ddPigz() {
    echo "dd if=${disk} bs=${block_size} | pv -s ${total_bytes} | pigz > ${filename}"
    dd if="${disk}" bs="${block_size}" | pv -s "${total_bytes}" | pigz > "${filename}"
}

function ddrescueProgress() {
    echo "ddrescue ${disk} ${filename} backup.log --force -D"
    ddrescue "${disk}" "${filename}" backup.log --force -D
}

function ddXz() {
    echo "dd if=${disk} bs=${block_size} | pv -s ${total_bytes} | xz -T0 > ${filename}"
    dd if="${disk}" bs="${block_size}" | pv -s "${total_bytes}" | xz -T0 > "${filename}"
}

function ddBzip2() {
    echo "dd if=${disk} bs=${block_size} | pv -s ${total_bytes} | bzip2 > ${filename}"
    dd if="${disk}" bs="${block_size}" | pv -s "${total_bytes}" | bzip2 > "${filename}"
}

function dcflddGzip() {
    echo "dcfldd if=${disk} bs=${block_size} | pv -s ${total_bytes} | gzip > ${filename}"
    dcfldd if="${disk}" bs="${block_size}" | pv -s "${total_bytes}" | gzip > "${filename}"
}

function ddLrzip() {
    echo "dd if=${disk} bs=${block_size} | pv -s ${total_bytes} | lrzip > ${filename}"
    dd if="${disk}" bs="${block_size}" | pv -s "${total_bytes}" | lrzip > "${filename}"
}

function show_menu() {
    echo "Select an option:"
    echo "1) DD with PV and GZip"
    echo "2) DD with Pigz"
    echo "3) Partclone with GZip"
    echo "4) DD with XZ"
    echo "5) DD with Bzip2"
    echo "6) Dcfldd with Gzip"
    echo "7) DD with Lrzip"
    echo "8) Exit"
    read -p "Enter choice [1-8]: " choice

    case $choice in
        1) ddPvGzip ;;
        2) ddPigz ;;
        3) partcloneGzip ;;
        4) ddXz ;;
        5) ddBzip2 ;;
        6) dcflddGzip ;;
        7) ddLrzip ;;
        8) exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Main loop
while true; do
    show_menu
done
