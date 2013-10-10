---
layout: post
title: "Embedded Jetty Executable JAR"
description: "Using Maven to build with embedded Jetty"
category: articles
tags: [jetty, maven, jar, package]
---

Previous posts such as [this one][part3] have shown using embedded Jetty to
REST-enable a standalone Java program.  Those posts were lacking an important
feature for real applications: packaging into a JAR so the application will run
outside of Eclipse and won't be dependent on Maven and jetty:run. To make this
happen, we will use Maven to build an executable JAR that also includes all of
the Jetty and Spring dependencies we need.

The goal of this work is to get to the point where we can run the example application
by:

1. Cloning the Git repository.
2. Running `mvn package`.
3. Running `java -jar target/webmvc-standalone.jar`

When I started adding the necessary bits to the `pom.xml` file of my [sample
application][webapp], I expected a relatively straightforward solution. I ended
up with a relatively straightforward solution that was completely different from what I
expected. So I think it's worth a detailed discussion of how this solution
works and what Maven is doing for us.

Our desire to make an executable JAR is complicated by the fact that we want our Maven
project to build a WAR as a default package, so that we can use this code in a Java web
container if desired. Additionally, we introduce some complexity by making a single JAR
with all dependencies, because that causes files in the Spring JARs to collide. I'll show
what I did to address each of these.

Build both JAR and WAR
----------------------

The basic idea here is that we want Maven to make both a JAR file and a WAR file during
the "package" phase. Our `pom.xml` file specifies `war` as the packaging for this project,
so the WAR file will be created as expected. We need to add the JAR file without disturbing
this.

I found a great post [here][warandjar] that got me started. The basic idea is
to add the following to `pom.xml` under `build/plugins`:

{% highlight xml %}
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-jar-plugin</artifactId>
    <version>2.4</version>
    <executions>
        <execution>
            <id>package-jar</id>
            <phase>package</phase>
            <goals>
                <goal>jar</goal>
            </goals>
        </execution>
    </executions>
</plugin>
{% endhighlight %}

This is the behavior we would get for "free" if we used `jar` packaging in `pom.xml`. The
`execution` section ties it to the `package` phase so that it runs during the default build
process. The `jar` goal tells the plugin what to make. This gets us a basic JAR with the
classes in the normal place for a JAR (rather than in `WEB-INF/classes` as they must be
in the WAR file).

