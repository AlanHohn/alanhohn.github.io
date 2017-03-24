---
layout: post
title: "Quick Hadoop Startup in a Virtual Environment"
description: ""
category: articles
tags: []
---

*tldr*A fully-featured Hadoop environment has a number of pieces that
need to be integrated. Vagrant and Ansible are just the tools to make
things easier.*/tldr*

When getting started with Hadoop, it is useful to have a test environment
to quickly try out programs on a small scale before submitting them to a real
cluster (or before setting that cluster up). There are
[instructions][standalone-docs] on the Hadoop website that describe running
Hadoop as a single Java process. However, I've found that running this way
hides a lot of how Hadoop really works for large-scale applications, which
can slow understanding of what kinds of problems need to be solved to make
an implementation work and be performant in a real cluster.

The same [page][standalone-docs] also describes a pseudo-distributed
mode. Don't let the "pseudo" throw you off; when running in this mode, the
exact same Hadoop processes are running, in the same way as a full cluster.
The only thing that's missing, besides the number of parallel resources, is
the setup for High Availability. That's important for a real cluster, but it
doesn't affect the way Hadoop jobs are written. So in my view,
pseudo-distributed mode makes a great test environment.

The instructions for pseudo-distributed mode still include a lot of files to
edit and commands to run. To make it easier to get up and running, I've created
a [virtual environment][github] using [Vagrant][] and [Ansible][] that will do
the installation automatically.

Vagrant and Ansible have good support and good docs for running on multiple platforms,
so I'll assume we're starting in an environment where they are both available
(as well as some virtualization software; Vagrant defaults to VirtualBox). 
I'll focus first on the Hadoop components that are being installed and set up,
then show how the automated installation and setup works.

## Hadoop Components

### Hadoop Distributed File System

All of the Hadoop components we'll be using come in the standard tarball. First,
we need to get the Hadoop Distributed File System (HDFS) up and running. HDFS provides
the storage (both input and output) for Hadoop jobs; most Hadoop jobs start by reading
one or more HDFS files and finish by leaving one or more HDFS files behind.

HDFS is divided into two main components, Name Node and Data Node. (There is a third
component, the Journal Manager, that is used in High Availability setups.) The Name Node
manages the HDFS equivalent of a file allocation table: for every file written to HDFS,
it keeps track of where the pieces are located. Like a regular file system, HDFS divides
the file up into "blocks"; however, the blocks are generally distributed across the
network, and are generally replicated both for improved performance and to protect against
drive failure. The amount of replication is configurable per-file; the standard default is 3.

The HDFS Data Nodes handle storing and retrieving blocks. They are provided with storage,
typically on top of some existing local file system (e.g. EXT3 or XFS). The Data Nodes
register themselves with the Name Node, which keeps track of how much total space is available
and the health of each Data Node. This allows the Name Node to detect failure of a Data Node and
to make additional copies of the blocks it holds to keep up the configured replication factor.

The Data Nodes also provide direct access to blocks to HDFS clients. While a client must go
first to the Name Node to determine which Data Nodes have blocks of interest, the client can
then read from or write to those blocks by going directly to the Data Nodes. This prevents the
Name Node from becoming a bottleneck.

In a real cluster there is one Name Node (two when running High Availability) and as many
Data Nodes as there are servers. For this pseudo-distributed installation, we still need
both a Name Node and a Data Node, but they will be run in the same virtual
machine.

### Yet Another Resource Negotiator

Now that we have a distributed file system, we can set up something to schedule and run
the actual jobs. For this example, I am setting up the "next generation" job scheduler [YARN][].
It's still called "NextGen" in the docs, but it has been around for quite a while now in
Hadoop terms.

Like HDFS, YARN needs two components, in this case a Resource Manager and a
Node Manager.  (It has other components: a History Server that stores job
history; and a Proxy Server, that provides a network proxy for viewing
application status and logs from outside the cluster.) 

The Resource Manager accepts applications, schedules them, and tracks their
status. The Node Manager registers with the Resource Manager and provides its
local CPU and memory for scheduling. For a real cluster, there is one Resource
Manager (two for High Availability) and as many Node Managers as there are
servers. For this example, we will run a Resource Manager and a single
Node Manager in our single virtual machine.

### Hadoop: Not Just for Map Reduce

As an aside, while YARN continues to explicitly support "map reduce" jobs,
which have traditionally been popular on Hadoop, it provides a more
general-purpose application scheduling framework. Applications provide an
"Application Master", which is scheduled onto a node and runs for the life of
the application. The application master requests resources for all of its
components, and is notified as they complete. 

When writing a standard MapReduce job, we don't need to create an application
master, as there is a standard MapReduce application master that already exists.
But if we write our own application master, we can create an application with
any kinds of components we choose, wired together in any order we need. 

In a future article I will discuss Spark running on top of YARN; Spark does
this by providing its own application master. When doing streaming, this
application master can request resources and start Spark components
ahead-of-time, allowing Spark to handle events with much lower latency than is
possible when running Hadoop jobs in the more typical batch processing mode.

## Up and Running with Hadoop

