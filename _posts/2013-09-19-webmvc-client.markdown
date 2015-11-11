---
layout: post
title: "REST enabled Java app, part 4"
description: "WebMVC client"
category: articles
tags: [java, webmvc, rest]
---

This is part 4 of a series discussing a sample [webapp][] that uses
Spring WebMVC and Jetty to add a REST API to a standalone Java application.
[Part 1][part1], [Part 2][part2], and [Part 3][part3] were posted previously.

This post discusses using Spring WebMVC for the client side, and also
discusses some integration options for adding WebMVC to an existing application.

WebMVC Client
-------------

Of course, one of the largest motivations for a REST API is the ability to use
it from any language, especially JavaScript in a browser. But there are
times when consuming a REST API from Java can be very useful. HTTP is popular
for client / server integration because firewalls are generally permissive,
which is not true for Java RMI or most uses of JMS. Also, if an application
must support a REST interface anyway, using that same REST interface for Java
clients avoids the work of maintaining two remote interfaces. Of course, as in
anything there are tradeoffs. Sending JSON over the wire is more verbose than a
typical serialized Java object, and the latency introduced by marshalling and
unmarshalling must be considered.

Spring WebMVC provides a class called `RestTemplate` to simplify calling REST
APIs from Java. This follows a typical Spring design pattern where a complex
API is made more accessible through a template class (other examples include
`JdbcTemplate` and `JmsTemplate`). 

Our example client uses Spring to instantiate the `RestTemplate`, with this
XML configuration file:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
xsi:schemaLocation="
http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">

  <bean id="restTemplate" 
    class="org.springframework.web.client.RestTemplate">
    <property name="messageConverters">
      <list>
        <bean 
          class="org.springframework.http.converter.json.MappingJacksonHttpMessageConverter"/>
      </list>
    </property>
  </bean>
    
  <bean id="client" class="org.anvard.webmvc.client.RestClient">
    <property name="tmpl" ref="restTemplate"/>
    <property name="host" value="localhost"/>
    <property name="port" value="9999"/>
  </bean>
    
</beans>
{% endhighlight %}

Unlike the server side discussed in [Part 2][part2], the client side does not use
annotation-driven configuration, so we register the Jackson JSON conversion
library explicitly.

The associated Java code is as follows:

{% highlight java %}
package org.anvard.webmvc.client;

import org.anvard.webmvc.api.Calculation;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.springframework.web.client.RestTemplate;


public class RestClient {

    private RestTemplate tmpl;
    private String host;
    private String port;

    public Calculation calc(String op, int left, int right) {
        return tmpl.getForObject(getUrlRoot() + "rest/calc/{op}/{left}/{right}", Calculation.class, op, left, right);
    }
    
    public Calculation calc2(Calculation in) {
        return tmpl.postForObject(getUrlRoot() + "rest/calc2", in, Calculation.class);
    }
    
    public static void main(String[] args) {
        ApplicationContext ctx = new ClassPathXmlApplicationContext("/clientContext.xml");
        RestClient client = (RestClient) ctx.getBean("client");
        client.print(client.calc("add", 2, 2));
        client.print(client.calc("subtract", 20, 2));
        client.print(client.calc("multiply", 5, 3));
        client.print(client.calc("divide", 20, 2));

        client.print(client.calc2(new Calculation("add", 50, 50)));
        client.print(client.calc2(new Calculation("subtract", 60, 40)));
        client.print(client.calc2(new Calculation("multiply", 25, 12)));
        client.print(client.calc2(new Calculation("divide", 16, 5)));
    }

    ...

}
{% endhighlight %}

The `print(...)` method and setter methods have been omitted for clarity.

The [javadocs][rtdocs] for `RestTemplate` list other methods that are available;
here we display the two primary ones, `getForObject` and `postForObject`. Both
require a URL in string form as the first parameter. These URL strings support
path variables similar to what we saw on the server side in [Part 2][part2]; however,
in this case the path variables are matched in order; the label in the curly brace
is not used.

