---
layout: post
title: "Karaf Features and OSGi Services: A Bundle"
description: ""
category: articles
tags: []
---

After finishing a [pair][1] of [articles][2] last week on Karaf features, I 
felt that I had done a poor job of explaining the context in which all of
this bundling and featurizing was taking place. Instead I pretty much started
in the middle, assuming the existence of OSGi bundles with proper manifests,
all snug in their Maven repositories.

[1]:https://dzone.com/articles/apache-karaf-features-for-osgi-deployment
[2]:https://dzone.com/articles/karaf-features-at-startup

So I'm going to correct that and at the same time illustrate another cool
OSGi technology: declarative services. To do that will take some time and
will require help from a [detailed example][3].

[3]:https://github.com/AlanHohn/karaf-greeter

### OSGi Bundles Of Moderate Joy

To start with, we need to know how to make OSGi bundles. And before we
bother doing that, it would help to discuss what a bundle is.

OSGi is an approach to building modular applications. The idea is that
each module is very specific about its unique name, its version, what
it requires from other modules, and what it provides that other modules
are allowed to use. In Java, each of these modules is packaged into a
JAR file with some additional information in the `META-INF/MANIFEST.MF`
file. This additional information includes imports and exports in the
form of Java packages. A properly packaged JAR file with the right
manifest content is known as an OSGi bundle. Here is a simple example
manifest, as packed inside the JAR at build time:

```
Manifest-Version: 1.0
Bnd-LastModified: 1477440189494
Build-Jdk: 1.8.0_91
Built-By: ahohn
Bundle-ManifestVersion: 2
Bundle-Name: Greeter Interfaces
Bundle-SymbolicName: org.anvard.karaf.greeter.interfaces
Bundle-Version: 1.0.0.SNAPSHOT
Created-By: Apache Maven Bundle Plugin
Export-Package: org.anvard.karaf.greeter.api;version="1.0.0.SNAPSHOT"
Tool: Bnd-1.50.0
```

There are a couple things to note here:

* The `Bundle-SymbolicName` is important and needs to be unique.
* We can specify a `Bundle-Version` as well as a version for any
  packages we export. Next time we'll see a bundle that imports this
  package; the version is important.

We could create this manifest content ourselves, whether we run the
`jar` command directly or use a build tool like the Maven JAR plugin.
But this is a lot of manual effort and involves a lot of redundancies,
especially in a Maven project where we are already specifying the
artifact name, version, and dependencies. Fortunately, OSGi expert
[Peter Kriens][4] created a tool called [bnd][5]. The bnd tool had the
ability to scan Java code to identify package imports from outside a
module, and to use a much cleaner configuration file as the source to
generate the right OSGi content for `META-INF/MANIFEST.MF`.

[4]:http://aqute.biz/
[5]:http://bnd.bndtools.org/

Taking this one step further is the [maven-bundle-plugin][6]. Instead
of using a separate configuration file, this plugin allows specifying
the needed information in the Maven POM. It also leverages the Maven
dependencies to figure out what versions of package imports are required.
To get the manifest shown above, we need this configuration in our POM
file:

[6]:http://felix.apache.org/documentation/subprojects/apache-felix-maven-bundle-plugin-bnd.html

```xml
    <packaging>bundle</packaging>
    ...
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.felix</groupId>
                <artifactId>maven-bundle-plugin</artifactId>
                <version>2.3.7</version>
                <extensions>true</extensions>
                <configuration>
                    <instructions>
                        <Bundle-Name>${project.name}</Bundle-Name>
                        <Bundle-SymbolicName>${project.groupId}.${project.artifactId}</Bundle-SymbolicName>
                        <Export-Package>
                            org.anvard.karaf.greeter.api
                        </Export-Package>
                    </instructions>
                </configuration>
            </plugin>
        </plugins>
    </build>
```

See the [GitHub repository][3] for the complete `pom.xml`.

### Bundling and Karafing

Now that we have a way to build an OSGi bundle, we can install it to our local
Maven repository and then use Karaf's ability to resolve bundles from Maven to
load it into Karaf.

First, we compile the bundle using Maven:

```
$ mvn clean install

[ Lots of output; Internet downloaded ]

[INFO] --- maven-bundle-plugin:2.3.7:install (default-install) @ interfaces ---
[INFO] Installing org/anvard/karaf/greeter/interfaces/1.0-SNAPSHOT/interfaces-1.0-SNAPSHOT.jar
[INFO] Writing OBR metadata
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 1.829 s
[INFO] Finished at: 2016-10-25T20:33:25-04:00
[INFO] Final Memory: 19M/212M
[INFO] ------------------------------------------------------------------------
```

Now we can load into Karaf. Starting from a standard [Karaf distribution][7]:

[7]:http://karaf.apache.org/download.html

```
apache-karaf-4.0.7$ bin/karaf

...

karaf@root()> install mvn:org.anvard.karaf.greeter/interfaces/1.0-SNAPSHOT
Bundle ID: 52
karaf@root()> list
START LEVEL 100 , List Threshold: 50
ID | State     | Lvl | Version        | Name
----------------------------------------------------------
52 | Installed |  80 | 1.0.0.SNAPSHOT | Greeter Interfaces
karaf@root()> 
```

Karaf has some nice features for doing development on OSGi bundles that
take advantage of OSGi's modularity. For example, now that we have the
bundle installed and we know its ID, we can use `update 52` to grab the
latest snapshot from Maven. This includes stopping the existing bundle,
installing a newer version, and starting the newer version. This works
because OSGi is careful to keep bundles separate, even to the extent of
separate class loaders, so it's easy to discard a bundle and load in a
new one, even if the classes are the same.

### Wrapping Up

At this point we have a bundle that has some Java code in it, but it
doesn't do anything other than export that code for other bundles to
use. Next time I'll talk a little about the structure of the example
and why 5 Java files are split across 4 bundles.

