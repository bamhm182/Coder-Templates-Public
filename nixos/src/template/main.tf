# !!! Change These !!!

locals {
  macvtap_interface  = "eth0"
  baseline_pool_name = "baselines"
  working_pool_name  = "working"
}

provider "libvirt" {
  uri = "qemu+ssh://user@host/session?keyfile=/home/coder/.ssh/id_ed25519"
  # uri = "qemu+ssh://user:password@host/session"
  # uri = "qemu+ssh://user@host/session?sshauth=password
  # Recommended to use the `LIBVIRT_DEFAULT_URI` environmental variable instead of definining this here
}

######################

# --- Providers ---

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "coder" {}

# --- Parameters ---

data "coder_parameter" "baseline_image" {
  name         = "baseline_image"
  display_name = "Baseline image"
  description  = "Which Baseline would you like to use?"
  default      = "nixos-base"
  type         = "string"
  mutable      = false

  option {
    name  = "Base"
    value = "nixos-base"
  }
}

data "coder_parameter" "cpu_count" {
  name         = "cpu_count"
  display_name = "CPU Count"
  description  = "How many CPU's would you like?"
  default      = "1"
  type         = "string"
  icon         = "/icon/memory.svg"
  mutable      = true

  option {
    name  = "1 CPU"
    value = "1"
  }
  option {
    name  = "2 CPUs"
    value = "2"
  }
}

data "coder_parameter" "ram_amount" {
  name         = "ram_amount"
  display_name = "RAM Amount"
  description  = "How much RAM would you like?"
  default      = "1024"
  type         = "string"
  mutable      = true

  option {
    name = "1 GB"
    value = "1024"
  }
  option {
    name = "2 GB"
    value = "2048"
  }
}

# --- Coder ---

data "coder_workspace" "me" {}

resource "coder_agent" "main" {
  os           = "linux"
  arch         = "amd64"
  count        = data.coder_workspace.me.start_count

  metadata {
    key          = "cpu"
    display_name = "CPU Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat cpu"
  }

  metadata {
    key          = "memory"
    display_name = "Memory Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat mem"
  }

  metadata {
    key          = "disk"
    display_name = "Home Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = "coder stat disk --path /home/user"
  }
}

# --- Credentials ---

resource "tls_private_key" "ssh_key" {
  count = data.coder_workspace.me.start_count
  algorithm = "ED25519"
}

resource "coder_metadata" "tls_private_key_ssh_key" {
  count = data.coder_workspace.me.start_count
  resource_id = tls_private_key.ssh_key[0].id
  item {
    key = "Private SSH Key"
    value = tls_private_key.ssh_key[0].private_key_openssh
    sensitive = true
  }
  item {
    key = "Public SSH Key"
    value = tls_private_key.ssh_key[0].public_key_openssh
    sensitive = true
  }
}

# --- libvirt ---

resource "libvirt_domain" "main" {
  count      = data.coder_workspace.me.start_count
  name       = lower("coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}")
  memory     = data.coder_parameter.ram_amount.value
  vcpu       = data.coder_parameter.cpu_count.value
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init[0].id

  disk {
    volume_id = libvirt_volume.root[0].id
  }

  disk {
    volume_id = libvirt_volume.home.id
  }

  boot_device {
    dev = [ "hd" ]
  }

  network_interface {
    macvtap        = local.macvtap_interface
    wait_for_lease = true
  }

  provisioner "remote-exec" {
    inline = [
      "install -d -m 0700 ~/.config/coder",
      "rm ~/.config/coder/*",
      "echo ${data.coder_workspace.me.access_url} > ~/.config/coder/url",
      "echo ${coder_agent.main[0].token} > ~/.config/coder/token",
      "chmod 0600 ~/.config/coder/*"
    ]

    connection {
      type        = "ssh"
      user        = "user"
      host        = libvirt_domain.main[0].network_interface.0.addresses.0
      private_key = tls_private_key.ssh_key[0].private_key_openssh
      timeout     = "1m"
    }
  }
}

# === cloudinit ===

data "template_file" "user_data" {
  count    = data.coder_workspace.me.start_count
  template = templatefile("${path.module}/user-data.cfg", {
    authorized_keys    = chomp(tls_private_key.ssh_key[0].public_key_openssh),
  })
}

resource "libvirt_cloudinit_disk" "init" {
  count     = data.coder_workspace.me.start_count
  name      = lower("coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-init.iso")
  user_data = data.template_file.user_data[0].rendered
  pool      = local.working_pool_name
}

# === disks ===

resource "libvirt_volume" "root" {
  name             = lower("coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}.qcow2")
  count            = data.coder_workspace.me.start_count
  pool             = local.working_pool_name
  format           = "qcow2"
  base_volume_name = "${data.coder_parameter.baseline_image.value}.qcow2"
  base_volume_pool = local.baseline_pool_name
}

resource "libvirt_volume" "home" {
  name             = lower("coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}.home.qcow2")
  pool             = local.working_pool_name
  format           = "qcow2"
  base_volume_name = "home.ext4.qcow2"
  base_volume_pool = local.baseline_pool_name
}