First, as mentioned above, install Vagrant, Ansible, and virtualization software.
The existing Vagrant configuration assumes VirtualBox but it is easy to change
to another (e.g. libvirt) as long as a Vagrant box is available.

Next, clone the [repository][github]:

```
git clone git@github.com:AlanHohn/single-node-hadoop.git
```

Now, change into the `single-node-hadoop` directory and run `vagrant up`. This
will download the Vagrant box if necessary and create a new virtual machine. It
will then run Ansible to provision the box. 

Here is the Vagrantfile that is used in this case:

```ruby
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

---
layout: post
title: "Vagrantfile API/syntax version. Don't touch unless you know what you're doing!"
description: ""
category: articles
tags: []
---
VAGRANTFILE_API_VERSION = "2"

proxy = ENV['http_proxy'] || ""
hadoopver = ENV['hadoop_version'] || "2.6.3"
sparkver = ENV['spark_version'] || "1.5.2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/wily64"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 4096
    vb.cpus = 4
    # Needed for multiple CPUs
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.extra_vars = {
      proxy_env: {
        http_proxy: proxy
      },
      hadoop_version: hadoopver,
      spark_version: sparkver
    }
  end

  config.vm.network "forwarded_port", guest: 50070, host: 50070
  config.vm.network "forwarded_port", guest: 8088, host: 8088
  config.vm.network "forwarded_port", guest: 19888, host: 19888

end
```

There are a couple important points here. First, the virtual machine
is configured to use 4 GB of RAM and 4 CPUs. This helps things move
along faster, but it is possible to scale down a bit (e.g. 2 GB RAM
and 1-2 CPUs) if needed. Second, this Vagrant configuration passes
through a few environment variables (with default values) as Ansible
variables, including any HTTP proxy. The version of Hadoop to
install and run is passed through as well; this makes it easier to try
out different versions of Hadoop (even in the same VM, as will
be discussed later). Finally, note that there are a few ports forwarded
through to the host. The most important one is 8088, which is used to
view the status of submitted applications. The others are for the
HDFS status page (50070) and the history server (19888).

When Vagrant runs Ansible, it configures Ansible to SSH into the VM
as the "vagrant" user using the SSH key Vagrant has configured. Ansible
can then use "sudo" to perform actions as root. Ansible reads a YAML file
called a playbook to determine what actions to take to setup the machine.
I'll provide the YAML file in stages to discuss what is happening; the
whole thing is available in the [repository][github].

```yaml
---
- hosts: all
  sudo: yes
```

These first lines tell Ansible what hosts to apply the upcoming list of tasks
(there is only one host in this case), and to use sudo for the upcoming list of
tasks.

```yaml
  tasks:
  - name: hostname file
    lineinfile: dest=/etc/hostname regexp=".*" line="hadoop"
  - name: set hostname
    command: hostnamectl set-hostname hadoop
  - name: update
    apt: upgrade=yes
    environment: proxy_env
```

These are setup lines that I generally include in all Ubuntu VMs configured
with Vagrant. The hostname items work around [an issue][issue] in some versions
of Vagrant where Ubuntu hostnames could not be set directly in the Vagrantfile.
This issue appears to be fixed but this workaround is backwards-compatible with
earlier Vagrant versions. The third task performs any updates needed to get our
new Ubuntu box up to date.

```yaml
  - name: Install packages
    apt: pkg={{item}} state=installed
    environment: proxy_env
    with_items:
        - openjdk-8-jdk
```

This task makes sure Java is installed. The form of this task, with a list of
items, can be used anywhere in Ansible and is convenient when applying the same
action multiple times.

```yaml
  - name: download hadoop
    get_url:
      url: http://mirrors.ibiblio.org/apache/hadoop/common/hadoop-{{hadoop_version}}/hadoop-{{hadoop_version}}.tar.gz
      dest: /opt/hadoop-{{hadoop_version}}.tar.gz
    environment: proxy_env
  - name: unpack hadoop
    unarchive: 
      src: /opt/hadoop-{{hadoop_version}}.tar.gz
      dest: /opt
      creates: /opt/hadoop-{{hadoop_version}}
      copy: no 
      owner: vagrant 
      group: vagrant
```

With these tasks, we download the Hadoop tarball to a location in the VM and
untar it. The way Apache does their mirrors it was easiest just to choose one.
Note that the `hadoop_version` variable is the one that comes in from the
Vagrantfile (or ultimately from the environment on the host). Also note that because
we are using "sudo" in our Ansible file, we need to make sure we get the right
ownership on the extracted files. The `copy: no` is also important; it tells
Ansible that the tarball it is extracting comes from inside the VM, not from
the host.

Since Ansible 2.0, the `unarchive` task understands URLs, so you can do this
in one step. But this is backwards compatible.

```yaml
  - name: hadoop current version link
    file: path=/opt/hadoop src=/opt/hadoop-{{hadoop_version}} state=link owner=vagrant group=vagrant
    notify: restart services
```

