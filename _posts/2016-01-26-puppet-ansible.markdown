---
layout: post
title: "Puppet or Ansible: How to Choose?"
description: ""
category: articles
tags: []
---

TLDR: When choosing between Puppet and Ansible, understanding the design 
choices can get us past wondering which is better, so we can make an
informed decision. /TLDR

For people who are new to DevOps, it can be difficult to understand
how tools are intended to be used. The basic examples in the documentation
are intentionally simplified to show the tool, but that makes it more
difficult to envision real-world usage. Since I've spent a lot of time
recently using multiple tools, I thought it would be worth writing a little
about my experiences.

Of course, since these observations are based on what I've seen, I'm not trying
to explain exhaustively all the features of either tool. I'm not trying to
teach the syntax or terminology of either tool, since the documentation for
both tools is excellent. I use that terminology, but not in a terribly precise
way, so it shouldn't be a prerequisite to know it in order to read this
article. I'm also not intentionally trying to exclude other tools like Chef or
Salt; I just haven't used them. Finally, this is not an argument for one tool
or the other; those articles tend to be silly and in any case I'm an active
user of both tools.

While both tools have enterprise versions, I will mostly be sticking to
the capabilities of the open source versions of each tool.

## Commonality

First, it makes sense to talk about what these tools have in common. Both
are designed to automate the work involved in taking a machine (physical or
virtual) from a generic configuration to a point where it serves some
purpose. This includes installing packages, creating and updating configuration
files, managing services, and running commands.

Both tools also have the idea of idempotency, which is essential for
automation. If written correctly, an automated script should leave the system
in a consistent state, no matter how many times it is run and no matter what
else may have changed on that system. If run partially, then run again, it should
run correctly to completion just as if it was run from the beginning. This is
very difficult when writing regular shell scripts, but it is made much easier by
a tool like Puppet or Ansible that is written in terms of resources and desired
state.

Finally, in addition to the many similar functions supported by both tools, both Puppet
and Ansible support a rich template language for configuration files. Puppet's
templates are based in [Embedded Ruby (ERB)][erb], while Ansible is using [Jinja 2][jinja].
In both cases, there is support for variables, whether fed in from a common set of
files or determined dynamically.

[erb]:https://docs.puppetlabs.com/puppet/latest/reference/lang_template_erb.html
[jinja]:http://jinja.pocoo.org/docs/dev/

To illustrate the similarity, it's worth showing some code. Here's
a simplified example of putting a Hadoop configuration file into place, first with
Puppet, then Ansible:

```ruby
file { '/opt/hadoop/etc/hadoop/hdfs-site.xml':
  content => template('hadoop/hdfs-site.xml'),
  owner => 'hadoop',
  group => 'hadoop',
  mode => '0644',
}
```

```yaml
- name: hdfs config file
  template:
    dest: /opt/hadoop/etc/hadoop/hdfs-site.xml
    src: hdfs-site.xml
    owner: hadoop
    group: hadoop
    mode: 0644
```

Here's what that file would look like before being templated out using variables.
First is Puppet, then Ansible:

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://<%= @hdfs_host %>:<%= @hdfs_port %></value>
    </property>
</configuration>
```

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://{{ hdfs_host }}:{{ hdfs_port }}</value>
    </property>
</configuration>
```

Pretty intuitive in either case.

## Pull or Push?

The first major difference I think is worth discussing is where the tools are designed
to run. Puppet runs in two different modes: agent mode and "apply" mode, which is also
called "masterless". However, either way, Puppet works with an install on every machine
that it manages, and the only difference is whether the catalog is fetched on every run
from a server, or copied to every machine first.

Ansible, meanwhile, is run from one location, and connects to the machines it manages
over the network, generally using SSH. This means there is no need for an Ansible install
on managed machines, although Ansible expects Python 2.x to be installed for
most of its modules to work.