The `postForObject` method has an extra parameter inserted next, which is the
request body. Next is the expected type for the response body, followed by a
variable number of parameters that match to the path variables in the URL.

Obviously, each call to the `RestTemplate` is making a network connection, so care
should be taken to make sure the call happens on a thread that can block without
slowing down the application, and to make sure that possible network or server
failures are handled.

Integration
-----------

This example shows adding a REST API to an existing Java SE application. For
the application to be modular, it is necessary to separate the Spring WebMVC
controller from other application classes, such as database access objects or
server-side business logic. This raises issues with integration since the
application may not be based on similar technology. 

For WebMVC clients, this integration is simple. The example application uses
a Spring XML configuration file, but it is simple to replace this with a 
direct instantiation of `RestTemplate` wherever it will be used. The sample
Google Places client discussed [in a previous post][googleplaces] shows this.

For the server side, generally our goal will be to provide the Spring WebMVC
controller class with a reference to application business logic. The business
logic can get a reference to the controller class, but this is generally not
necessary since as requests flow in from the client, the controller class is
invoked automatically by Spring WebMVC.

For complete Spring applications, this integration can be done by combining
all beans into a single application context.  Any existing application context
can be included from the WebMVC XML configuration file (since this file is read
automatically by Spring when the `DispatcherServlet` is created). This approach
would break model-view-controller separation if we were writing a fully-fledged
web application, but since in this case we're just adding a REST API on
existing business logic, it's defensible from a design standpoint.

However, in many cases the application will not be Spring-based, or merging the
application contexts may be undesirable. This makes integration more
challenging. There are a few ways to proceed: 

1. A factory class can be used by Spring beans to instantiate or lookup objects
   in the application. This can be done either directly in Java code or through
   a Spring `FactoryBean`.
2. The Spring beans can register themselves in a separate registry which is
   used by the application to lookup the WebMVC controllers and inject
   application references.
3. A Spring bean can be added that implements `ApplicationContextAware` to get
   a direct reference to the Spring application context and store it in a
   registry. This context can then be used to look up any desired bean by name or
   type. [Here][appctxaware] is an example.
4. While I have illustrated a `DispatcherServlet` and its ability to search for
   a Spring XML configuration file using a naming convention, it is also
   possible to use Spring's `ContextLoaderListener` to load an application context
   in a servlet environment. 

The last method deserves an expanded discussion. Unlike the
`DispatcherServlet`, when the `ContextLoaderListener` creates its application
context, it registers it as the root context. This means it's possible to use
`getWebApplicationContext(servletContext)` in `WebApplicationContextUtils` to
retrieve it. (In the case of our embedded Jetty example, we can obtain the
servlet context easily from the `WebAppContext` we instantiate.) 

From a design standpoint, using a `ContextLoaderListener` has the advantage
that it lets us use multiple instances of `DispatcherServlet` to handle
separate web applications, each of which will have its own path and its own
Spring context, and all of which can access the 'common' beans in the root
context. The disadvantage is that we add some complexity to our configuration.
A good discussion of the difference can be found
[here](http://stackoverflow.com/questions/9016122/contextloaderlistener-or-not).

Any of these four methods will work. The first two methods allow us to avoid
spreading Spring-related dependencies further in our code. The last method
provides the most flexibility.

Summary
-------
Through these posts we've seen how Spring WebMVC and Jetty can be combined to
add a REST API to an existing application with very few lines of code, and
without requiring a servlet container to be added to the architecture.

[rtdocs]:http://docs.spring.io/spring/docs/3.0.x/javadoc-api/org/springframework/web/client/RestTemplate.html
[part1]:{% post_url 2013-09-16-webmvc-server-1 %}
[part2]:{% post_url 2013-09-17-webmvc-server-2 %}
[part3]:{% post_url 2013-09-18-webmvc-server-3 %}
[googleplaces]:{% post_url 2013-09-16-webmvc-googleplaces %}
[webapp]:https://github.com/AlanHohn/webmvc
[appctxaware]:http://blog.jdevelop.eu/?p=154

