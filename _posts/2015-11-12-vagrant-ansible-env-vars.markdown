---
layout: post
title: "Environment Variables with Ansible and Vagrant"
description: ""
category: articles
tags: []
---

One of the joys of working in a big corporate environment is the use of a [Web
proxy server][proxy] for connection to the Internet. When provisioning a
virtual machine with Vagrant and Ansible, this means that sometimes the VM has
to go through the proxy and sometimes it doesn't. I'd rather this was as
seamless a transition as possible. The solution I came up with can be extended
to other cases where different Ansible behavior is needed at different times.

[proxy]:https://en.wikipedia.org/wiki/Proxy_server#Web_proxy_servers

The first step is to configure Ansible to use the environment variable.  This
is done using the `environment` attribute on a task in a playbook.  For
example, a task to update an Ubuntu box looks like this:

```yaml 
  - name: update
    apt: upgrade=yes
    environment: proxy_env
```

The `proxy_env` variable could be declared in a `vars` section within the
Ansible playbook. But it's more flexible to pass it through from the
Vagrantfile. This means a provisioning section like this:

```ruby 
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.extra_vars = {
      proxy_env: {
        http_proxy: proxy
      }
    }
  end
```

This in turn sets the `http_proxy` to a `proxy` variable in the Vagrantfile.
The `proxy` variable is set elsewhere in the Vagrantfile, like this:

```ruby 
proxy = ENV['http_proxy'] || ""
```

So if the `http_proxy` environment variable is set on the host, it will be set
in the Vagrantfile, which will cause it to be passed to Ansible, which will
cause Ansible to set it in the VM before it runs the `apt-get update` task.