At the same time, we need to deal with the fact that the Maven resources plugin considers only
`src/main/resources` to be a resources directory, while in our case we have files in
`src/main/webapp` that also need to be included. We want to copy these resources to the target
directory so the JAR plugin will pick them up. (This is an important distinction; the typical
Maven question, "how do I include extra resources in my JAR?" should really be "how do I get
extra resources into `target` so the JAR plugin will pick them up?")

We add this to the `build` section of `pom.xml`:

{% highlight xml %}
<resources>
    <resource>
        <directory>src/main/resources</directory>
    </resource>
    <resource>
        <directory>src/main/webapp</directory>
    </resource>
</resources>
{% endhighlight %}

This causes our new `webmvc.jar` file to include the HTML, JavaScript, etc. required for our
embedded Jetty webapp.

JAR with dependencies
---------------------

Next, we make an additional JAR that has the correct `Main-Class` entry in the `MANIFEST.MF`
file and includes the necessary dependencies so we only have to ship one file. This is done
using the [Maven assembly plugin][assembly]. The assembly plugin does repackaging only; that's
why we had to add a JAR artifact above. Without that JAR artifact to work from,
the assembly plugin repackages the WAR, and we end up with classes in `WEB-INF/classes`. This causes
Java to complain that it can't find our main class when we try to run the JAR.

The assembly plugin comes with a `jar-with-dependencies` configuration that can be used simply
by adding it as a `descriptorRef` to the relevant section of `pom.xml`, as shown in [this
StackOverflow question][soq]. However, this configuration doesn't work in our particular case,
as the Spring dependencies we need have files with overlapping names. As a result, we need to
make our own assembly configuration. Fortunately, this is pretty simple. We first add this to
the `build/plugins` section of `pom.xml`:

{% highlight xml %}
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-assembly-plugin</artifactId>
    <version>2.4</version>
    <configuration>
        <descriptors>
            <descriptor>src/assemble/distribution.xml</descriptor>
        </descriptors>
        <archive>
            <manifest>
                <mainClass>org.anvard.webmvc.server.EmbeddedServer</mainClass>
            </manifest>
        </archive>
    </configuration>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>single</goal>
            </goals>
        </execution>
    </executions>
</plugin>
{% endhighlight %}

As before, we use the `executions` section to make sure this is run automaticaly during
`package`. We also specify the main class for our application. Finally, we point the
plugin to our assembly configuration file, which lives in `src/assemble`. I present the
assembly configuration below, but first we need to talk about the issue with the Spring
JARs that made this custom assembly necessary.

Spring schemas and handlers
---------------------------

With this sample application, we use Spring WebMVC to provide a REST API for ordinary
Java classes, as discussed in [this post][part2]. The Spring code we use is spread
across a few different JARs.

Recent versions of Spring added a "custom XML namespace" feature that allows the contents
of a Spring XML configuration file to be very extensible. Spring WebMVC, and other Spring
libraries, use this feature to provide custom XML tags. In order to parse the XML file with
these custom tags, Spring needs to be able to match these custom namespaces to handlers. To
do this, Spring expects to find files called `spring.handlers` and `spring.schemas` in the
`META-INF` directory of any JAR providing a Spring custom namespace.

Several of the Spring JARs used by this application include those `spring.handlers` and
`spring.schemas` files. Of course, each JAR only includes its own handlers and schemas.
When the Maven assembly plugin uses the `jar-with-dependencies` configuration, only one
copy of those files "wins" and makes it into the executable JAR. 

We really just need a single `spring.handlers` and `spring.schemas` that are the concatentation
of the respective files. There is probably some Maven magic to accomplish this, but I elected
to do it manually as my [Bash-fu][] is much greater than my Maven-fu. I added two files
to the `src/assemble` directory that have the combined contents of the various files in the Spring
JARs.

Maven assembly configuration
----------------------------

The assembly file looks like this:
{% highlight xml %}
<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.2 http://maven.apache.org/xsd/assembly-1.1.2.xsd">
  <id>standalone</id>
  <formats>
    <format>jar</format>
  </formats>
  <baseDirectory></baseDirectory>
  <dependencySets>
    <dependencySet>
      <unpack>true</unpack>
      <unpackOptions>
        <excludes>
          <exclude>META-INF/spring.handlers</exclude>
          <exclude>META-INF/spring.schemas</exclude>
        </excludes>
      </unpackOptions>
    </dependencySet>
  </dependencySets>
  <files>
    <file>
      <source>src/assemble/spring.handlers</source>
      <outputDirectory>/META-INF</outputDirectory>
      <filtered>false</filtered>
    </file>
    <file>
      <source>src/assemble/spring.schemas</source>
      <outputDirectory>/META-INF</outputDirectory>
      <filtered>false</filtered>
    </file>
  </files>
</assembly>
{% endhighlight %}

The `id` will be used to name this assembly. The `baseDirectory` tells the assembly plugin
that the pieces it assembles should go at the root of the new JAR. (Otherwise they would go
into a directory using the project name, in this case "webapp".)

The next two sections are important. We want to exclude the `spring.handlers` and
`spring.schemas` from the Spring JARs (a.k.a. the dependency set). Instead, we
want to explicitly include them from our `src/assemble` directory, and put them
into the right place. We also want the assembly plugin to unpack the dependency
set JARs so we wind up with Java class files in our new JAR, rather than just
JAR-files-inside-JAR-file, which would not run correctly.

Notice that there is no directive telling Spring to include all dependencies from the dependency
set, including transitive dependencies. This is the default so we don't need to specify it. It's
also the default to include the unpacked files from our own artifact
(`webmvc.jar`) into the new JAR.

Conclusion
----------

A real-world application would probably pick either WAR packaging or executable JAR packaging,
and be simpler. Additionally, it would be possible to use multiple Maven modules to build a JAR
and embed it in the WAR. But it's interesting to see how to implement a more complex solution
that builds everything we need from a single project.


[webapp]:https://github.com/AlanHohn/webmvc
[warandjar]:http://communitygrids.blogspot.com/2007/11/maven-making-war-and-jar-at-same-time.html
[assembly]:http://maven.apache.org/plugins/maven-assembly-plugin/
[soq]:http://stackoverflow.com/questions/1814526/problem-building-executable-jar-with-maven
[part2]:{% post_url 2013-09-17-webmvc-server-2 %}
[part3]:{% post_url 2013-09-18-webmvc-server-3 %}
[bash-fu]:http://bash-fu.com/


