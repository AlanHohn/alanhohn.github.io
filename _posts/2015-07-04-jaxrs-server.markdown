---
layout: post
title: "Java REST Web Service"
description: "Standalone Java application with Jersey and Jetty"
category: articles
tags: [java,jaxrs,jersey,jetty]
---

Introduction
------------

I've built a [small example][gh] of running a standalone Java application
that both serves static HTML, JavaScript, CSS content, and also
publishes a REST web service. The example uses Jersey and Jetty. This
example probably deserves a few posts to allow enough time to
explain how the pieces fit together, so I'll start with the primary
Java pieces that make a JAX-RS application.

A couple years back, while I was working through some slides to teach a
Java class (mostly Java EE and Spring) I created a REST web service using
Spring WebMVC. I wrote a few posts (starting [here][p1]) about how it
works.

I've recently been teaching that class again, updating to later versions of
Java and later versions of libraries. When I got to the Spring WebMVC class, I
wanted to teach it, because I still think it's a good choice for an
application that uses the Spring framework (because it integrates with Spring
dependency injection). But of course now we have the Java API for RESTful Web
Services (JAX-RS) as an option.

So I've adapted the previous example to JAX-RS. Fortunately, some of the little
tricks used with the Spring WebMVC application still apply.

Provider Class
--------------

JAX-RS divides the work of the REST web service amongst one or more provider
classes. Each provider class handles a set of paths within the whole application,
and each provider class can have multiple methods that handle specific paths and
HTTP methods.

Provider classes are plain old Java objects (POJOs), using annotations to specify
JAX-RS parameters. Here is the provider class for this application.

{% highlight java linenos %}
@Path("/calculator")
public class Calculator {

    @GET
    @Path("/calc/{op}/{left}/{right}")
    public Calculation calculate(@PathParam("op") String op, @PathParam("left") Integer left,
            @PathParam("right") Integer right) {
        Calculation result = new Calculation();
        result.setOperation(op);
        result.setLeft(left);
        result.setRight(right);
        return doCalc(result);
    }

    @POST
    @Path("/calc2")
    public Calculation calculate(Calculation calc) {
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

The example illustrates both `GET` and `POST` HTTP methods, and illustrates
passing in parameters, either via components of the URL or via the request
body.

The key annotations used above are:

* `@Path`: Adds a path component for matching the incoming URL. Path components
  are cumulative, so the class annotation and the method annotation work together.
  The path can contain templates used to supply parameters.
* `@GET`: Specifies a method that handles HTTP GET requests.
* `@POST`: Specifies a method that handles HTTP POST requests.
* `@PathParam`: Associates a template in the URL with a method parameter.

Not illustrated in this example is `@QueryParam`, which works similar to
`@PathParam` but instead matches a form input (either encoded in the URL as
`?name1=value1&name2=value2` pairs, or in a `name=value` list with linebreaks
in the request body).

For those familiar with Spring WebMVC, note that the annotations are quite
similar.  Also note that some annotations, like `@RequestBody` and
`@ResponseBody` to specify that the request body should be converted to a
parameter, or the returned Java object should become the response body, are
assumed rather than specified.

JAX-RS Application
------------------

The JAX-RS application class allows, among other things, customizing which
packages are scanned for providers.

{% highlight java linenos %}
public class CalculatorApp extends ResourceConfig {

    public CalculatorApp() {
        packages("org.anvard.jaxrs");
    }
}
{% endhighlight %}

`ResourceConfig` is a Jersey class that extends from the standard JAX-RS
`Application` class and provides package scanning and other helper
applications. It also provides an implementation for the standard
`getClasses()` and `getSingletons()` methods that we would otherwise have to
supply ourselves.

web.xml
-------

While it is possible with Servlet 3.0 to deploy applications without use of a deployment
descriptor, it makes it easier to connect Jetty with Jersey when running using the
Maven Jetty plugin.

{% highlight xml %}
<?xml version="1.0" encoding="ISO-8859-1"?>
<web-app version="3.0" xmlns="http://java.sun.com/xml/ns/javaee"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd">

    <servlet>
        <servlet-name>Calculator</servlet-name>
        <servlet-class>org.glassfish.jersey.servlet.ServletContainer</servlet-class>
        <init-param>
            <param-name>javax.ws.rs.Application</param-name>
            <param-value>org.anvard.jaxrs.server.CalculatorApp</param-value>
        </init-param>
    </servlet>
    <servlet-mapping>
        <servlet-name>Calculator</servlet-name>
        <url-pattern>/rest/*</url-pattern>
    </servlet-mapping>
</web-app>
{% endhighlight %}

This configuration uses a servlet provided by Jersey to delegate to the JAX-RS
application class we defined earlier. This also allows us to specify the first
component of the path for JAX-RS services (to keep them distinct from static
files, which we also want to serve).

Deploying and Running
---------------------

The Maven POM file handles building a JAR (for a standalone application, discussed
in the next post), and a WAR (for deploying to a Servlet container). It also
includes the Maven Jetty plugin, allowing us to run the application from the
command line using `mvn jetty:run`.

Client Requirements
-------------------

The example includes both JavaScript and Java clients, which I will discuss in
another post. Any Web client can of course be used, but note that this REST
service is careful about responding to clients. 

We list a dependency on the Jersey plugin for Jackson, so we can move between
Java and JSON. However, the client must specify the header `Accept: application/json`;
otherwise, the server defaults to XML. Also, when supplying data to the server for
the POST request, the client must also specify a `Content-Type: application/json`
header.

Next Steps
----------

The next post will provide detail on running the service in a regular Java application
using an embedded Jetty server.

[gh]:https://github.com/AlanHohn/jaxrs
[p1]:{% post_url 2013-09-16-webmvc-server-1 %}

