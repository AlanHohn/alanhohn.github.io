---
layout: post
title: "REST enabled Java app, part 2"
description: "Spring WebMVC Controllers"
category: articles
tags: [java, spring, webmvc, rest]
---

[Last time][prev] I introduced an [example application][webapp] I wrote to illustrate
Spring WebMVC for a Java class. I think the application is a nice example because
it also illustrates the ability to add a REST API to an existing standalone Java
application using Jetty as an embedded servlet container.

I'm presenting this example in a series of posts because I learned from personal
experience teaching this that the more "under the covers" behavior there is, be it
classpath scanning, annotation configuration, reflection, or proxying, the harder
it can be for new folks to grasp. Lots of people know way more than I do about
Spring WebMVC, but I'm hoping to lay out in detail what I do know. As a result,
this post will focus just on the controller class. The business logic of the 
class is intentionally very simple in order to avoid being distracted from what
Spring WebMVC is doing for us.

Controller class
----------------

The Java code for the controller class is:

{% highlight java %}
package org.anvard.webmvc.server;

import org.anvard.webmvc.api.Calculation;
import org.springframework.stereotype.Controller;
import org.springframework.util.Assert;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class Calculator {

    @RequestMapping(value = "/calc/{op}/{left}/{right}", 
                    method = RequestMethod.GET)
    @ResponseBody
    public Calculation calculate(@PathVariable("op") String op, 
            @PathVariable("left") Integer left,
            @PathVariable("right") Integer right) {
        Assert.notNull(op);
        Assert.notNull(left);
        Assert.notNull(right);
        Calculation result = new Calculation();
        result.setOperation(op);
        result.setLeft(left);
        result.setRight(right);
        return doCalc(result);
    }

    @RequestMapping(value = "/calc2", method = RequestMethod.POST)
    @ResponseBody
    public Calculation calculate(@RequestBody Calculation calc) {
        Assert.notNull(calc);
        Assert.notNull(calc.getOperation());
        Assert.notNull(calc.getLeft());
        Assert.notNull(calc.getRight());
        return doCalc(calc);
    }

    private Calculation doCalc(Calculation c) {
        String op = c.getOperation();
        int left = c.getLeft();
        int right = c.getRight();
        if (op.equalsIgnoreCase("subtract")) {
            c.setResult(left - right);
        } else if (op.equalsIgnoreCase("multiply")) {
            c.setResult(left * right);
        } else if (op.equalsIgnoreCase("divide")) {
            c.setResult(left / right);
        } else {
            c.setResult(left + right);
        }
        return c;
    }
    
}
{% endhighlight %}

The `doCalc` method is here for completeness but we can ignore it. The Spring
WebMVC behavior is configured through the annotations. Note that we annotate
both the class and the methods. The class-level annotation I discussed last
time; it's used by the Spring classpath scanning function to automatically
find classes that should be added to the Spring application context. By using
`@Controller` rather than `@Component` or `@Service` we also tell WebMVC to
search for method-level annotations.

The details of the method-level annotations are really going to depend on
how the REST API requests and responses should look to clients. This simple
example only illustrates a few:

* `@RequestMapping`: This annotation provides a unique path for the service
and sets up path variables. It also allows specifying what type of HTTP
request should be accepted (e.g. GET, POST, PUT, DELETE).
* `@ResponseBody`: Informs WebMVC that the Java object returned by the method
should be used in the body of the HTTP response (suitably converted, as
discussed below).
* `@PathVariable`: Matches a method parameter to a specific item in the request URL.
* `@RequestBody`: The entire body HTTP request is converted to the type of the
parameter before the method is called. As you might expect, only one parameter
can get this annotation, though other parameters can be path variables or
request parameters (discussed below).

It is up to the application to make sure that the various @RequestMapping paths
don't conflict. A naming scheme is definitely the way to go.

The selection of the HTTP request method is important to make a REST API align
with user expectations and the typical behavior for REST servers. The use of
POST in the example above is non-standard as the method does not result in a
state change for that particular resource. Really that method should be a GET
as well since it's returning unmodified state.

Path Variables and Request Parameters
-------------------------------------

Path variables deserve some additional discussion. A key idea of REST is that
where possible, a clear, logical URI should be assigned to a long-lived resource.
In this case, we can think of a calculation as a "resource" &mdash; if we add
2+2, we will always get the same calculation object back, with the result of 4.
It therefore makes sense to think of the URI `http://server:port/rest/calc/add/2/2` 
as the permanent "home" of the calculation:

{% highlight javascript %}
{
    "operation": "add",
    "left": 2,
    "right": 2,
    "result": 4
}
{% endhighlight %}

On the other hand, there may be some transient parameter we wish to pass to the
server that could hold different values for the same calculation. To extend our
admittedly silly example, we might have a mode of our calculator that delegated
the calculation to an external engine for performance reasons. The resulting
calculation would be the same, so we wouldn't want to encode that directly into
the URI; we would want to use a query parameter.

Deciding between the two approaches is important in creating a clear API. Spring
WebMVC of course supports both, using the `@PathVariable` annotation we've seen
plus the `@RequestParam` annotation for HTTP query parameters. To finish our
example, consider the following method declaration:

{% highlight java %}
    @RequestMapping(value = "/calc/{op}/{left}/{right}", 
                    method = RequestMethod.GET)
    @ResponseBody
    public Calculation calculate(@PathVariable("op") String op, 
            @PathVariable("left") Integer left,
            @PathVariable("right") Integer right, 
            @RequestParam("engine", required=false) String engine) {
      ...
    }
{% endhighlight %}

The declaration is the same as before, but we've added a query parameter. We
don't modify the request mapping to do this, because the Java Servlet API does
not see two identical URLs with different query parameters as different URLs, and
neither does Spring WebMVC. The resulting method could be accessed using a URL like
`http://server:port/rest/calc/add/2/2?engine=matlab`.

Type Conversion
---------------

Above I mentioned that Spring will automatically do type conversion on the request body
and the response body. Spring will also perform automatic conversion on parameters, so
in the example above if someone tried to call `http://server:port/rest/calc/add/2/abc`
the request would not even reach our method. WebMVC would send back an HTTP error 400
(Bad Request) for us.

Conversion from string for parameters is generally straightforward. Conversion of request
and response bodies is more complicated. REST APIs typically use JSON or XML, and Spring
WebMVC is able to support both, as well as custom converters.

There is nothing in our example anywhere that configures JSON conversion, but we get it
for free by having the necessary Jackson libraries in the Maven `pom.xml` file. This is
because we used WebMVC's annotation-driven configuration. As a result, when Spring
instantiates our controller class, WebMVC actually generates a proxy. The proxy wraps
our various controller methods:

1. Before our method is called, the proxy calls Jackson when required to convert the 
request body to a Java object.
2. The proxy calls our request method.
3. The proxy calls Jackson with the Java object that's returned from our method to 
convert it to the right form for the response.

That completes this second post on this simple example using WebMVC. Next time we'll
quickly discuss the client before discussing how Jetty is used to add a REST API to
a standalone Java program.

[prev]:{% post_url 2013-09-16-webmvc-server-1 %}
[webapp]:https://github.com/AlanHohn/webmvc

