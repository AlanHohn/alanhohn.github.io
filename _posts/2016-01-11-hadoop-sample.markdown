---
layout: post
title: "Hadoop Sample Application with Vagrant and Ansible"
description: ""
category: articles
tags: []
---

In a [previous article][first] I showed an [example][gh] of
using Vagrant and Ansible to deploy a pseudo-distributed Hadoop
into a single virtual machine. The idea was, while Hadoop has
support for running directly from a regular Java program or IDE,
we can better learn how it works by running in a more realistic
environment. We can also make something that's useful for testing
new applications at small scale.

The last article got a little long and ended a little abruptly, so
I wanted to come back and discuss actually running a Hadoop application
in the virtual machine. I'll use the hoary example of the word count job.

## Hadoop Services

First, let's look at a couple of the Hadoop services we started. Both
the HDFS Name Node and the YARN Resource Manager provide web interfaces.
The ports from those web interfaces are forwarded from the virtual
machine to the host, so once Hadoop is up and running (via `vagrant up`,
with the Ansible provisioning completed successfully), we can visit
http://localhost:50070 to see HDFS status and http://localhost:8088 to
see job status from the host running the VM.

A side note: Vagrant only provisions the VM the first time it is
started. However, because we set up the Hadoop components as systemd
services, they will start automatically without having to run the
Ansible provisioner again. One good reason to do it this way.

The HDFS status should look something like this:

<img src="/post-images/hdfs.png" style="max-width:100%;max-height:375px;"/>

YARN status should look something like this (before any jobs are run):

<img src="/post-images/yarn1.png" style="max-width:100%;max-height:375px;"/>

## Building the Application

To run the sample application, we first need to build it. To do this, we
will SSH into the VM. Vagrant makes this very easy; just run `vagrant ssh`
from the directory with the `Vagrantfile`. This works because Vagrant has
already forwarded port 22 from the VM to a local port, recorded which port
to use, and placed an SSH key into the VM's list of authorized keys for
the "vagrant" user.

The sample application is available in the VM under `/vagrant/wordcount`,
because Vagrant automatically shares the directory with the Vagrantfile
into the VM as `/vagrant`.

So here's the full command to build:

```shell
vagrant ssh
cd /vagrant/wordcount
./build.sh
```

This will compile the source code in `src` and create `wc.jar`. Running
the build from inside the VM allows us to have the necessary Hadoop JARs
from our installed distribution on the classpath. Of course, for a real
application we would use a build tool like Maven or Gradle and specify
a dependency on the right version of Hadoop. 

## Running the Application

To run the application, we first need to provide it with an input file.
To do this, we need to upload the input file into HDFS. This is one important
difference between running in a real cluster, even a pseudo-distributed one,
and running in a regular Java application. We can then run the application.
Once the application is finished, we can grab the output file that was written
to HDFS.

Run the following from `/vagrant/wordcount` inside the VM:

```shell
./ul.sh
./run.sh
./out.sh
```

The `ul.sh` file looks like this:

```shell
#!/bin/sh
/opt/hadoop/bin/hadoop fs -mkdir /tmp/wordcount
/opt/hadoop/bin/hadoop fs -mkdir /tmp/wordcount/input
/opt/hadoop/bin/hadoop fs -put -f joyce.txt /tmp/wordcount/input
```

Once we've performed the upload, we can visit the HDFS Name Node at
http://localhost:50070, click "Browse the file system" under Utilities, 
and see the file we've uploaded.

The `run.sh` file looks like this:

```shell
#!/bin/bash
/opt/hadoop/bin/hadoop fs -rm -r -f /tmp/wordcount/output
/opt/hadoop/bin/hadoop jar wc.jar wordcount/WordCount /tmp/wordcount/input /tmp/wordcount/output
```

Note that we delete the output directory before running the job, to
remove any old output files. The directory is automatically created
by our application master.

The `out.sh` file looks like this:

```shell
#!/bin/sh
/opt/hadoop/bin/hadoop fs -cat /tmp/wordcount/output/part* 
```

