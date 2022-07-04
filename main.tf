terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.76.0"
    }
  }
}

provider "yandex" {
  token                    = ""
  cloud_id                 = ""
  folder_id                = ""
  zone                     = "ru-central1-a"
}

resource "yandex_compute_instance" "build" {
  name        = "build"
  hostname    = "build"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
    image_id = "fd8fte6bebi857ortlja"
      size = 6
    }
  }

  network_interface {
    subnet_id = "e9bjpslo50evgegc3mko"
    nat = true
  }

  metadata = { 
    foo = "bar"
    serial-port-enable = true
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }

connection {
    type     = "ssh"
    user     = "root"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = yandex_compute_instance.build.network_interface.0.nat_ip_address
  }

provisioner "file" {
    source = "./Dockerfile"
    destination = "/opt/Dockerfile"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update && apt-get install -y docker.io",
      "docker login -u ivangelion -p  && cd /opt",
      "docker build -t for_hw_terra .",
      "docker tag for_hw_terra ivangelion/for_hw_terra:v1",
      "docker push ivangelion/for_hw_terra:v1"
    ]
  }
}


resource "yandex_compute_instance" "prod" {
  name        = "prod"
  hostname    = "prod"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8fte6bebi857ortlja"
    }
  }

  network_interface {
    subnet_id = "e9bjpslo50evgegc3mko"
    nat = true
  }

  metadata = {
    foo = "bar"
    serial-port-enable = true
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }

connection {
    type     = "ssh"
    user     = "root"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = yandex_compute_instance.prod.network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update && apt-get install -y docker.io",
      "docker run -d -p 5555:8080 ivangelion/for_hw_terra:v1"
    ] 
  }
}
