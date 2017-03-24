---
layout: post
title: "Docker and User Namespaces by Trial and Error"
description: ""
category: articles
tags: []
---

Included in the recent [release of Docker 1.10][newdoc] is a feature
destined to become more important with future releases: support for
user namespaces. At the moment, it's not enabled in a fresh install,
and it still feels a little bleeding edge compared to more established
Docker features, but it does work and is worth getting to know.

[newdoc]:https://blog.docker.com/2016/02/docker-1-10/

I spent a little time getting familiar; by no means enough to claim
expertise, but enough to make it work. Hopefully the fact that
it's new to me will make it easier for me to explain to others, since
I hit some obstacles on the way to getting it to work.

I'm assuming that if you're reading this, you may have seen one of
the [excellent][1] [pages][2] on user namespaces in Docker. Very briefly,
the idea is to map the "root" user in the container to be some normal
(unprivileged) user on the host system. This allows us to prevent
containers from modifying files on the host, even with mapped volumes,
which allows closing [other security holes][sec] that allow
containers to improperly obtain privileges on the host.

[1]:https://blog.docker.com/2016/02/docker-engine-1-10-security/
[2]:https://github.com/docker/docker/blob/master/docs/reference/commandline/daemon.md#daemon-user-namespace-options
[sec]:http://reventlov.com/advisories/using-the-docker-command-to-root-the-host

I started with a fresh install of Ubuntu Wily; however, despite this
being the latest, it doesn't have a very new Docker in the default set
of packages. So we need to move on to using Docker's own repository.
In my Ansible playbook, this looks like this:

```yaml
  - name: docker apt key
    apt_key: keyserver=keyserver.ubuntu.com id=F76221572C52609D
  - name: install docker repo
    apt_repository: repo='deb http://apt.dockerproject.org/repo ubuntu-wily main'
  - name: Install packages
    apt: pkg=docker-engine state=installed update_cache=yes
```

Note that the package name changed recently from 'docker.io' to 
'docker-engine'. 

With that done, and the Docker service started, we now have:

```
root@penguin64:~# docker -v
Docker version 1.10.1, build 9e83765
```

However, this installation does not have user namespaces enabled.
To enable it, we need to pass an argument to the Docker daemon.
Here's the first place where there is a potential for confusion. On
Ubuntu, there is a file `/etc/default/docker` with some content;
however, this file is not used now that Docker has switched over to
running services with [systemd][]. Instead, the expected way to
handle it is to create a "drop-in". Systemd takes configuration
files from /lib/systemd, but it also looks in /etc/systemd for
files that override the defaults. This is a nice feature in that
it avoids the issue of having a package manager not be able to
update a file because it's been customized.

[systemd]:https://www.freedesktop.org/wiki/Software/systemd/

The convention with systemd is to create an override directory for
each service. Since the Docker configuration file lives in
`/lib/systemd/system/docker.service`, this means a directory called
`/etc/systemd/system/docker.service.d`. All `*.conf` files in this
directory will override anything in the default configuration file.

```shell
---
layout: post
title: "mkdir -p /etc/systemd/system/docker.service.d"
description: ""
category: articles
tags: []
---
---
layout: post
title: "cat >/etc/systemd/system/docker.service.d/userns.conf <<EOD"
description: ""
category: articles
tags: []
---
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --userns-remap=default
EOD
---
layout: post
title: ""
description: ""
category: articles
tags: []
---
```

The first `ExecStart=` clears out the default value, since systemd
supports multiple processes in a single service for some service
types. The second replaces the default value with the command we
want. Getting that command right was itself a little painful, since
`docker daemon --help` in 1.10 isn't terribly verbose when it comes to
identifying what kind of parameter is expected for `--userns-remap`.
(That documentation issue has been fixed in latest master.)

Of course, there are other options besides default, but the default
worked for my purposes; it remaps into the 'nobody' user on the
host.

With this file in place, we need to reload systemd, then docker:

```shell
---
layout: post
title: "systemctl daemon-reload"
description: ""
category: articles
tags: []
---
---
layout: post
title: "systemctl restart docker"
description: ""
category: articles
tags: []
---
```

Here's where I hit the second obstacle. I tried running a Docker image,
only to find out that I had no images. When switching to a separate
namespace, Docker creates a directory under `/var/lib/docker` for
the namespace:

```
vagrant@penguin64:~$ sudo ls -l /var/lib/docker
total 32
drwx------ 9 296608 296608 4096 Feb 23 00:59 296608.296608
drwx------ 2 root   root   4096 Feb 12 21:09 containers
drwx------ 5 root   root   4096 Feb 23 00:42 devicemapper
drwx------ 3 root   root   4096 Feb 12 21:09 image
drwxr-x--- 3 root   root   4096 Feb 12 21:09 network
drwx------ 2 root   root   4096 Feb 23 00:43 tmp
drwx------ 2 root   root   4096 Feb 12 21:09 trust
drwx------ 2 root   root   4096 Feb 12 21:09 volumes
```

No big deal, just had to pull the image I wanted again.

Finally, we can get down to starting a container and seeing
the effect of namespaces:

```
vagrant@penguin64:~$ docker run -it --rm centos /bin/bash
[root@65fd7566b552 /]# whoami
root
```

So inside the container, it still thinks of itself as root.
But root inside the container is not root on the host system:

```
vagrant@penguin64:~$ docker run -it --rm -v /opt:/opt centos /bin/bash
[root@690e37988416 /]# ls -ld /opt
drwxr-xr-x 2 65534 65534 4096 Nov  6 21:38 /opt
[root@690e37988416 /]# touch /opt/file1
touch: cannot touch '/opt/file1': Permission denied
```

And this means that it is no longer possible to use a [SUID trick][sec]
to root the host.

Right now, this feature is limited so that all containers on a host
share the same namespace. On the roadmap is supporting per-container
namespaces, allowing finer control over what each container can access
on the host.