This just prints any output files found in the output directory we specified.

## The Sample Application

While I'm not intending to give an "Introduction to Hadoop" in this article, since
there are better versions out there, I do want to mention a few things about 
this sample application.

There are three Java source files in the sample application: `WordCount.java`,
`TokenizerMapper.java`, and `IntSumReducer.java`. They are lifted from the Hadoop
examples at the Apache website, but I've broken them into separate files as I think
it makes things easier to comprehend.

I won't include the whole source code in this article, but I'll describe a few points
of interest (at least to me):

* `WordCount` has a main method. This is what makes it easy to run a Hadoop job
  in a single Java process. When running in our cluster, if you watch the Java processes 
  while the application is running, you can see a Java process get spawned with a main 
  method of `RunJar` and `wordcount/WordCount` passed as a parameter. So when running
  in a cluster, Hadoop is just calling our main method as an ordinary static method.
* Within the main method, we create an instance of a Map Reduce `Job` class, configure
  it, and call `job.waitForCompletion()`. This approach uses Hadoop's Map Reduce API
  even though we are using YARN.  As I mentioned in the [previous article][first], with
  YARN we can do many different kinds of applications; YARN allocates a process for an
  "Application Master" that then requests whatever other processes it needs. In this
  case, there is an application master for Map Reduce (called `MRAppMaster`) that bridges
  the old Map Reduce API to the new YARN approach.
* The basic flow of the application works like this: The application master looks at
  the input directory in HDFS, figures out that there is only one file and that the
  file is short enough for one "split", so it only needs one mapper. It asks YARN to
  allocate that mapper. YARN spins up a new Java process (main class `YarnChild`) that
  feeds the input file from HDFS through the mapper (class `TokenizerMapper` from our
  source code). The application master then goes through a similar process to kick off
  a process for the reducer.
* The combiner and the reducer use the same class in our example, but have very different
  functions that are important in a full-scale example. The combiner runs on the keys
  output by the map, within the same map process, before the keys are written to disk.
  It exists to shrink the load on HDFS for intermediate data that is passed from the mapper(s)
  to the reducer(s). The combiner is not guaranteed to run; Hadoop only runs it if it finds
  its in-memory output buffer is filling up (a.k.a. "spilling") multiple times.
* The reducer, meanwhile, will definitely run. All outputs from the mapper with the same
  key are guaranteed to go to the same reducer; Hadoop sorts the intermediate data as needed
  to make this happen.

## Viewing Status and Logs

Once we have run the application, it will show up in the YARN application list at
http://localhost:8088:

<img src="/post-images/yarn2.png" style="max-width:100%;max-height:375px;"/>

The YARN Resource Manager allows us to see detailed status for each job and to click
through to logs. Unfortunately, one downside of running in a VM and forwarding ports is that 
things get a little confused with URLs. The VM has a host name of "hadoop", so it
uses that hostname in some of the links. As a result, we can't click through to the logs.

For this reason, when we set up Hadoop, we also set up a history server. This acts as a proxy
for logs of completed jobs. The history server is also forwarded to the host so we can visit
it at http://localhost:19888. We will see the same list of completed jobs, and can see the
logs:

<img src="/post-images/hadoop-history.png" style="max-width:100%;max-height:375px;"/>

There are some clever tricks we can do to configure YARN to make the right URLs. We can
also use a proxy server to get access to the logs (which is important on a real cluster,
since the logs will be distributed across multiple machines). But for our simple example
the history server works well enough.

Once we are all done, we can shut down the VM by running `vagrant halt` from the host,
or delete it with `vagrant destroy`.

Hopefully this pair of articles has been valuable for showing a bit of how a
Hadoop cluster runs and how to set one up easily. Any questions, please comment;
any suggestions for the [repository][gh], also please comment or open an issue on
GitHub.

[first]:https://dzone.com/articles/quick-hadoop-startup-in-a-virtual-environment
[gh]:https://github.com/AlanHohn/single-node-hadoop

