---
layout: post
title: "Karaf Features at Startup"
description: ""
category: articles
tags: []
---

In a [previous article][1] I provided an introduction to how [Apache Karaf][2]
uses "features" to simplify adding OSGi bundles to a container, including
handling dependencies.

[1]:https://dzone.com/articles/apache-karaf-features-for-osgi-deployment
[2]:http://karaf.apache.org/

As discussed in that article, Karaf has its own XML format for a "feature
repository", an XML file that lists one or more features. Each feature
lists features or bundles that it relies on, with support for versioning.
The whole thing works because Karaf can retrieve both the feature repository
XML files and the OSGi bundles from a variety of sources, including Maven.

Last time I showed a single command to add a feature repository XML file
from Maven, and then a command to install a feature. However, when using
Karaf in production we of course need to have it load the right features
on startup.

### Karaf Features Config

To do this, we will update some of the configuration files in the Karaf
`etc/` directory. The first file of interest is `org.apache.karaf.features.cfg`.
This file contains two settings of interest: `featuresRepositories` and
`featuresBoot`.

The `featuresRepositories` entry is a list of URLs where feature repository
files can be retrieved. As we said last time, Karaf uses the term "feature
repository" to refer to the XML file that lists one or more features. This
"feature repository" XML file can itself live on a web server, on the file
system, or (most commonly) in a Maven repository. (Little bit of overlap
in the names to get used to here.)

To add Apache Camel to the list of features repositories that Karaf knows
about at startup, we just add another item to the list:

```
featuresRepositories = \
    mvn:org.apache.karaf.features/spring/4.0.7/xml/features, \
    mvn:org.apache.karaf.features/framework/4.0.7/xml/features, \
    mvn:org.apache.karaf.features/enterprise/4.0.7/xml/features, \
    mvn:org.apache.karaf.features/standard/4.0.7/xml/features, \
    mvn:org.apache.camel.karaf/apache-camel/2.18.0/xml/features
```

The last line is the only new one (along with the backslash on the previous
line to keep this a valid Java properties file). This Maven coordinate
tells Karaf where to go to get the features repository XML file for Camel.
Karaf builds in enough Maven support to be able to find this file in a
configured list of Maven repositories.

By itself, this won't make Karaf install anything; we also need to add
one or more features to `featuresBoot`. This is a comma-separated list
of features to install at startup; all of the bundles in those features
will be started (if possible).

### Find Those Dependent Features

If you look at a Karaf feature repository XML file, you will notice that
it lists Maven coordinates for bundles but not for any dependent features.
Dependent features are just listed by name. 

However, it is possible for one feature file to specify additional
feature repository coordinates for dependent features. For example, the
Camel feature repository XML file has these lines:

```xml
  <repository>mvn:org.apache.cxf.karaf/apache-cxf/3.1.7/xml/features</repository>
  <repository>mvn:org.apache.jclouds.karaf/jclouds-karaf/1.9.2/xml/features</repository>
  <repository>mvn:org.ops4j.pax.cdi/pax-cdi-features/1.0.0.RC1/xml/features</repository>
```

These repositories are added immediately when the feature repository listing
them is added; Karaf doesn't wait until features are installed. Not only that, but
Karaf immediately goes to fetch the feature repository XML files to find out what
features are available.

### Potential Confusion

Over time, I've had to work with feature repository XML files that weren't quite as
friendly or complete as desired. In particular, they might have listed dependent
features without also listing the repository where those features could be found.

To deal with this, we've had to add features repositories to the `featuresRepositories`
list in the Karaf config, so that Karaf winds up with a comprehensive list of all
the places it needs to look for features. But, and this is the confusing part, it
isn't necessary to add them to `featuresBoot` as well, because they'll get pulled
in as a dependency. This has been a big source of confusion to new people, because
they'll see coordinates for a feature XML file in the list and not see it in the
list of features to start at boot time, and think this is an error.

### Configuring Maven

There's one more file that is critically important to configure correctly in order
for Karaf to find and install features and bundles: `org.ops4j.pax.url.mvn.cfg`.
As the name implies, this file configures [Pax URL][3] from OPS4J to correctly
handle Maven URLs.

[3]:https://ops4j1.jira.com/wiki/display/paxurl/Pax+URL

Pax URL has an interesting relationship with any installed Maven. It does not
require Apache Maven to be installed; the necessary code is embedded within the
Karaf distribution. However, by default it does use the per-user Maven settings
file in `$HOME/.m2/settings.xml` and the per-user local repository in
`$HOME/.m2/repository`. 

But by default, it does not implicitly use any of the "fallback" Maven
repositories that are automatically available in a normal Maven installation
(like Maven Central). Instead, it has its own "built-in" list of repositories
However, the configuration file does not use this "built-in" list of
repositories that are built into the code; it uses only the list of
repositories in the configuration file. As it happens, this list includes Maven
Central, so this difference may not seem important. But it obviously becomes
very significant if we go changing the `org.ops4j.pax.url.mvn.cfg` config file.

To make it even worse, the config file also lists `defaultRepositories` in the
form of directories within the Karaf installation that override even the local
Maven repository in `$HOME/.m2`.

That was confusing, so to sum that up, we have this list:

* Global settings file from a Maven installation: Not used
* Maven settings.xml in `$HOME/.m2`: Used by default
* Default repositories in Karaf distribution: Used by default; don't mess with this
* Built-in repositories: Available but overridden by configuration
* Configuration in `org.ops4j.pax.url.mvn.cfg`: Always used, may specify whether
  others are used.

At the end of the day, when working in an Internet-available environment, I find
it easiest to just ignore most of that and tack on new repositories to the end
of the list. In Internet-denied environments, of course we can just replace the
list with an available Maven repository.

I've written a lot for one article again, but I still would like to cover some
best practices for making these Karaf feature repository XML files, ideally with
a simple example.

