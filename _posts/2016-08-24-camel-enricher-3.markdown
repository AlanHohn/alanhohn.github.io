---
layout: post
title: "Apache Camel: Content Enricher Foibles"
description: ""
category: articles
tags: []
---

This is the third of three articles on using Apache Camel with its [content
enricher][1] to handle transforming data on its way between two applications.
The [first][2] article discussed Camel and its positive attributes; the
[second][3] provided an example of using content enricher a straightforward
way.

[1]:http://camel.apache.org/content-enricher.html
[2]:https://dzone.com/articles/apache-camel-content-enricher
[3]:https://dzone.com/articles/apache-camel-content-enricher-example

To recap, Apache Camel provides a wealth of components and processors to
interact with applications and services in all kinds of ways, including
publish-subscribe messaging, REST, SOAP, file transfers, email, and many more.
Internally, it uses routes to move and transform data, greatly reducing the
amount of code required to integrate diverse pieces of a system. The content
enricher is one such processor that takes an incoming piece of data, uses it to
retrieve extra data from some other resource (specifically some URI), and then
passes the resulting enriched data on down the line.

What occasioned the writing of these articles is that the straightforward use
of the content enricher did not work for our use case, for two important
reasons. First, the REST web service in question provided only its own
information; it didn't repeat back any data passed into it. Second, the REST
web service expected a call via GET rather than POST.

## Aggregation Strategy

The first of these is very easy to deal with via a feature built into the
content enricher called an "aggregation strategy". When configuring the
enricher, you can specify a Java class that implements `AggregationStrategy`.
This means a single method with this signature:

```java
public Exchange aggregate(Exchange original, Exchange resource);
```

This class can then combine information from the "original" exchange that was
passed to the enricher and from the "resource" exchange that came back from
whatever URI the enricher was configured to use.

As part of a larger example, I've created an example aggregation strategy in a
[GitHub repo][4]; it looks like this:

[4]:https://github.com/AlanHohn/java-intro-course/tree/master/src/main/java/org/anvard/introtojava/camel

```java
public Exchange aggregate(Exchange original, Exchange resource) {
    OrderInfo info = (OrderInfo) original.getIn().getBody();
    OrderInfo recd = (OrderInfo) resource.getIn().getBody();
    info.setCustomerName(recd.getCustomerName());
    info.setOrderTotal(recd.getOrderTotal());
    if (original.getPattern().isOutCapable()) {
        original.getOut().setBody(info);
    }
    return original;
}
```

Note that we use the "incoming" message in both cases and cast to the
expected type. The other thing to note is the `isOutCapable()` section; most
Camel routes are `InOut`, with the "out" message becoming the "in" message of
the next step in the route. The final "out" message goes all the way back to
the producer of the route if that makes sense.  (For example, imagine a Camel
route that starts with an incoming REST call. Camel will route the final "out"
message back to the REST client.) However, some routes are `InOnly`, in which
case it's not valid to use the "out" message. This is described in more detail
[here][5].

[5]:http://camel.apache.org/using-getin-or-getout-methods-on-exchange.html

So now we have a way to deal with a resource that only supplies some of the
data we need, and we have a way in which the content enricher is more than just
syntactic sugar (as we saw in the [previous article][3]).  

## Building The Route

To use our aggregation strategy, we create a route that looks like this:

```java
public void configure() throws Exception {
    from("timer://ordergen").bean(new OrderGenerator(), "generate")
        .enrich().simple("http://localhost:8680/rest/order/lookup/${body.orderNumber}",
            new OrderAggregationStrategy()).marshal().json(JsonLibrary.Jackson)
        .log("${body}");
}
```

Note the way that we can use a "simple" expression with `enrich()` to configure
the URL based on properties of the incoming message.

Unfortunately, this is only a partial solution and still won't work with our
REST web service. We still need a way to tell Camel to make a `GET` call to our
web service rather than `POST`.

In turns out this is a little more challenging, partly because of the way that
Camel decides whether to use `GET` or `POST`. The algorithm is [here][6].  It
boils down to either making the body of the incoming message `null` or setting
the header `Exchange.HTTP_METHOD` to `GET`.

[6]:http://camel.apache.org/http.html

The second of these is obviously easier. We just need to add `setHeader()`
to the route:

```java
public void configure() throws Exception {
    from("timer://ordergen").bean(new OrderGenerator(), "generate")
        .setHeader(Exchange.HTTP_METHOD, "GET")
        .enrich().simple("http://localhost:8680/rest/order/lookup/${body.orderNumber}",
            new OrderAggregationStrategy()).marshal().json(JsonLibrary.Jackson)
        .log("${body}");
}
```

But here's where we ran into an issue. It turns out that the Camel HTTP
component will try to use the incoming message body as an `InputStream` for the
HTTP client, even in cases where `GET` is being used. Unfortunately, in this
case, the body is of type `OrderInfo`, and Camel doesn't know how to use that
as an `InputStream`. So instead of success, we get an exception traceback
containing this unpleasant message:

