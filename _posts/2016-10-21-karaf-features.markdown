---
layout: post
title: "Apache Karaf Features for OSGi Deployment"
description: ""
category: articles
tags: []
---

I've worked on multiple teams that have successfully used [Apache Karaf][1]
as an OSGi container. In addition to the usual need to understand OSGi
bundles and class resolution in the context of multiple class loaders
(which deserves at least one article all by itself), Karaf adds the
concept of a "feature" on top of OSGi bundles. While there is [detailed
documentation][2] on features, I've found that they can be confusing for new 
users, especially when they are [resolved from Maven][3], since there
seems to be so much behind the scenes magic involved.

[1]:http://karaf.apache.org/
[2]:http://karaf.apache.org/manual/latest/#_feature_and_resolver
[3]:http://karaf.apache.org/manual/latest/#_maven_url_handler

### Base OSGi

For everything that Karaf adds to OSGi, the basic unit of installation in
the OSGi container is still the bundle. A bundle is a Java Archive (JAR)
with some special information in its manifest that identifies it, gives
a version, and specifies dependencies. When an OSGi container adds a
bundle, it goes through a resolution process to make sure that the bundle's
dependencies are met (and that it does not conflict with other installed
bundles). However, that resolution process does not include any ability
to obtain any dependencies; it just checks to see if they are available
and delays or prevents the bundle from starting if a required dependency
is missing.

So it is necessary for a user of an OSGi container to identify all of
the bundles that need to be available in the container. Unfortunately,
this can get unwieldy, as the number of bundles can easily reach the
dozens or hundreds.

### Karaf Features

To address this, Karaf introduces the concept of a feature. A feature is
just a group of bundles that should all be installed together. A feature
also gets a name and a version. Features are specified in an XML format.
For example, here's part of the XML definition for the "core" feature for
[Apache Camel][4]:

[4]:http://camel.apache.org/

```xml
  <feature name='camel-core' version='2.16.0' resolver='(obr)' start-level='50'>
      <feature version='2.5.0'>xml-specs-api</feature>
      <bundle>mvn:org.apache.camel/camel-core/2.16.0</bundle>
      <bundle>mvn:org.apache.camel/camel-catalog/2.16.0</bundle>
      ...
  </feature>
```

Notice that a feature can specify a dependency on another feature as well
as listing bundles. 

### Feature Repositories

To simplify things a little bit, Karaf allows multiple features to be specified
in a single XML file. That way, a product like Camel with lots of different pieces
can have a single location where all the available features are listed, and users
can pick and choose the features they need.

This XML file is called a "feature repository". I've seen this cause confusion
with new users of Karaf, because we're used to a repository being a collection
of files on a remote system. (For example, this is how Artifactory uses the term.)

A feature repository is just a list of features wrapped in an outer XML element:

```xml
<features xmlns="http://karaf.apache.org/xmlns/features/v1.3.0">
  <feature name="feature1" version="1.0.0">
    ...
  </feature>
  <feature name="feature2" version="1.1.0">
    ...
  </feature>
</features>
```

Even though multiple features can be listed in a single feature repository, we
install using the name of the individual features inside.

### Feature Resolution

Providing a way to specify dependencies is nice, because it helps to modularize
the selection of all the bundles we need. (As one small example, we can shift to
new a version of a feature dependency and get the transitive dependencies of that
feature without having to figure out which versions have changed.)

But in order to be really useful, there needs to be a way to resolve those
dependencies. Otherwise we would still have a manual process of putting all the
bundles together so the OSGi container could resolve them. Karaf, recognizing
that Maven repositories have become very common for storing dependencies, supports
using Maven to find features repositories and bundles.

As a result, to fetch down a feature repository XML file for Apache Camel and
get access to all its features, we can just do:

```
karaf@root()> feature:repo-add mvn:org.apache.camel.karaf/apache-camel/2.18.0/xml/features
```

Now we have all the Camel features available:

```
karaf@root()> feature:list | grep camel-core
camel-core                              | 2.18.0           |          | Uninstalled | camel-2.18.0                |
```

And we can install:

```
karaf@root()> feature:install camel-core
karaf@root()> list | grep camel
52 | Active |  50 | 2.18.0  | camel-catalog
53 | Active |  50 | 2.18.0  | camel-commands-core
54 | Active |  50 | 2.18.0  | camel-core
55 | Active |  50 | 2.18.0  | camel-karaf-commands
```

What is shown in the list is the set of bundles with 'camel' in the name that
were installed as part of the feature. There is no rule that the names of
bundles or features have to match.

There is much more to know about using Karaf features, but I'm already
running long for a single article. Next I'll walk through how to configure
Karaf to load features at startup, and control how it uses Maven.

