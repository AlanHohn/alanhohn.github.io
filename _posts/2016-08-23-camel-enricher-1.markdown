---
layout: post
title: "Apache Camel Content Enricher"
description: ""
category: articles
tags: []
---

A colleague and I were working through using Camel as an event-driven
data router. Part of the work the router had to do was fetch additional
information from a REST web service. This was a natural fit for Camel's
[content enricher][en], but we had to work through a few bumps along the
way, so it was a great learning experience.

[en]:http://camel.apache.org/content-enricher.html

## Apache Camel

Let me start first with a brief discussion of Camel and the content
enricher pattern. Then, in the next post, I'll walk through an example
implementation using Camel's Java DSL. Finally, I'll walk through some
unique things about our use case and how we made things work.

[Apache Camel][camel] is a Java library that greatly simplifies routing
and transforming data. It's based on the [Enterprise Integration Patterns][eip],
originally laid out in a book by Gregor Hohpe and Bobby Woolf. The
enterprise integration patterns identify ways to deal with common problems,
like the need to pass messages between systems, route messages based on their
content, handle message delivery failures, transform the data inside the
messages, and successfully route and correlate replies. By organizing the
patterns around a "message", the patterns support publish-subscribe or
request-reply semantics but allow applications to be decoupled. This means it's
much easier to integrate arbitrary components with any kind of expected
interface.

In addition to the core patterns, Camel provides a wealth of components to
handle specific interfaces: everything from polling a directory for files, 
connecting to an FTP server, calling (or exposing) a REST web service, or
just calling into arbitrary Java code. To use Camel, you define a "route" that
takes data from somewhere, operates on it, sending it to each endpoint within
the route until finished. Routes can be defined using a Java Domain Specific
Language (DSL) or in XML (using the Spring Framework or OSGi Blueprint).

Here's an example using the Java DSL of a Camel route that waits for
a JMS object message (using ActiveMQ), pulls out a field containing a list,
splits it, converts it to JSON, and saves it to etcd:

```java
CamelContext context = new DefaultCamelContext();
context.addRoutes(new RouteBuilder() {
  public void configure() {
    from("activemq:pendingOrders")
    .transform().simple("${body.orderIds}")
    .split()
    .setHeader(EtcdConstants.ETCD_PATH, simple("/orders/pending/${body}"))
    .marshal().json(JsonLibrary.Jackson)
    .to("etcd:keys");
  }
}
```

That's a lot of functionality in a few lines of code. The nice thing about
using Camel for this kind of thing, besides the number of lines of code it
saves, is that whether you use the Java or XML DSL, it's relatively easy to
follow along and see what's happening to the data.  Even someone who has never
worked with Camel can see what is being done, even if it isn't clear why it's
being done in a certain way or what's happening under the covers.

## Transform Plus

In our particular example, a message was coming in via one publish-subscribe
channel, being transformed into another data type, and going out another
publish-subscribe channel. Of course, it would be trivial to implement this
with a Java class. But it is even easier to implement with Camel, with the
advantage that if some piece of that behavior needs to change, it probably
would result in a change to just a couple lines of XML.

It's important to note that there are very good architectural reasons to
have this kind of data transformer implemented separately. It might be tempting
to just have the data producer make data in the format the consumer expects, or
to have the consumer add a feature to support multiple data types. But this
ends up coupling the two components together excessively. Like I describe in
my article on [one concept][1], in a distributed integration architecture,
pieces that provide integration are "first class" citizens of the architecture
and are implemented separately.
 
In this case, it has the added benefit of making it easy to augment the data
transformation without changing either the producer or the consumer. In
addition to bringing in a message, transforming it, and shipping it out, the
integration piece needed to fetch other data from a REST web service and to
create an output data item that includes information from both the input
message and the web service.

This is a perfect use case for the [content enricher pattern][cep]. In this
pattern, we start with a "basic" message. We use some data from the basic
message to retrieve data from some resource. We combine that with the basic
message to make an "enriched" message that goes on to the next stage.

## Wrapping Up

In the next post, I'll show an example using the content enricher with Camel.
For now, I wanted to write a few words about getting up to speed with the
enterprise integration patterns.

When I first started working with the enterprise integration patterns, I
had a hard time relating them to the software design patterns. With the
Gang of Four patterns, there tends to be a pretty concrete example of
how the pattern would be implemented in a given programming language. Also,
the Gang of Four patterns tend to stand independently (at least compared to
EIP). With EIP, the patterns are explicitly chained together, and there
really isn't any particular kind of implementation specified; it's all very
abstract.

It took some thinking and working with the EIP to gain an appreciation of what
it offers, and in the process I started to change my view of what design
patterns are. Like I said in my [article on the subject][des], I now see 
design patterns as a way of training our minds to think about problems in a
certain way, to see similarities that aren't otherwise apparent. To put it
another way, from the perspective of EIP there is no design difference between
sending a JMS message with `ReplyTo` and listening for the response, and making
a SOAP web service call. Either is an instance of the "Request-Reply" pattern,
and the difference is just implementation detail.

There is also an advantage in modularity. Before working with the EIP, if I was
presented with the need to take some incoming data, modify it, and save it off
somewhere, I would have seen the required actions as individual procedural
steps, but not as independent steps.  With the EIP, we can think about each of
those steps (take the data, modify the data, save the data) as individual
modular components that we can write once and then leverage elsewhere. Once we
can think about even very complex data transformations as a series of simpler
steps, we can create software that's easier to write, modify, and perhaps most
importantly to test.

[camel]:http://camel.apache.org/
[eip]:http://www.enterpriseintegrationpatterns.com/
[1]:https://dzone.com/articles/simplicity-one-concept
[cep]:http://www.enterpriseintegrationpatterns.com/patterns/messaging/DataEnricher.html
[des]:https://dzone.com/articles/design-patterns-are-not-blueprints

