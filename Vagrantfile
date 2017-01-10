# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
PROJECT_NAME = "kaa"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "centos/6"
  config.vm.network :private_network, ip: "192.168.10.16"
  config.vm.synced_folder ".", "/srv/" + PROJECT_NAME
  config.vm.network "forwarded_port", guest: 3000, host: 3005
  config.vm.network "forwarded_port", guest: 3306, host: 3309

  config.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--name", PROJECT_NAME]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 2048]
      v.customize ["modifyvm", :id, "--cpus", 2]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook       = "ansible/playbooks/kaa.yml"
    ansible.install        = true,
    ansible.verbose        = "v"
    ansible.inventory_path = "ansible/local.ini"
  end

  config.vm.define PROJECT_NAME do |machine|
      machine.vm.hostname = PROJECT_NAME
  end
end