This "pull versus push" distinction can seem like a trivial difference, but it ends
up driving a lot of details in how the tools are used. With Puppet, there is additional
infrastructure involved in either setting up a server or in distributing files. On
the other hand, it is very convenient to run Puppet as a service on every machine, either
in agent mode or masterless mode, and know that the configuration will be continually
applied and kept up to date. 

Meanwhile, with Ansible, there is an assumption of reachability and of SSH access from
one or more administration machines. So there is a little bit more "wiring" to have
an automated process that continually applies configuration to ensure that nothing has
changed. At the same time, with Ansible it is much easier to pick and choose pieces
of the entire configuration to apply to specific machines at specific times, and to
run individual commands on demand on one or more remote machines.

## Getting a URL

One of the features of Puppet that new users tend to look for is downloading a tarball
or installer package from some HTTP location and using it. Puppet provides a
configurable file server that can serve files from multiple locations, so if
you're willing to host the package on the Puppet master you can use the "file"
type to deliver the file to the machine. But while there are modules in Puppet Forge
to download files from an arbitrary URL, there is no built-in support for it. Ansible,
on the other hand, has a `get_url` module to do the job.

This difference reveals an important design concept for Puppet. Puppet puts an emphasis on
knowing definitively both the source and the status of every resource in its catalog.
Connections from the agent to the master are encrypted and are authenticated both ways
using certificates. If files are transferred over this connection, their provenance is known
and it is easy to identify whether they have changed. Similarly, Puppet prefers installs from
a package repository because there is both built-in certificate checking and built-in
versioning. The concept is that most of the time, the Puppet agent will be running
in the background, and so its behavior needs to be as predictable as possible.

While Ansible certainly runs in the background in many installations, it is generally run
from one place, and there is more expectation that its behavior will be monitored by a
human being. So a `get_url` feature is not as much of a concern. This same difference
in thinking is evident in third party modules written for both tools; with Ansible correct
function is of course important but my experience is that modules are less strict in
guaranteeing they won't take any action if they have already been applied.

## Uniqueness

One more example helps to illustrate the difference in design focus I'm describing. In
Puppet, there is a strict prohibition on having two identical resources in a node's catalog.
This means, for example, that if there is a resource somewhere that specifies that the 'httpd'
service should be started and enabled, and another resource elsewhere that specifies the same
thing, a given machine cannot have both resources applied to it, or Puppet will generate an
error when it compiles the catalog to apply it to the machine. Ansible, meanwhile, does not
have this prohibition.

This example shows a difference in thinking. For Puppet, idempotency is king.
It is considered a Very Bad Thing to have a node catalog that does not
"settle"; that is, if the agent is run multiple times without any configuration
changes, it should quickly get to a point where it does not take any action at all. If
the same resource is managed from multiple places in the catalog, there is the
opportunity for them to diverge, in which case Puppet's behavior won't be
predictable. This is considered a significant error.

Ansible expects its roles and modules to be applied on demand, and potentially
selected for a specific run, so it is more relaxed about duplication. Ansible
also runs its tasks mostly in order, top to bottom, so even if you have the
undesirable situation of changing the same resource multiple times, the
behavior is still generally predictable.

## Wrap Up

So the differences described above derive from key design decisions made by
the creators of each tool, which is another reason why it would be silly to
try to determine which is "better". I generally advise people that while both
tools are excellent, if they're looking for a tool to maintain a mostly fixed
set of machines, to use Puppet, and if they're looking for a tool to configure
a set of machines that are continually being torn down and reprovisioned on
demand, to use Ansible. 

I also tell people who are using Vagrant for development and test that while
support for both tools is excellent, in my opinion Ansible has a slightly
easier learning curve, mostly because of the relaxed rules I mentioned above.
For that reason, I would use Puppet with Vagrant when planning to use Puppet in
production, but would use Ansible otherwise.

In any case, having built and set up many physical and virtual machines in my
day, I would choose either tool every time rather than go back to the days
of manual commands, kickstart files, and shell scripts.

