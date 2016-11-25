# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"
  config.vm.hostname = "zbx3"

  config.vm.network :forwarded_port, guest: 80, host: 2080
  #config.vm.network :forwarded_port, guest: 2080, host: 2080

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = 1024
    vb.cpus = 2
    vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
    vb.customize [
      'modifyvm', :id,
      '--hwvirtex', 'on',
      '--nestedpaging', 'on',
      '--largepages', 'on',
      '--ioapic', 'on',
      '--pae', 'on',
      '--paravirtprovider', 'kvm',
    ]
  end
  config.vm.provision :shell, path: 'provision/etckeeper.sh'
  config.vm.provision :shell, path: 'provision/ja_JP.sh'
  config.vm.provision :shell, path: 'provision/journald.sh'
  config.vm.provision :shell, path: 'provision/timesyncd.sh'
  config.vm.provision :shell, path: 'provision/packages.sh'
  config.vm.provision :shell, path: 'provision/packages-misc.sh'
  config.vm.provision :shell, path: 'provision/packages-go.sh'
  config.vm.provision :shell, path: 'provision/nadoka.sh'
  config.vm.provision :shell, path: 'provision/ufw.sh'
  config.vm.provision :shell, path: 'provision/backports.sh'
  config.vm.provision :shell, path: 'provision/zabbix.sh'
  config.vm.provision :shell, path: 'provision-user/dot-shell.sh', privileged: false
  config.vm.provision :shell, path: 'provision-user/vim.sh', privileged: false
  config.vm.provision :shell, path: 'provision-user/anyenv.sh', privileged: false
  config.vm.provision :shell, path: 'provision-user/go.sh', privileged: false
end