This is the step that allows us to try out different versions of Hadoop, switching
between them easily. This task ensures that there is a softlink at `/opt/hadoop` pointing
to the version we have selected. The remaining steps can use this location for configuration
files and starting services. If we set the `hadoop_version` environment variable and run
`vagrant provision`, Ansible will install the new version and update the pointer. It will
then go through the rest of the tasks, ultimately restarting the Hadoop services in the VM.

However, if we re-run `vagrant provision` without updating `hadoop_version`, Ansible is smart
enough to notice that the link is already in the right place and realize that nothing has
changed, so the services won't be affected. Also, because of the way we set up the `get_url`
and `unarchive` tasks, once a particular version of Hadoop has been downloaded, it will stick
around, so we can switch back to it just by updating the softlink and restarting Hadoop services.
The term typically used for this kind of task is "idempotent", which means that it is safe to
run multiple times and nothing changes unless it is necessary. This is an important goal for
automated deployment because it greatly improves reliability.

```yaml
  - name: hadoop config files
    copy: dest=/opt/hadoop/etc/hadoop/{{item}} src=files/{{item}} mode=0644 owner=vagrant group=vagrant
    with_items:
        - hadoop-env.sh
        - core-site.xml
        - hdfs-site.xml
        - mapred-site.xml
        - yarn-site.xml
    notify: restart services
```

We now put the configuration files into the right place. I pretty much copied these from the
[docs][standalone-docs] so I won't spend a lot of time discussing them. The change to
`hadoop-env.sh` is needed to provide Hadoop with `JAVA_HOME` for our Ubuntu install. 

```yaml
  - name: hadoop format namenode
    command: /opt/hadoop/bin/hdfs namenode -format 
    become: yes
    become_user: vagrant
    args:
      creates: /opt/hadoop/dfs
```

Before we can run the HDFS Name Node, we need to run a format command. This initializes its
local storage where it maintains information about files in HDFS and where their blocks
are stored. We use the Ansible `command` module; note that the syntax is a little strange
because the command module has to be able to accept parameters for the command as well as
arguments for the module itself. Also note that we make sure to tell the command module
about the directory that this command creates; this allows the task to be idempotent,
which is needed in this case because the command will fail if we try to run it twice.

```yaml
  - name: service files
    copy: dest=/lib/systemd/system/{{item}} src=files/{{item}} mode=0644 owner=root group=root
    with_items:
        - hdfs-namenode.service
        - hdfs-datanode.service
        - yarn-resourcemanager.service
        - yarn-nodemanager.service
        - yarn-proxyserver.service
        - yarn-historyserver.service
    notify: reload systemd
  - meta: flush_handlers
```

We now provide systemd with the service files it needs to make proper
services. I prefer to start things this way when automating them, as
it means we can configure them to automatically start on reboot, so once
the VM is provisioned, it can be stopped with `vagrant halt` and restarted
with `vagrant up` without having to run `vagrant provision` again. It also
makes it easier to stop / start services without having to worry about having 
multiple copies running. Finally, it makes for a more realistic test environment
(e.g. avoiding surprising differences caused by the environment in which the
process runs). It is slightly more painful when the services aren't
working, since we have to query systemd or look in the logs, but its
benefits outweigh this hassle. 

The `notify: reload systemd` is important because systemd keeps its own cache
of service configuration, so when we change the files in the directory we have
to tell systemd to pick up the new ones. We need to do this immediately, before
we try to start the new services, so we include `meta: flush_handlers`, which
makes Ansible run any pending handlers immediately.

Note that this location for systemd service files is specific to Ubuntu; on
RHEL they are kept in `/usr/lib/systemd` instead.

```yaml
  - name: services
    service: name={{item}} state=started enabled=yes
    with_items:
        - hdfs-namenode
        - hdfs-datanode
        - yarn-resourcemanager
        - yarn-nodemanager
        - yarn-proxyserver
        - yarn-historyserver
```

This next task tells Ansible to make sure that the various services are running.
In addition to starting Hadoop for the first time, this means that if our Hadoop 
services fail for any reason, we can restart them using `vagrant provision`.

```yaml
  handlers:
  - name: reload systemd
    command: systemctl daemon-reload
  - name: restart services
    service: name={{item}} state=restarted
    with_items:
        - hdfs-namenode
        - hdfs-datanode
        - yarn-resourcemanager
        - yarn-nodemanager
        - yarn-proxyserver
        - yarn-historyserver
```

Finally, we provide handlers to reload systemd and to restart services. The
handler to restart services is nice because it allows us to change Hadoop
configuration files in their location on the host, re-run `vagrant provision`,
and have the service restarted with the configuration change. This is a very
important technique for automated deployment, since once Ansible has taken
control of a configuration file we don't want to modify it directly on the 
target machine, as our changes will be lost the next time Ansible runs. 

This single node Hadoop example also includes a basic word count example from
the Hadoop documentation, so we can test that our cluster is working. I'll need
to save a discussion of that example for the next article.

[Hadoop]:https://hadoop.apache.org
[standalone-docs]:https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html
[github]:https://github.com/AlanHohn/single-node-hadoop
[Vagrant]:https://www.vagrantup.com/
[Ansible]:http://www.ansible.com/
[YARN]:https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html
[issue]:https://github.com/mitchellh/vagrant/issues/5673

