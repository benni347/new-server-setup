# Makefile for creating a Debian VM

# Variables
VM_NAME := debian-test
DISK_SIZE := 20G
RAM := 2048
CPUS := 2
ISO_URL := https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.6.0-amd64-netinst.iso
ISO_PATH := ./isos/debian-12.6.0-amd64-netinst.iso
DISK_PATH := $(VM_NAME).qcow2

# Targets
.PHONY: all download_iso create_disk check_network create_vm start_vm clean

all: download_iso create_disk check_network create_vm

download_iso:
	@echo "Downloading Debian ISO..."
	@mkdir -p ./isos
	@if [ ! -f $(ISO_PATH) ]; then \
		wget -O $(ISO_PATH) $(ISO_URL); \
	else \
		echo "ISO already exists. Skipping download."; \
	fi

create_disk:
	@echo "Creating disk image..."
	qemu-img create -f qcow2 $(DISK_PATH) $(DISK_SIZE)

check_network:
	@echo "Checking default network..."
	@if ! virsh --connect qemu:///system net-list --all | grep -q "default"; then \
		echo "The default network does not exist. Please run the following commands as root:"; \
		echo "sudo virsh net-define /etc/libvirt/qemu/networks/default.xml"; \
		echo "sudo virsh net-start default"; \
		echo "sudo virsh net-autostart default"; \
		exit 1; \
	elif ! virsh --connect qemu:///system net-list | grep -q "default"; then \
		echo "The default network exists but is not active. Please run the following command as root:"; \
		echo "sudo virsh net-start default"; \
		exit 1; \
	else \
		echo "The default network is active."; \
	fi

create_vm: download_iso check_network
	@echo "Creating VM..."
	virt-install \
		--connect qemu:///system \
		--name $(VM_NAME) \
		--ram $(RAM) \
		--vcpus $(CPUS) \
		--disk path=$(DISK_PATH),format=qcow2 \
		--cdrom $(ISO_PATH) \
		--os-variant debian11 \
		--network network=default \
		--graphics vnc \
		--noautoconsole \
		|| (echo "VM creation failed. Check libvirt status and permissions."; exit 1)

start_vm:
	@echo "Starting VM..."
	virsh --connect qemu:///system start $(VM_NAME)

clean:
	@echo "Cleaning up..."
	-virsh --connect qemu:///system destroy $(VM_NAME)
	-virsh --connect qemu:///system undefine $(VM_NAME)
	-rm $(DISK_PATH)
	@echo "Note: The ISO file $(ISO_PATH) was not deleted."
