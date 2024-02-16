# Prerequisites

You need to have a couple of things set up to take advantage of the template and qcow2's:

- Server with KVM/QEMU/libvirt installed and working
  - A "baselines" pool used to hold the images that your VMs will use
  - A "working" pool used to hold files related to unique workspace VMs
- Ability to SSH into that server from your Coder instance

## Pools

The pools might not be totally intuitive, so I wanted to explain those a bit better.

Libvirt allows you to create a number of Virtual Machines based on a single "base volume".
When you do this, each VM will have a sparse disk which holds the changes from the base volume.
This means that you can have a single 20GB base volume and 10 VMs based on it with 1GB of changes each, and only use a total of 30GB instead of 210GB.
It also had the added benefit of not modifying the underlying base volume, so there's no concern about changes on one VM affecting other VMs.

The easiest to get this working is to create two libvirt pools (one or the base volumes and one for the sparse volumes).
I like the name "baselines" and "working" for these, but you can name them whatever you want.

# Usage

1. Download or Build the items as described below
1. Place the "nixos-base.qcow2" and "home.ext4.qcow2" images in your base pool
1. Create a new template from the template tar
1. Change the `locals` variables at the top of the template as needed for your setup

# Builds

I have set up the [GitHub Actions for this repository](https://github.com/bamhm182/Coder-Templates-Public/actions/workflows/build-nixos.yml) to build the images and template automatically when I push to `main`. If you don't want to use those, you can find the instructions to build them below.

## NixOS

If you're already on a NixOS system, you should be able to build the qcow2 with the following command:

```
nix build ./src/nixos#base --out-link /tmp/nixos-base.qcow2
ls -lath /tmp/nixos-base.qcow2/nixos.qcow2
```

## Home Disk

One of Coder's key features is the idea that your home drive should persist while your underlying OS gets deleted.
This was a little more difficult to implement here, but I've had great success with base volumes for the primary OS disk, and found that a similar approach worked well here too.
The problem is, how do you generate the qcow2 to use as the base volume for the "/home"?

You can create it with the following commands:

```
working_dir=$(mktemp -d)

# Create the base qcow2
qemu-img create -f qcow ${working_dir}/home.ext4.qcow2 20G

# Mount the qcow2
modprobe nbd max_part=10
qemu-nbd --connect /dev/nbd0 ${working_dir}/home.ext4.qcow2

# Format the qcow2
parted --script --align optimal /dev/nbd0 unit MiB mklabel gpt mkpart primary ext4 0% 100%
mkfs.ext4 -L home /dev/nbd0p1

# Unmount the qcow2
qemu-nbd --disconnect /dev/nbd0

# Compress the qcow2 (~1.3MB vs ~133MB)
qemu-img -c -O qcow2 ${working_dir}/home.ext4.qcow2 ${working_dir}/home.shrunk.ext4.qcow2
mv ${working_dir}/home.shrunk.ext4.qcow2 ${working_dir}/home.ext4.qcow2

# Print the location of your new qcow2
echo ${working_dir}/home.ext4.qcow2
```

From there, you can put it in your baselines directory and all your VMs will use it as a jumping off point.

# About this NixOS Configuration

The hard part about NixOS is that everyone has their own way of doing things.
I have found that this structure makes the most sense for me, but I wanted to explain it in case it isn't intuitive to you.

- baselines: 
  - base:
    - default.nix: Options which are used throughout ./config/commmon to allow me to easily change things about the "base" baseline
- config: The actual "root" of my NixOS configuration
  - common: Configurations for everything that is going to be available across all baselines, even if not used
  - flake.nix: The flake.nix that will end up at `/etc/nixos/flake.nix` inside the VM. It only describes that single system. `initialHostname` is replaced with the hostname of the actual configuration by a systemd service.
  - options: Options used within ../baselines/*/default.nix to enable/disable features
  - postCreation: Some hardware and other configurations used by the VM to boot/operate as expected
- copyConfig.nix: I wanted to make it possible to put the NixOS config inside of the qcow2 file, and this file is how that's done
- flake.nix: A flake.nix used to define the various baseline qcow2's I want to create. Only "base" exists here
- formats:
  - qcow2.nix: Describes the qcow2 this configuration outputs.
