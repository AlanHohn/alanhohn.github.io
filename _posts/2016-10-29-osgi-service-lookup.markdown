---
layout: post
title: "OSGi Services: Automated Discovery and Service Lookup"
description: ""
category: articles
tags: []
---

This articles continues a series on declarative services in OSGi. We started
[with a basic OSGi bundle][1], then discussed [architecting a multi-bundle
application][2]. Then we looked closer at [declarative services][3] and how
to register them. All of this is fully demonstrated in [an example application
on GitHub][4].

With the last article, we left off with a service interface, and
implementation, and a few ways to tell the service registry about it. However,
we didn't cover the mechanics of registration for our last method ([SCR using
Java annotations][5]) and we didn't cover service lookup. In this article, I'll
be tackling the first of those two topics.

### SCR Annotations

Our service implementation looks like this:

```java
@Component(immediate = true)
@Service
@Property(name="language", value="fr")
public class FrenchGreeter implements Greeter {

    private static final Logger LOGGER = LoggerFactory.getLogger(FrenchGreeter.class);

	@Override
	public String greet() {
		LOGGER.info("Le 'greeter' en francais!");
		return "Bonjour tout le monde!";
	}
}
```

Those `@Component`, `@Service`, and `@Property` annotations by themselves
don't do anything; there needs to be some code that processes them. In this
case, we need code that scans the classpath, finds annotated classes,
instantiates them, and registers them in the service registry.

Since I'm using Karaf and therefore Apache Felix, I'm using the Felix version
of these annotations. So I'm going to demonstrate the Felix way of using them.
This involves processing the annotations at build time and generating an XML
file that gets packed into the JAR. This XML file is then specified in the
`META-INF/MANIFEST.MF` file so the OSGi container knows to process it. (It's
worth noting that there is a [vendor-neutral set of annotations][6]) that can
also be used; the process is very similar. Under the covers, the [bnd tool][7]
from Peter Kreeft is ultimately doing a large part of the work.)

To process the annotations at build time, we use Felix's `maven-scr-plugin`.
This plugin provides a goal to generate the XML descriptor files from the
annotations.

The plugin declaration is shown below. For those looking at the [source code
in GitHub][4], note that this is specified in the parent POM; it doesn't hurt
anything to apply it to modules where the annotations aren't used, and specifying
it in the parent reduces duplication.

```xml
    <plugin>
        <groupId>org.apache.felix</groupId>
        <artifactId>maven-scr-plugin</artifactId>
        <version>${maven.scr.version}</version>
        <executions>
            <execution>
                <id>generate-scr-scrdescriptor</id>
                <goals>
                    <goal>scr</goal>
                </goals>
                <configuration>
                    <outputDirectory>target/classes</outputDirectory>
                </configuration>
            </execution>
        </executions>
    </plugin>
```

With this particular bit of magic applied, when our JAR is generated we get two
special things. First, we get this line in `META-INF/MANIFEST.MF`:

```
Service-Component: OSGI-INF/org.anvard.karaf.greeter.french.FrenchGreeter.xml
```

Second, we get the actual XML file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<components xmlns:scr="http://www.osgi.org/xmlns/scr/v1.0.0">
    <scr:component immediate="true" name="org.anvard.karaf.greeter.french.FrenchGreeter">
        <implementation class="org.anvard.karaf.greeter.french.FrenchGreeter"/>
        <service servicefactory="false">
            <provide interface="org.anvard.karaf.greeter.api.Greeter"/>
        </service>
        <property name="language" value="fr"/>
        <property name="service.pid" value="org.anvard.karaf.greeter.french.FrenchGreeter"/>
    </scr:component>
</components>
```

There's nothing special about this file. We could have written it ourselves and
used the `maven-bundle-plugin` to add the `Service-Component` information to the
manifest. But this is obviously much more verbose than Java annotations. It's
also worth mentioning that the reason I showed Blueprint XML in the [previous article][3]
is because Blueprint XML does the same thing less verbosely, and is capable of
doing many other useful things, as I hope to show in a future article.

### Wrapping Up

We've almost described every piece of our OSGi declarative services example. The one thing
that's missing is to perform the service lookup. I want to save that for another article for
two reasons. First, I want to discuss finding multiple service instances and choosing between
them based on properties. Second, I want to show both programmatic lookup and service lookup
using Blueprint XML. Across both of these, we need to consider the fact that in OSGi, bundles
can come and go dynamically, and we need to deal with the fact that the available services
could change at any time.
    
[1]:https://dzone.com/articles/karaf-features-and-osgi-services-a-bundle
[2]:https://dzone.com/articles/structure-of-an-osgi-application-with-declarative
[3]:https://dzone.com/articles/osgi-declarative-services-and-the-registry
[4]:https://github.com/AlanHohn/karaf-greeter
[5]:http://felix.apache.org/documentation/subprojects/apache-felix-maven-scr-plugin/scr-annotations.html
[6]:http://enroute.osgi.org/services/org.osgi.service.component.html
[7]:http://bnd.bndtools.org/

