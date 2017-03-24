---
layout: post
title: "Apache Camel Content Enricher Example"
description: ""
category: articles
tags: []
---

In a [previous article][1] I discussed why Apache Camel is a useful
tool for building small modules to perform integration independent
of any of the pieces being integrated. With that out of the way
I can go straight into showing an example of using Apache Camel's
content enricher. 

[1]:https://dzone.com/articles/apache-camel-content-enricher

The basic flow of our Camel route is to listen for data to come in via a
publish-subscribe messaging destination and send it back out in a
format that another consumer is expecting. However, the incoming data
does not have all the information required to complete the outgoing
message. So the content enricher is going to fetch that data from somewhere
else to fully populate the outgoing message.

To illustrate all of this, I've created [an example on GitHub][2]. In
order to create a self-contained example, I've included an embedded REST
service that will be the source of our "extra" data, and a data generator
to replace the initial publish-subscribe message from the first producer.

[2]:https://github.com/AlanHohn/java-intro-course/tree/master/src/main/java/org/anvard/introtojava/camel

## Embedded REST web service

The embedded REST web service is based on [one I built last year][3] using
Jersey and Jetty. I [wrote that up][4] at the time, so no need to go into
too much detail. I'll just show the key part of the service so we can see
what it's doing with the data it gets:

```java
@POST
@Path("/lookup")
@Consumes({"application/json"})
@Produces({"application/json"})
public OrderInfo fillIn(OrderInfo info) {
    info.setCustomerName("Johannes Smythe");
    info.setOrderTotal(r.nextDouble() * 100.0);
    return info;
}
```

The great thing about JAX-RS is how simple it makes this kind of thing. The
`OrderInfo` class is a data transport object (DTO) that just stores information
related to an order. This method takes whatever data is passed in and populates
a couple additional fields. When we run this via the embedded Jetty server (see
[GitHub][2] and [the article][4] for details) we can see the following output
(using [httpie][]):

```plain
$ http :8680/rest/order/lookup orderNumber=123
HTTP/1.1 200 OK
Content-Type: application/json
Server: Jetty(9.1.1.v20140108)
Transfer-Encoding: chunked

{
    "customerName": "Johannes Smythe",
    "orderNumber": 123,
    "orderTotal": 55.91403903011334,
    "timestamp": null
}
```

[3]:https://github.com/AlanHohn/jaxrs
[4]:https://dzone.com/articles/standalone-java-application-with-jersey-and-jetty
[httpie]:https://github.com/jkbrzt/httpie

## Camel Route

So we have our external "resource" ready. Now we need to supply the Camel
route that will use it. I'm electing to use the Java DSL, mostly because I have
a lot more experience with using either Spring or Blueprint XML. To build a Camel
route using the Java DSL, we create a route builder:

```java
public class EnrichRoutePost extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        from("timer://ordergen").bean(new OrderGenerator(), "generate")
                .marshal().json(JsonLibrary.Jackson)
                .setHeader(Exchange.CONTENT_TYPE, constant("application/json"))
                .enrich("http://localhost:8680/rest/order/lookup").log("${body}");
    }

}
```

By extending the `RouteBuilder` class, we get access to lots of useful chaining
methods. Under the covers, when the route is built, Camel creates objects representing
each stage of the route, and gives each stage a reference to the next stage. As a result,
at runtime executing the route is making a series of method calls, where possible
directly from one step in the route to the next. This is done for performance reasons.

The method calls between steps in the route include a parameter called an
`Exchange`, which Camel uses to hold an "incoming" and an "outgoing" message.
Each message includes headers and a body. The header names are strings; the
header value and body can be of any type. When building and debugging Camel
routes, it is critical to think about the state of the exchange at each step
in the route, as this will directly affect the behavior of the next step.

The most generic route building methods are `from()` and `to()`; with these
methods we can provide any URI that Camel understands and configure using path
and query parameters in the URI. The URI schemes that Camel understands are
dynamic based on what Camel components are on the classpath; this extensibility
is a big reason for Camel's success.

In this case, we are starting with a timer; for recent versions of Camel it defaults to
once per second after one second, so we don't need to do any configuration. At this
point, the exchange has no usable data, and we want it to contain an object of type
`OrderInfo`, so we use a `bean()` to call an arbitrary method on a Java class that
creates an object of the type we want. These two steps together simulate the 
publish-subscribe message we might receive in a real system.

Now that we have an object of type `OrderInfo` we want it to become the input to the
REST web service. For this to work, we need to convert it to JSON. We do this with
a `marshal()`, specifying JSON as the target using the Jackson library. This works
without any configuration as long as the `camel-jackson` library is on the classpath.
The exchange now contains a string form of the order info in JSON format.

The next step does the content enriching by calling the web service. The `enrich()`
processor takes a URI, similar to `from()` and `to()`. Based on the URI, it routes
the incoming message to a component, and sets the outgoing message based on what
returns from the component. (Headers are copied over.) In our case, this means that
the enricher uses the HTTP component to POST to the supplied URL, sending the JSON
data as the POST body. The JSON data that comes back becomes the outgoing message
body.

To run this route, we need to embed it in a Camel context and start that context:

```java
RouteBuilder builder = new EnrichRoutePost();
CamelContext context = new DefaultCamelContext();
context.addRoutes(builder);
context.start();
```

We then see output like this:

```plain
[Camel (camel-1) thread #0 - timer://ordergen] INFO route1 - {"timestamp":1472045595996,"orderNumber":308,"customerName":"Johannes Smythe","orderTotal":36.50952697279789}
```

The output contains data from both the original generator and the REST web service.

## Wrapping Up

Using a content enricher this way, we're really just using `enrich()` as syntactic sugar
in place of `to()`; the behavior would be exactly the same. But the content enricher is
capable of more complex behavior, and we'll need that in the next article in order to
deal with some use cases that aren't quite this simple.

