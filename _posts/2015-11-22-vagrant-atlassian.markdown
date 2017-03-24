---
layout: post
title: "Developing Atlassian Plugins with Vagrant"
description: ""
category: articles
tags: []
---

*tldr*DevOps tools are great for teams, but they are great for
one-person efforts too. A basic knowledge of Vagrant and Ansible
makes it much easier to create and maintain custom development environments.*/tldr*

I've been a user of various Atlassian tools for several years, and have
developed a couple plugins along the way to make things easier.
Atlassian has a substantial SDK with toolkit available for use, but
since I use Maven every day for work, I'm very sensitive to anything
that wants to add new Maven configuration to my everyday machine,
even as a separate set of commands and configuration file. So I did
what I always do in this case, which is to drop it into a virtual
machine.

The big change for me over the past couple years has been the transition
to Vagrant and to DevOps tools like Puppet and Ansible. Before, I would
make a VM for a purpose, and try to keep it around forever, eventually
archiving it to an OVA and saving it somewhere. Now, a few kilobytes
of description, and I can re-create the VM from scratch whenever I need
it. Besides the disk space savings, I find I forget less about how I
set things up, because I know that any permanent change needs to be in
a config file.

For my Atlassian SDK VM, I used this Vagrantfile:

```vagrantfile
---
layout: post
title: "-*- mode: ruby -*-"
description: ""
category: articles
tags: []
---
---
layout: post
title: "vi: set ft=ruby :"
description: ""
category: articles
tags: []
---

VAGRANTFILE_API_VERSION = "2"

proxy = ENV['http_proxy'] || ""

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/vivid64"
  config.vm.hostname = "atlassian"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 4096
    vb.cpus = 4
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.extra_vars = {
      proxy_env: {
        http_proxy: proxy
      }
    }
  end
  config.vm.network "forwarded_port", guest: 1990, host: 1990,
    auto_correct: true
  config.vm.synced_folder "~", "/host"

end
```

This is for developing a Confluence plugin, and I test it
by running Confluence in the VM. Since it shows up on port 1990,
I can easily use my normal browser if the port is forwarded. Also,
making my host home directory available on the VM makes it easier
to run Eclipse in the host but do the full compile and run inside
the VM.

Vagrant delegates to Ansible for the provisioning. The Ansible
playbook looks like this:

```yaml
---
- hosts: all
  sudo: yes
  tasks:
  - name: update
    apt: upgrade=yes
    environment: proxy_env
  - name: install openjdk
    apt: name=openjdk-8-jdk state=present 
    environment: proxy_env
  - name: apt over https
    apt: name=apt-transport-https
    environment: proxy_env
  - name: atlassian apt key
    apt_key: keyserver=keyserver.ubuntu.com id=B07804338C015B73
  - name: install atlassian repo
    apt_repository: repo='deb https://sdkrepo.atlassian.com/debian/ stable contrib'
    environment: proxy_env
  - name: install atlassian sdk
    apt: name=atlassian-plugin-sdk update_cache=yes
    environment: proxy_env
```

Using this setup, I was able to have an Atlassian plugin development
environment set up in under an hour, to the extent of having a basic
plugin show up inside a running copy of Confluence. And despite the
fact that I've since destroyed that VM to save disk space, I'm confident
that I could get it back in around 15 minutes to pick up where I left off.

