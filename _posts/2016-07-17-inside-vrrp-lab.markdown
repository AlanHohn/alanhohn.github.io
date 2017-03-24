---
layout: post
title: "VRRP Virtual Lab with Ubuntu Xenial and Vagrant"
description: ""
category: articles
tags: []
---

The Virtual Router Redundancy Protocol (VRRP) provides a way for multiple hosts
to communicate so that one of them at a time can hold a virtual IP. Since VRRP
is useful for high availability and operates at the intersection of Layer 2 and
Layer 3 of the [OSI model][osi], it's an interesting topic for a better
understanding of networking.

[Last time][1] I introduced VRRP, then spent some time on the Address
Resolution Protocol (ARP), which is used to locate the Ethernet address for a
given IP address. This time I want to head off in a slightly different
direction. To work with VRRP, we need at least two hosts with a networking
stack and a VRRP implementation. We should also have a client that can be used
to ensure the hosts are working.

I've built [a virtual lab][gh] using Vagrant, VirtualBox, and Ansible.  Along
the way there were some interesting lessons learned about working with Vagrant
and the latest Ubuntu (16.04 LTS, a.k.a. Xenial). Once I hit about the third
one of these showstoppers I figured I better take an article to describe each
of them and how I got around them.

### Starts and Beginnings

You can see the whole `Vagrantfile` in the [GitHub repo][gh]. The box we're
using is `ubuntu/xenial64`. This box represents a change from previous versions
of Ubuntu. Before, the boxes were created pretty specifically for Vagrant. This
means they have a `vagrant` user, with a standard SSH key and passwordless sudo
access. However, the "xenial" Vagrant box is pretty much a standard Ubuntu
cloud image.  This has some potential advantages, in that an Ubuntu Vagrant box
running Xenial will be very similar to an Ubuntu box in the cloud.  However, it
means there are some differences we have to be aware of.

The first difference is that, instead of a `vagrant` user, there is a standard
`ubuntu` user. Also, instead of access via key, the SSH access is via user name
and password. Fortunately, the box itself takes care of the configuration for
this, including for the provisioning we'll be doing with Ansible as well as for
`vagrant ssh`. So we just have to be aware of it if we connect to the VM through
some other means.

Second, there's a useful configuration in the box that tells VirtualBox to send
the console log to a virtual serial port. This serial port is then routed to a
file. So when you run the Vagrant VM, you get a log file in the same directory
with the console output. This is nice if your VM dies suddenly; I intend to
steal this trick to use with other Vagrant boxes.

Third, because it's a generic cloud image, the VirtualBox Guest Additions are
not installed. This is something of a hassle for me, because I really like getting
files out of the VM by copying them to `/vagrant`. Of course, for getting files
into the VM, Ansible works just fine. Fortunately, since we have SSH, it's possible
to use SCP to the host to get files out (assuming you're on an OS with an SSH
server). When running a VirtualBox VM, the host is generally visible to the VM on
10.0.2.2.

### Python

We are going to provision our Vagrant boxes with Ansible. Ansible has the advantage
that it doesn't require much in the way of installation or setup on the target
system, as Ansible itself runs locally, connects to the target over SSH, and then
performs the commands over that connection. However, many Ansible commands are
performed using Python on the remote system.

Unlike previous versions of Ubuntu, the Xenial Vagrant box does not come with
any kind of Python installed. So we need a way to bootstrap Python onto the target
system before the Ansible provisioner can run. It has to be Python 2, because
Ansible hasn't yet switched over.

The best way to do this is with a shell provisioner:

```ruby
  config.vm.provision "shell",
    inline: "sudo apt-get -y install python",
    env: {
      http_proxy: proxy,
      https_proxy: proxys
    }
```

The "env" is a trick I use with Vagrant VMs to make it easier to operate inside
and outside of a corporate network with an HTTP proxy. The variables are pulled
from the host environment as follows:

```ruby
proxy = ENV['http_proxy'] || ""
proxys = ENV['https_proxy'] || ""
```

They are then used in provisioner steps.

