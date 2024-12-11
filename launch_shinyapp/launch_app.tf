# Questo codice è compatibile con Terraform 4.25.0 e versioni precedenti compatibili con 4.25.0.
# Per informazioni sulla convalida di questo codice Terraform, visita la pagina https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration

resource "google_compute_instance" "shiny-rnaseq" {
  boot_disk {
    auto_delete = true
    device_name = "shiny-rnaseq"

    initialize_params {
      image = "projects/compgen-dbb-playground/global/images/compgen-playground-docker-fuse"
      size  = 50
      type  = "hyperdisk-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    analysis              = "rnaseq_shiny_app"
    env                   = "cpu"
    goog-ec-src           = "vm_add-tf"
    goog-ops-agent-policy = "v2-x86-template-1-3-0"
    scope                 = "teaching"
    type                  = "interactive"
    user                  = "francesco"
  }

  machine_type = "c4-standard-8"
  name = "shiny-rnaseq"

  metadata = {
    enable-osconfig = "TRUE"
	ssh-keys = "${var.vm_username}:${file("./google_key.pub")}"
  }

  provisioner "remote-exec" {
    connection {
        type = "ssh"
        user = "${var.vm_username}" ### --> SAME user you indicated in metadata
        host = self.network_interface[0].access_config[0].nat_ip
        private_key = file("./google_key") ### --> now this is the PRIVATE key you will only have where executing THIS script
    }
    inline = [
	  "sudo mkdir -p /home/apps/rnaseq_app",
	  "sudo chown -R ${var.vm_username}:${var.vm_username} /home/apps", ### --> this is the user you are using to connect to the instance
	  "sudo chmod g+w /home/apps"
    ]
  }

  provisioner "file" {
	source = "../rnaseq_app/app.R"
	destination = "/home/apps/rnaseq_app/app.R"
	connection {
	type = "ssh"
	user = "${var.vm_username}" ### --> SAME user you indicated in metadata
	host = self.network_interface[0].access_config[0].nat_ip
	private_key = file("./google_key") ### --> now this is the PRIVATE key you will only have where executing THIS script
	}
  }

  provisioner "remote-exec" {
    connection {
        type = "ssh"
        user = "${var.vm_username}" ### --> SAME user you indicated in metadata
        host = self.network_interface[0].access_config[0].nat_ip
        private_key = file("./google_key") ### --> now this is the PRIVATE key you will only have where executing THIS script
    }
    inline = [
	  "docker run -dt -v /home/apps:/srv/shiny-server -p 3838:3838 --name shinyserver ghcr.io/lescai-teaching/rstudio-shiny:latest"
    ]
  }

  

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    nic_type    = "GVNIC"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/compgen-dbb-playground/regions/europe-west3/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "372887427342-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-server", "https-server", "rstudio", "shiny"]
  zone = "europe-west3-b"
  project = "compgen-dbb-playground"
}



####################################
## VARIABLES DEFAULTS DECLARATION ##
####################################

variable "vm_username" {
    default = "default"
}

variable "vm_password" {
    default = "default"
}

variable "vm_name" {
    default = "default"
}