```plain
Caused by: org.apache.camel.NoTypeConversionAvailableException: No type converter available to convert from type: org.anvard.introtojava.camel.OrderInfo to the required type: java.io.InputStream with value org.anvard.introtojava.camel.OrderInfo@30140dd0
```

What this error message is saying is that the HTTP component is expecting
an `InputStream` and doesn't know how to make one of those using our
`OrderInfo` class. If our message body was something simple like a string,
instead of being a POJO, Camel would have a converter available in its
built-in set of type converters, and the conversion would happen invisibly.
But since this is a POJO, nothing doing.

Camel allows registration of custom type converters. So we were tempted to
create a type converter that just returned an empty input stream. But we
decided this would be too confusing for maintainers since it would be decoupled
from the point of use and the reason for needing it wouldn't be obvious.

So instead, we decided we needed to use the other method of choosing GET, which
is to null out the incoming message body. But this presents some difficulties,
because we need to use the body in the aggregation strategy, and because we need
to use it to build the URI for the enricher.

## The Solution, Finally

Fortunately the expressive power of Camel came through for us. Here's what we wound
up with:

```java
public void configure() throws Exception {
    from("timer://ordergen").bean(new OrderGenerator(), "generate")
        .enrich("direct:enricher", new OrderAggregationStrategy()).marshal().json(JsonLibrary.Jackson)
        .log("${body}");
    from("direct:enricher")
        .setHeader(Exchange.HTTP_URI, simple("http://localhost:8680/rest/order/lookup/${body.orderNumber}"))
        .transform().simple("${null}").to("http://ignored").unmarshal().json(JsonLibrary.Jackson, OrderInfo.class);
}
```

What we've done here is split things into two separate routes. This allows us to
manipulate just the exchange that's used for retrieving data from the REST web
service resource without affecting the primary exchange. The flow works like this:

* The timer fires, kicking off the first route.
* The method `OrderGenerator.generate()` is called and returns an `OrderInfo`
  object with some fields populated.  
* The enricher starts. It splits the exchange in two. One side is sent to
  `direct:enricher`.

The `direct` endpoint in Camel implements the [channel][] integration pattern.
It creates a coupling between two routes in the same Camel context. The
coupling is synchronous; it actually takes the form of a method call.

[channel]:http://www.enterpriseintegrationpatterns.com/patterns/messaging/MessageChannel.html

Work then proceeds in the second route:

* A header is added to the exchange using data from the message.
* The message body is set to null.
* The `http` component is invoked. It uses the header to override the URI. 
  Since the body is null, it uses a `GET`.
* The result comes back in JSON form and is unmarshalled into an instance 
  of `OrderInfo`.
* The `OrderInfo` object comes back to the enricher.

The key insight here is that the enricher doesn't care what kind of URI is
passed into it. When an `http` URI is used, it looks up that scheme in the
context and finds the Camel HTTP component. When `direct` is used, it looks
up that scheme instead, and ends up invoking another route. Either way, it
uses whatever comes back from the route as the "resource" exchange for the
aggregation strategy.

Note that this also solves one more issue, which is that the REST web service
returns JSON but we would like to write the aggregation strategy as just a
simple combining of two POJOs. By writing a separate route for the enricher, we
can perform the `unmarshal()` before the enricher gets the data back. We could
similarly build in some transformation here if it made sense rather than doing
it in the aggregation strategy.

With all that work done, the rest is simple:

* The enricher calls the aggregation strategy with the two exchanges and
  uses the returned exchange.
* The resulting object is marshalled back to JSON and sent to a log.

Running this route produces output like this:

```plain
[Camel (camel-1) thread #0 - timer://ordergen] INFO route1 - {"timestamp":1472081765263,"orderNumber":477,"customerName":"Johannes Smythe","orderTotal":2.214534914131583}
[Camel (camel-1) thread #0 - timer://ordergen] INFO route1 - {"timestamp":1472081766254,"orderNumber":742,"customerName":"Johannes Smythe","orderTotal":43.44691798994265}
[Camel (camel-1) thread #0 - timer://ordergen] INFO route1 - {"timestamp":1472081767259,"orderNumber":282,"customerName":"Johannes Smythe","orderTotal":62.38526390226096}
```

## Wrapping Up

It would be nice if Camel ignored the incoming message body in the HTTP
component when using GET. But we would still end up having to create a separate
route for the enricher so we could unmarshal to Java. So in the end we wound up
with the only solution that would have done us any good.  And we got some extra
practice debugging Camel routes.

I've written three articles on the topic, but the code is probably the best way
to understand what's going on. So I invite you to [look][4], and ask any questions
in the comments. If I missed an even better way to solve this problem, let me
know that too.