While we're covering things missing from the cloud image, it's worth mentioning
that `aptitude` is no longer part of the installed cloud image. It is needed
for Ansible's `apt` module to be able to perform upgrades (with `upgrade=yes`),
so we need to add to the top of our `playbook.yml`:

```yaml
  - name: install apt requirements
    apt: name=aptitude state=present
```

### Naming

The next issue cropped up when I created my second Vagrant VM using the same
Xenial Vagrant box. It turns out that the Xenial box explicitly sets the name
of the VM inside VirtualBox. You can see this by looking at the Vagrantfile of
the box itself:

```
$HOME/.vagrant.d/boxes/ubuntu-VAGRANTSLASH-xenial64/<version>/virtualbox/Vagrantfile:

  config.vm.provider "virtualbox" do |vb|
     vb.name = "ubuntu-xenial-16.04-cloudimg"
     ...
  end
```

This Vagrantfile represents the base configuration for this box; the
configuration commands in the Vagrantfile we use for `vagrant up` are really
just overrides.

I can only guess this explicit naming was done to match a VM spun up by downloading
the cloud image outside of Vagrant. Unfortunately, this breaks Vagrant's usual method
of generating a name using the name of the directory, the name of the virtual machine
(if multiple VMs are defined in the Vagrantfile), and a timestamp.

As a result, when the second box comes up, it tries to use the same name as the
first box, and you get this error message:

```
A VirtualBox machine with the name 'ubuntu-xenial-16.04-cloudimg' already exists.
```

We could edit the box's Vagrantfile to remove this line, but I don't like this
approach as anyone cloning the repo would have to do that, and it wouldn't survive
a `vagrant box update`. So instead I override the box name in my Vagrantfile:

```
  config.vm.define "server1" do |host|
      ...
      host.vm.provider "virtualbox" do |vb|
        vb.name = "server1"
      end
  end
```

### Groups

This gets us to the place where we can perform a normal `vagrant up` and 
start provisioning using Ansible. Since we're declaring multiple VMs with
this Vagrantfile, and we want different things to be installed on each one,
we need to have different plays in the `playbook.yml` that apply to different
hosts. Vagrant will pass through to Ansible the name of the VM it's
provisioning, so we can use those names in the playbook. However, since we're
not reading a separate inventory file, we need a different way to configure
groups.

The Vagrant Ansible provisioner provides that:

```ruby
    ansible.groups = {
        "server" => ["server1", "server2"]
    }
```

This way we can say `hosts: server` in the `playbook.yml` and it will install
on both VMs.

### Variables

When provisioning a Vagrant box with Ansible, we can create a `group_vars`
directory in the same place as the `playbook.yml` and populate it with files
defining variables for all hosts or for groups or individual hosts. However,
we can also define variables directly in the Vagrantfile. This is what I use
for the HTTP proxy settings, because it makes it easier to import environment
variables from the host. But it's also useful for other variables, because then
we can use them in the Vagrantfile as well.

The key insight is that a Vagrantfile is executed as normal Ruby. So we can
do something like declare a hash:

```ruby
hosts = {
  "server1" => "192.168.199.2",
  "server2" => "192.168.199.3",
  "server" => "192.168.199.10",
  "client" => "192.168.199.101"
}
```

We can then use that hash directly in the Vagrantfile:

```ruby
  config.vm.define "server1" do |host|
      host.vm.hostname = "server1"
      host.vm.network "private_network", ip: hosts["server1"]
      ...
  end
```

And then pass it through to Ansible using `ansible.extra_vars`:

```ruby
    ansible.extra_vars = {
      ...
      hosts: hosts,
      ...
    }
```

We can then use this variable in the playbook or a template. This
saves us from having to repeat the same configuration in two places.

### Wrapping Up

With these lessons behind us, we have a virtual lab with three VMs:
two servers and a client. We can now use those to delve into VRRP to
make sure our configuration behaves the way it should.

You can see the [full setup][gh] for yourself, and run it on any machine
with Vagrant, VirtualBox, and Ansible.

[1]:https://dzone.com/articles/inside-vrrp-introduction
[osi]:https://en.wikipedia.org/wiki/OSI_model
[gh]:https://github.com/AlanHohn/vrrp-lab

