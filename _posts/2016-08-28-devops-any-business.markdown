---
layout: post
title: "DevOps In Any Business"
description: ""
category: articles
tags: []
---

Much of my time over the past couple years has been spent working with
DevOps tools such as Ansible, Puppet, Vagrant, and Packer, rather than
the traditional programming I did previously. Since I work in the
defense industry, there are some unique challenges applying these tools
and DevOps techniques. I had a recent conversation with a colleague about
these challenges and whether it DevOps is worthwhile in our business.
Of course, I think it is, and I tried to explain some of the reasoning.

When most people think about DevOps, they envision an automated pipeline
that runs from development all the way into production. The joint
Development and Operations team maintains all of the software and the
configuration for the system in source code form. Changes run through
a test and review process, as automated as possible. Changes that get
through that process are promoted to production automatically. Ideally
production itself is automated, with idempotent configuration (a fancy
way of saying we build up servers or containers from scratch rather than
upgrading). If possible, the architecture is such that we have many
copies of each piece of the system, so we can automatically update them
on a rolling basis, with the ability to roll back if problems appear.

This description of things doesn't have much to do with the defense
industry, at least not my part of it. We generally build systems that
run not on the Internet, or even on some classified wide-area network,
but on platforms like aircraft, ships, submarines, or vehicles.
Updates to those systems happen only at scheduled times and they
undergo substantial testing commensurate with the difficulty of
installing a new version. (If you have a week-long window to install
an update before a six-month deployment, it's worth the expense of
testing to be sure that there won't be any show-stopping problems during
that six months.)

So for the majority of defense systems, there's no DevOps Pipeline from
development to production. So what good are all these DevOps tools and
techniques? There are still a number of benefits to be had:

* Controlled Configuration. Obviously one of the most important pieces of
being sure your installed system will perform is being sure it's the same
as the one you exhaustively tested. There is a process called Physical
Configuration Audit (PCA) that is used to ensure that the "as-built" system
matches the one that went through testing. This PCA can be a remarkably
detailed look down into the individual versions of every piece of installed
software. Automating the installation using DevOps can mean that an inspection
of the configuration source code plus a successful run equals a successful PCA.
* Fast Rebuilds. In order to improve the realism of a full system test, test
systems in the defense industry tend to mirror production, even to the extent of
including expensive custom equipment or simulation. A test system is expensive
enough that it is never possible to have as many as the engineering team would
like. Also, it is very common to have to support patches and bug fixes for
multiple versions in the field while also supporting testing for the next version.
It is critical to be able to get a system into the right configuration for the
next test quickly and reliably.
* Fast Installation. Software updates are never the only thing going on during
the brief maintenance window, and they typically aren't the most important.
It's often necessary to squeeze the software installation into a few hour window.
Not only does automating the installation process speed it up, it also reduces
the chance that an error will be made.
* Better Development Testing. The items above are important for the whole program,
but this one is especially critical to me as a software engineer. The cost of
test systems means that no software engineer gets as much time using one as
desired. At the same time, it's possible to buy lots of regular servers for much
less than the cost of one full test system. Historically, we added a lot of
separate configuration to our systems in order to be able to test them in a
"development" environment. In addition to being extra work, this meant we were
testing in a different environment, missing some issues that only show up on 
the real system. With tools like Vagrant, we can now use development servers to
build server and network environments that are much closer to production, and with
tools like Puppet and Ansible, we can use the exact same code to configure those
development systems that we use to install in production. The result is everyone
on the team getting a personal test system that is a close match to production.

If you're in a business where it doesn't seem like DevOps is a good solution,
hopefully one or more of these advantages sounds like something worth having.
If DevOps makes sense in cases where installation means carrying a DVD onto an
airplane, it probably makes sense lots of other places too.


