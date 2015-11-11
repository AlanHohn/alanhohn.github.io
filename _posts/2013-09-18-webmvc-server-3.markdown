---
layout: post
title: "REST enabled Java app, part 3"
description: "Embedded Jetty"
category: articles
tags: [java, jetty, rest]
---

This post is part 3 of a series that started [here][part1] and continued [here][part2].
There will be at least one more post in this series, to discuss Spring WebMVC as a
client. All of the code is available as a [project][webapp] on GitHub.

As I discussed previously, the Spring WebMVC example I provided is a complete
web application, with the three files `web.xml`, `rest-servlet.xml`, and the
controller class.

But one of the reasons I wanted to put together this example is to show the class
I was teaching the possibility of embedding this into an existing Java program. A REST
API for an existing capability is often a good way of moving a distributed client-server
application from Java-only to language-agnostic, and introducing a separate web container
like Tomcat can add complexity. Fortunately Jetty makes it quite easy to run an
embedded servlet container on any port from within a Java SE application.

Of course, there's an excellent `jetty-maven-plugin` that will run Jetty as if the
Maven `target` directory were an "exploded WAR". But in deployment, we don't want to
require Maven to still be around, so we want to do something similar using plain Java.

Embedded Server Class
---------------------

In the [webapp][] I have the following Java class:

{% highlight java %}
package org.anvard.webmvc.server;

import java.net.URL;
import java.security.ProtectionDomain;

import org.eclipse.jetty.server.Connector;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.ServerConnector;
import org.eclipse.jetty.webapp.WebAppContext;

public class EmbeddedServer {

    /**
     * @param args
     * @throws Exception
     */
    public static void main(String[] args) throws Exception {
        Server server = new Server();
        ServerConnector connector = new ServerConnector(server);

        connector.setPort(9999);
        server.setConnectors(new Connector[] { connector});

        WebAppContext context = new WebAppContext();
        context.setServer(server);
        context.setContextPath("/");

        ProtectionDomain protectionDomain = 
            EmbeddedServer.class.getProtectionDomain();
        URL location = 
            protectionDomain.getCodeSource().getLocation();
        context.setWar(location.toExternalForm());

        server.setHandler(context);
        while (true) {
            try {
                server.start();
                break;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        try {
            System.in.read();
            server.stop();
            server.join();
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(100);
        }
    }
    
}
{% endhighlight %}

Embedded Jetty Setup
--------------------

Here the embedded server happens in a `main`, but it could just as easily happen
in a regular Java class that's instantiated as one small part of a major program.
The first thing the code does is instantiate a Jetty `Server` class. Then, it
instantiates a server connector and tells it a port number. I've chosen to stay
away from the usual port 80 or 8080; we may have lots of Java programs that
each expose their own REST API. Also notice that we actually pass a connector
array to the server &mdash; a single Jetty server may have multiple server
connectors, each providing their own mechanism to route requests into the
server (e.g. HTTP, HTTP/S). 

The Jetty server is essentially just a dispatcher for requests. It dispatches
requests to a handler. In our example, we use a `WebAppContext` as a handler;
this is a class that supports a single web application. There are many other
types of Jetty handlers. For example, if we needed to support multiple
completely separate web application contexts within a single embedded Jetty
server, we could create a `ContextHandlerCollection` and add multiple
`WebAppContext` instances to it.

Since we create a single `WebAppContext` and tell it to use `/` as its
context path, it will try to handle everything from the context root. 
Lines 28-32 then tell the `WebAppContext` where it should search for
its `WEB-INF/web.xml` file, Java code, and static resources. Essentially, what
those three statements do is start from the `EmbeddedServer` class itself,
find the root of that classpath location, then convert it to URL form. This
might be a file URL for a regular directory, a file URL that provides an
entry into a JAR or WAR, or even something esoteric like an HTTP location.

The `WebAppContext` reads the `web.xml` and instantiates servlets. Any servlets
will then be used to handle matching requests. Requests that do not match a
servlet will be matched against the classpath for static resources. Anything
that hasn't matched by this point will be handed off to Jetty's default
handler, which provides a 404 response.

We can use this ability to match against static resources to include
ordinary HTML, JavaScript, or CSS in our web application. An example
can be seen with the `index.html` file in the sample application. However,
note that there is a potentially undesirable side effect, in that other
files included in the directory or archive can be accessed this way. This
applies to all files except for those in the `WEB-INF` directory; even the
Java class files can be downloaded. To see this, try accessing the URL
`http://<server>:<port>/clientContext.xml` when running the example
application. Fortunately, Jetty provides some limits to this; it does
not support relative paths that would allow us to access other locations
on the disk, and it will not follow softlinks.

Summary
-------

Hopefully these posts together have illustrated the power of Spring WebMVC
to "REST-enable" existing Java code, as well as the ability of Jetty to
"web-enable" an existing Java SE application. These two technologies
are independent but work well when combined together.

This post ran long, and I still need to cover the client, so there will be
at least one more post. I'd also like to discuss techniques for applying
WebMVC to existing Java applications that might not be using Spring.

[part1]:{% post_url 2013-09-16-webmvc-server-1 %}
[part2]:{% post_url 2013-09-17-webmvc-server-2 %}
[webapp]:https://github.com/AlanHohn/webmvc



