---
layout: post
title: "Jetty Proxy Servlet"
description: "HTTP and HTTP/S proxies with Jetty"
category: articles
tags: [jetty, proxy, rest, jquery]
---

Introduction
------------

I've [talked][part3] [before][jettyssl] about Jetty as an embedded servlet
container. Jetty also includes some useful utility servlet implementations,
one of which is `ProxyServlet`.

`ProxyServlet` is a way to create an HTTP or HTTP/S proxy in very few lines
of code. Even though it's part of the Jetty project, it's modularized to be
independent of the Jetty server, so you can use it even in cases where the
servlet won't be run in Jetty.

Motivation
----------

Why might you need a proxy servlet? One reason is to address issues raised by
the [same origin policy][sameorig]. In general, a script loaded from one site
is not allowed to make requests from a different site. While it is possible
to work around this (for example using [JSONP][]) I tend to think a proxy
is a more elegant solution as it doesn't require exploiting a hole to download
and evaluate arbitrary JavaScript. 

A proxy might also be useful to allow a user to access a web service without
providing all the information necessary to access it. In our example, we'll
be providing a proxy for Google's Places API without having to send the
Google API key down to the browser.

The proxy we'll be looking at is a per-request proxy, so it's not something
that could conveniently be used for caching remote server responses in case of
slow connections or server failures.

Example
-------

The example is part of the [Spring WebMVC application][webapp] I use to present
WebMVC and REST for a Java class. I've added the `PlacesProxyServlet` and a
basic HTML page to demonstrate fetching Google Places search results and using
them in jQuery.

Maven POM
---------

To get started, we need `jetty-proxy` in our `pom.xml`. Prior to Jetty 9, the
`ProxyServlet` class lived in `jetty-servlets`, but it's been moved, probably to
reduce the other Jetty dependencies that have to be pulled in.

{% highlight xml %}
<dependency>
    <groupId>org.eclipse.jetty</groupId>
    <artifactId>jetty-proxy</artifactId>
    <version>${jetty.version}</version>
</dependency>
{% endhighlight %}

Java
----

Next, we create a class that extends `ProxyServlet`. We need to know the right
URI to use for Google Places, and we need a Google API key. The best way to
handle this is to allow them to be passed in from the servlet context using
`init-param`, but I like to also allow them to be overridden using Java system
properties. We start by overriding the `init()` method:

{% highlight java %}
public void init() throws ServletException {
    super.init();
    ServletConfig config = getServletConfig();
    placesUrl = config.getInitParameter("PlacesUrl");
    apiKey = config.getInitParameter("GoogleApiKey");
    // Allow override with system property
    try {
        placesUrl = System.getProperty("PlacesUrl", placesUrl);
        apiKey = System.getProperty("GoogleApiKey", apiKey);
    } catch (SecurityException e) {
    }
    if (null == placesUrl) {
        placesUrl = "https://maps.googleapis.com/maps/api/place/search/json";
    }
}
{% endhighlight %}

To actually proxy the requests, the key method is `rewriteURI`.  Again, this is
new to Jetty 9; previously there was a method called `proxyHttpURI` that
accomplished pretty much the same function.

{% highlight java %}
protected URI rewriteURI(HttpServletRequest request) {
    String query = request.getQueryString();
    return URI.create(placesUrl + "?" + query + "&key=" + apiKey);
}
{% endhighlight %}

This method returns the "real" URI that the Jetty proxy servlet will call. All of
the data from the client request is available. In this case, we just need the
browser's query parameters so we can pass them on to Google Places. 

Tweaks
------

