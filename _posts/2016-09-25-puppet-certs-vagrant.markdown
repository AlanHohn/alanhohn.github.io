---
layout: post
title: "Managing Puppet Certificates for Vagrant VMs"
description: ""
category: articles
tags: []
---

[Vagrant][1] has built-in support for running Puppet in either "apply" mode,
where the Puppet manifests and modules are provided from the host running
Vagrant, or in "server" mode, where Puppet on the VM connects to some shared
Puppet server. The latter choice has the advantage of requiring less setup for
new users and of being closer to a typical production environment.

However, there is one major issue with using Puppet this way. For security,
Puppet uses certificate authentication that includes a certificate for the
client. On a new operating system install, this typically works like this:

1. The new client attempts to connect to the Puppet server. It accepts the
   server certificate (as long as the name matches what it expects). It
   generates a new certificate for the client and provides the public side.
1. The new client certificate goes into a list of waiting certificates on
   the Puppet server.
1. An administrator looks over the list of certificates waiting to be signed,
   verifies them, and runs "puppet cert" to sign them.
1. The client is now able to authenticate to the server using the new
   certificate.

The signing step is sometimes automated with a tool like [Cobbler][2] that
"knows" when a new machine is being installed, but the process is the same.

Unfortunately, this doesn't work as well with Vagrant VMs for a couple reasons.
First, after a "vagrant destroy" and "vagrant up", the old certificate will be
gone and the client will generate a new one. This requires a manual step of
cleaning the old certificate on the server. Second, if multiple people are
using copies of the same Vagrant VM, they will have different certificates,
which won't work at all.

Even telling the Puppet server to autosign certificates doesn't help.  Not only
does this have security implications, and still requires manually cleaning old
certificates, but it also does not solve the issue of multiple users. Instead,
the best solution is to find a way to use the same certificate for every copy
of the Vagrant VM.

In creating my solution, I am indebted to [this page][3] that offers one
way to solve the problem, but I've modified things a little to get the
VM to work the first time.

1. Choose a "node name" for the VM. This does not need to be the same as
   the Vagrant host name.
1. Make sure the Puppet server has a manifest for the new node.
1. On the server, run "puppet cert generate (node-name)". This will generate
   the certificate and will also sign it (assuming the use of the built-in
   certificate authority.)
1. Copy the private key and certificate to the directory with the Vagrantfile.
   The private key is in `/etc/puppetlabs/puppet/ssl/private_keys/node-name.pem`.
   The certificate is in `/etc/puppetlabs/puppet/ssl/ca/signed/node-name.pem`.
1. Configure the Vagrantfile as follows:

```ruby
  config.vm.provision "puppet_server" do |puppet|
    puppet.puppet_node = "node-name"
    puppet.puppet_server = "puppet-server.domain"
    puppet.client_cert_path = "cert.pem"
    puppet.client_private_key_path = "key.pem"
  end
```

As long as the certificate and private key are checked in with the Vagrantfile,
anyone should now be able to grab the repository, run "vagrant up", and immediately
provision from the Puppet server.

[1]:https://www.vagrantup.com/
[2]:http://cobbler.github.io/
[3]:http://yetti.co.uk/blog/articles/shared-puppet-server-provisioning-with-vagrant.html

