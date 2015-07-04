---
layout: post
title: "REST enabled Java app"
description: "Add REST to standalone Java with Jetty and Spring WebMVC"
category: articles
tags: [java, spring, webmvc, rest]
---

This is part 1 of 3. Also see [part2][p2] and [part3][p3].

[p2]:{% post_url 2013-09-17-webmvc-server-2 %}
[p3]:{% post_url 2013-09-18-webmvc-server-3 %}

There are a lot of tutorials out there about providing REST web services
in a servlet container by building and deploying a WAR. There are also
cases where someone is looking to put a REST interface on an existing
Java application. In that case it isn't always possible to turn the
application into a WAR or EAR and adding a servlet container as a
separate process just adds a layer of complexity.

At the time, I didn't see a good example that brought all the pieces
together for a standalone Java application that exposes REST interfaces
using Spring WebMVC. So I put together a [small example][webapp]. If
I'd looked harder, I would have found one, but now I've written it
and get to share it.

Even though the example is small, there are a number of moving parts, and
I want to do them justice. So I'm going to start by discussing the Spring
WebMVC configuration and move on from there in future posts.

One other thing I like about this example is that we can build up everything
required to actually make a WAR, but then run it as a standalone Java
application. I've always thought that to be one of the coolest things about
[Jenkins][] and I think it's a useful technique in general.

To begin, in order to make a webapp, we'll add a web.xml file. With Servlet
3.0 we could avoid having a web.xml, but it's nice to have one as it keeps
us compatible with Servlet 2.x. We're using Maven, so it goes in 
`src/main/webapp/WEB-INF`.

{% highlight xml %}
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE web-app PUBLIC 
 "-//Sun Microsystems, Inc.//DTD Web Application 2.3//EN" 
 "http://java.sun.com/dtd/web-app_2_3.dtd">
<web-app>

  <display-name>REST API</display-name>
  <description>Sample Spring WebMVC REST API</description>

  <servlet>
    <servlet-name>rest</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <load-on-startup>2</load-on-startup>
  </servlet>

  <servlet-mapping>
    <servlet-name>rest</servlet-name>
    <url-pattern>/rest/*</url-pattern>
  </servlet-mapping>

</web-app>
{% endhighlight %}

There's not much to this configuration. The main thing to note is that we're
not implementing a servlet ourselves; we're letting Spring WebMVC's
`DispatcherServlet` do the work. The `DispatcherServlet` does exactly what
it sounds like: it takes in requests and figures out where they should go.

In the same `WEB-INF` directory we now need to configure Spring WebMVC.
To do this we need a file called `rest-servlet.xml`:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  xmlns:context="http://www.springframework.org/schema/context"
  xmlns:mvc="http://www.springframework.org/schema/mvc"
  xsi:schemaLocation="
  http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
  http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-3.0.xsd
  http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc-3.0.xsd">

    <context:component-scan base-package="org.anvard.webmvc.server"/>
    <mvc:annotation-driven/>

</beans>
{% endhighlight %} 

The file name is important, as Spring WebMVC is going to look for a file with this name
because of the `<servlet-name>` we provided in `web.xml`. It's important to remember
to change one if you change the other.

This is a regular Spring XML configuration file. We could create arbitrary beans here,
link them together, configure transaction management, persistence, whatever we choose.
In this case, we're using two items that were added to Spring within the last few years
and relate to Spring's new annotation-driven configuration.

* `<context:component-scan>` tells Spring that rather than listing all the beans in
the XML file, we want it to scan the classpath. We give it a `base-package` to make
the search more efficient and to make sure it doesn't pick up things we don't want.
There are a number of Spring class-level annotations that will tell Spring that a
class should be instantiated as a bean, but for WebMVC purposes we will use `@Controller`.
* `<mvc:annotation-driven/>` tells Spring that as beans are added to the Spring 
application context, it should search them for WebMVC annotations in order to
find targets for the dispatcher. More on this next time, but there's also the
excellent Spring [reference documentation][springref].

As the name implies, Spring WebMVC is about bringing the model-view-controller design
pattern to web programming. Controllers handle requests, optionally pulling in data
from the model. As much as possible, the Spring framework itself handles the view,
which for REST interfaces mostly means converting to JSON or XML.

Our controller Java class looks like this:

{% highlight java linenos %}
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

Next time I'll talk in detail about the various WebMVC annotations and
how they're used to expose different types of REST interfaces. For today,
I want to finish with the point that this is a complete example of a
Spring WebMVC REST application. We could build a WAR with these three files
(and the Spring dependencies) and it would deploy to a servlet container
and expose REST interfaces. With the right dependencies, this example
will return XML or JSON to a client, depending on what the client 
requested.

[webapp]:https://github.com/AlanHohn/webmvc
[springref]:http://docs.spring.io/spring/docs/2.5.6/reference/mvc.html#mvc-annotation
[jenkins]:http://jenkins-ci.org/