To actually get this to work with the Google Places API, there were a couple other
changes required. First, the Places API enforces HTTP/S. Note that this doesn't mean
that our client has to connect to our proxy servlet using HTTP/S; regular HTTP is
perfectly fine for that connection because our proxy servlet is making a brand new
HTTP/S connection (using Jetty's `HttpClient` class). However, it does mean that we
need to tell the Jetty `HttpClient` that it's OK to use HTTP/S. We do this by
overriding the method that the `ProxyServlet` class uses to make a new `HttpClient`:

{% highlight java %}
protected HttpClient newHttpClient() {
    SslContextFactory sslContextFactory = new SslContextFactory();
    HttpClient httpClient = new HttpClient(sslContextFactory);
    return httpClient;
}
{% endhighlight %}

Second, Google Places didn't like the fact that the Jetty proxy servlet adds a
`Host` header to the request with the name of the originating server. With this
header, the Google Places server returns 404 in response to the request.
Fortunately, this is easy to fix; we just have to remove that header before the
request goes out.  We can do this by overriding the `customizeProxyRequest`
method that `ProxyServlet` thoughtfully provides for just such a problem:

{% highlight java %}
protected void customizeProxyRequest(Request proxyRequest,
        HttpServletRequest request) {
    proxyRequest.getHeaders().remove("Host");
}
{% endhighlight %}

Updates to `web.xml`
--------------------

To get this servlet up and running, we need to add it to `web.xml`. In the case of
the example application, this required updating to Servlet 3.0, since the Jetty proxy
servlet wants to use asynchronous connections. This is a good thing in terms of
increasing the number of simulataneous requests the proxy servlet can process, but it
requires enabling that feature in `web.xml`:
{% highlight xml %}
<servlet>
    <servlet-name>PlacesProxy</servlet-name>
    <servlet-class>org.anvard.webmvc.server.PlacesProxyServlet</servlet-class>
    <init-param>
      <param-name>GoogleApiKey</param-name>
      <param-value>YOUR_KEY_HERE</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
    <async-supported>true</async-supported>
</servlet>

<servlet-mapping>
    <servlet-name>PlacesProxy</servlet-name>
    <url-pattern>/places</url-pattern>
</servlet-mapping>
{% endhighlight %}

The `async-supported` tag is important; the proxy servlet won't work without it.

Browser interface
-----------------

On the browser side, we need a way to query and then display the results. I cannibalized
some example HTML and JavaScript I had lying around that did something similar with
CometD. (Unfortunately, I can't find the original source to provide a linkback.) The
relevant jQuery part looks like this:

{% highlight html %}
$.getJSON("/places?location=39.016249,-77.122993&radius=1000&types=food&sensor=false",
    function ( data ) {
        console.log( data );
        for (i = 0; i < data.results.length; i++) {
            result = data.results[i];
            $('<li>').html(result.name + '<br>' + result.vicinity).appendTo('#contentList');
        }
    })
    .fail(function() {
        console.log( "error" );
    })
    .always(function() {
        $("#status").text("Complete.");
    });
{% endhighlight %}

The jQuery makes an AJAX call to the proxy servlet, which then makes a call to Google Places.
The resulting JSON response data is sent through as-is. The (anonymous)
"success" function then gets called. It iterates through the returned results,
adding `<li>` tags to the existing list for each result it finds.

Conclusion
----------

Of course, a proxy servlet doesn't have to be used for sites on the Internet. One of my
motivations for creating the [example application][webapp] was to show how easy it was to
REST-enable an existing standalone Java application. Many systems that use Java have multiple
standalone Java applications, each performing some independent function. This would make it
challenging to create a single unified web interface while still allowing each application to
define its own REST API. Proxy servlets can help by making it look like there's a single
endpoint for all the various APIs, while not requiring any logic that knows about the contents
of the interfaces.

[sameorig]:http://en.wikipedia.org/wiki/Same_origin_policy
[JSONP]:http://en.wikipedia.org/wiki/JSONP
[part3]:{% post_url 2013-09-18-webmvc-server-3 %}
[jettyssl]:{% post_url 2013-10-05-jetty-ssl-server %}
[webapp]:https://github.com/AlanHohn/webmvc

