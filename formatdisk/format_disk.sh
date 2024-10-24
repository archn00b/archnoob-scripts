#!/usr/bin/env bash

# Function to format the disk using fdisk
format_disk() {
    local disk="/dev/sda"
    
    # Create partition table and define partitions
    {
        echo "g"      # Create a new GPT partition table
        echo "n"      # New partition
        echo "1"      # Partition number
        echo ""       # First sector (default)
        echo "+1G"    # Size of the partition
        echo "t"      # Change partition type
        echo ""      # Partition number
        echo "19"     # Type (Linux swap)
        echo "n"      # New partition
        echo "2"      # Partition number
        echo ""       # First sector (default)
        echo "+8G"    # Size of the partition
        echo "n"      # New partition
        echo "3"      # Partition number
        echo ""       # First sector (default)
        echo ""       # Size (default to remaining space)
        echo "p"      # Print partition table
        echo "w"      # Write changes
    } | fdisk "$disk"

    # Format the file system
    echo "Formatting the file system..."
    
    mkfs.fat -F 32 "${disk}1" || { echo "Failed to format ${disk}1"; exit 1; }
    mkswap "${disk}2" || { echo "Failed to create swap on ${disk}2"; exit 1; }
    mkfs.ext4 "${disk}3" || { echo "Failed to format ${disk}3"; exit 1; }
}

format_disk

