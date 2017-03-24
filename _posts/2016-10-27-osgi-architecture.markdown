---
layout: post
title: "Structure of OSGi Application with Declarative Services"
description: ""
category: articles
tags: []
---
    
So with our [previous article][1] and with a [sample application][2], we made
it all the way to an OSGi bundle that we can install in a Karaf container.
However, so far we just build the bundle for our `interfaces` project, which
just contains a single Java class.

And that raises an important question: in a project with only five total Java
classes, why did I go to the trouble to have four separate OSGi bundles, plus
a separate Maven project for the Karaf feature repository XML file? The answer
partly has to do with illustrating OSGi declarative services, but also with
the right approach to OSGi in general.

### Thinking In Bundles

The idea of OSGi is modularity. Each OSGi bundle is an island unto itself;
the OSGi container may be a single process in the operating system, and a
single Java Virtual Machine, but each bundle gets its own class loader and
therefore in some sense has its own class path.

In some ways, this is similar to Java Enterprise, where the idea was one
big application server that could run multiple applications. The application
server provides shared resources (like database connections, lookups, and
a transaction manager) that lots of applications can use.

OSGi has a little bit of that same reasoning; with declarative services, we
can load an OSGi bundle to provide an HTTP server and then use that server with
lots of servlets or REST endpoints. But that is not the primary purpose for
OSGi's modularity. Instead, the idea is to get around the particular kind of
pain that comes from having large applications with lots of third party libraries,
each with their own set of dependencies.

In that environment, it is common to have cases where different third party
libraries need different and conflicting versions of dependencies. In a regular
Java program, to get around that problem, you can either rewrite one of the
libraries to use a private version of the dependency, or you can find some
set of versions that is cross-compatible. Both of these are restrictive and make
it harder to upgrade. (If you'd like to experience this pain vicariously, [try
this Google search][3]).

OSGi aims to avoid this pain by giving each bundle its own private class path
and allowing bundles to specify versions of the packages they import. This
means that two libraries that need different versions of CGLib can each get the
version they need without either of the two having any conflicts with the other
version.

### Rules For Bundles

So with this understanding of how bundles are supposed to work, we can derive a
few rules for what should be in a separate bundle. In general, we should have
separate bundles whenever we have:

* Code that we might want to update independently from other code. This way
  we can get the basic benefits of modularity.
* Code that we might include or exclude for a certain configuration of our
  application. This is another basic benefit of modularity.
* Code that has a particular set of dependencies on other libraries. This
  way we can isolate those dependencies to decrease the chance of conflicts.
* Interface code that might have different implementations. This way we can
  swap out implementations without having to make any other changes at all.

### About That Last One

When I teach Java, I like to talk a lot about the benefits of coding to interfaces.
The idea is that any code outside a module doesn't know anything about any
implementation classes, decreasing the chances that changes will "leak" between
modules. However, this creates what I call the "instantiation problem": you can't
`new` an interface, so somewhere there needs to be some code that knows what
implementation to instantiate. This is where a factory or dependency injection
pattern comes in.

OSGi's solution to the instantiation problem is declarative services. With declarative
services, we can register an implementation for an interface, along with some
additional properties, with a service registry. Users of the service can lookup
the implementation in the service registry and get a reference to an implementation
without having to do their own instantiation or know anything about the service.

Now, one of the advantages of OSGi is that deployment of bundles is dynamic; we can
decide at startup, or even while we're running, what bundles we want to have available.
So if each of our distinct service implementations is in a separate bundle, we can
deploy and upgrade it independently of the others. I've seen this technique used very
successfully to build highly modular applications that are very easy to upgrade.

At the same time, unless we really are going to be separating out multiple service
implementations, we don't really have to separate the interface from the implementation
in order to get the benefits of OSGi modularity. We just need to put them in separate
packages so we can specify `Export-Package` just for the interface. That will have the
same advantages of controlling the class path and limiting any dependencies that "leak"
to users of our service.

### A Couple Caveats

Not everything in OSGi-land is sweetness and light. A well-designed, highly modular
application will genuinely have no issues with different versions of dependencies. But
most Java code is written for regular Java first and OSGi second (if at all), so many
libraries are not quite that modular. Also, many libraries use various tricks, like
reflection or classpath scanning, that are made a lot more complicated with multiple
class loaders. OSGi has to [provide workarounds][4] for these, and this rapidly becomes
complex.

### Wrapping Up

Still, I've seen teams do some really neat things with OSGi, and I think it's worth
learning. Hopefully I've introduced OSGi reasonably well now, and can move on to
declarative services specifically. Next time I'll walk through how we can make a
service and what the code looks like for finding services in the registry.

[1]:https://dzone.com/articles/karaf-features-and-osgi-services-a-bundle
[2]:https://github.com/AlanHohn/karaf-greeter
[3]:https://www.google.com/webhp?ion=1&espv=2&ie=UTF-8#q=hibernate%20nosuchmethoderror
[4]:http://blog.osgi.org/2013/02/javautilserviceloader-in-osgi.html

