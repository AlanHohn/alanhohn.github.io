---
layout: post
title: "OSGi: Declarative Services and the Registry"
description: ""
category: articles
tags: []
---

In two previous articles, I introduced [building an OSGi bundle][1] and the
[architecture of a multi-bundle OSGi solution][2]. One of the key features of
that multi-bundle solution in its [associated GitHub repository][3] is the use
of OSGi declarative services.

OSGi declarative services are the OSGi way to handle the instantiation
problem: the fact that we want to code to interfaces, but we need some way to
instantiate classes and some way to provide some concrete instance of an
interface in order for the parts of our modular application to work together.

Like most solutions of this type, there are three parts to OSGi services: the
service interface, the service registry, and the service implementation. This
is exactly the same design as:

* Spring: The service interface is used as the type for the setter method or
  constructor; the service registry is the application context, and the service
  implementation is the bean.
* JDBC: The service interface is the JDBC API itself, the service registry is
  the JDBC driver manager, and the service implementation is the driver.
* JNDI / EJB: The service interface is whatever type we cast to once we do the
  lookup, the context is the service registry, and the EJB is the service
  implementation.

Of course, the reason all these use the same design pattern is because this is
the minimum number of things needed for discoverable services. But as a key
aside, we can conclude that as long as we code to Plain Old Java Interfaces,
and separate out instantiation and injection of those interfaces, we can write
code that works perfectly well in OSGi, Spring, and Java Enterprise. (Of
course, things like database access, remote lookup, and transactions break
that pure "framework independence" a little bit, but it still applies to a lot
of our code.)

### Coding to Interfaces

For our OSGi declarative services example, we first create our own Plain Old Java
Interface:

```java
public interface Greeter {
	String greet();

}
```

We then write some "manager" code that uses that interface:

```java
// ...
public String greet(String language) {
    // ... Fetch the right greeter
    return greeter.greet();
    // ...
}
// ...
```

Note that in our [example][3] these are in separate bundles, so we have to
export the `api` package from the `interfaces` bundle and import it into the
`manager` bundle in order for the interface to be visible.

### Declaring a service

To make an actual instance of this service, we write ordinary Java code that
implements the interface:

```java
public class FrenchGreeter implements Greeter {
    private static final Logger LOGGER = LoggerFactory.getLogger(FrenchGreeter.class);
	@Override
	public String greet() {
		LOGGER.info("Le 'greeter' en francais!");
		return "Bonjour tout le monde!";
	}
}
```

So far none of these examples include anything OSGi-specific. To use this
service in an OSGi context, we need to do two things: tell the service
registry about the implementation, and have a way to lookup the implementation
from the registry where we need it.

There are a few ways to register a service with the OSGi service registry. 

### Bundle Activator

First, we could register the service programmatically. To do this, we need a
reference to the service registry, and a way to tell the OSGi container to
invoke some code for us when it starts our bundle. We can get both of these
with a [bundle activator][4]. If we write a class that implements this
interface, and tell our [Maven Bundle plugin][5] about it so it gets
configured in the `META-INF/MANIFEST.MF` file of our JAR, then OSGi will
invoke our class after our bundle is started and before it is stopped. We can
use the `BundleContext` it passes us to register our service. To be polite, we
should also unregister our service when we are stopped.

It might look something like this (on the start side):
```java
public class Activator implements BundleActivator {
    public void start(BundleContext context) throws Exception {
        Dictionary<String,String> props = new Dictionary<>();
        props.put("language", "fr");
        context.registerService(Greeter.class.getName(),
            new FrenchGreeter(), props);
    }
    // ... stop
}
```

The upside to this method is that it's very clear. The downside is that we're
writing boilerplate code that's OSGi-specific in every bundle with a service
implementation. 

### Blueprint

OSGi also supports XML configuration that is very similar to what's supported by
the Spring Framework. If we drop an XML file into OSGI-INF/blueprint inside our
bundle JAR file, then the OSGi container will parse it automatically when our
bundle is started.

I'll show a Blueprint XML example in more detail in a future article, but here's
a quick look at what it might look like:

```xml
    <bean id="frenchGreeter" class="org.anvard.karaf.greeter.french.FrenchGreeter">
    </bean>
    <service id="frenchGreeterService" ref="frenchGreeter"
        interface="org.anvard.karaf.greeter.api.Greeter">
        <service-properties>
            <entry key="language" value="fr" />
        </service-properties>
    </service>
```

The advantage of this is that it avoids boilerplate Java, but it includes boilerplate
XML. If we're not otherwise using Blueprint XML we might not want to bring it in just
for this purpose.

### Service Component Runtime (SCR)

Since our example is using Apache Karaf, which is built on the OSGI capabilities of
Apache Felix, we have [SCR][6] available to us, including Java annotations. This means
we can annotate our implementation class and have it automatically discovered by
Felix and registered as a service.

The resulting code looks like this:
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

This is nice because it is very self-contained. We do pay the cost of having Felix-specific
annotations in our code, so we're no longer neutral as to whether we're using OSGi and which
container we're using. 

### Wrapping Up

Of course, Java annotations by themselves don't do anything, and we also need to have a way
to look up the service once it's in the registry. Next time I'll cover both of these topics.

[1]:https://dzone.com/articles/karaf-features-and-osgi-services-a-bundle
[2]:https://dzone.com/articles/structure-of-an-osgi-application-with-declarative
[3]:https://github.com/AlanHohn/karaf-greeter
[4]:https://osgi.org/javadoc/r4v43/core/org/osgi/framework/BundleActivator.html
[5]:http://felix.apache.org/documentation/subprojects/apache-felix-maven-bundle-plugin-bnd.html
[6]:http://felix.apache.org/documentation/subprojects/apache-felix-service-component-runtime.html

