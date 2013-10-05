---
layout: post
title: "Embedded Jetty and SSL"
description: "Adding SSL support to an embedded Jetty server"
category: articles
tags: [jetty, embedded, rest, ssl]
---

As I discussed in a series of four posts (see [Part 1][part1], [Part 2][part2],
[Part 3][part3], and [Part 4][part4]), I recently taught a class on Spring
WebMVC and how it can be used to REST-enable a standalone Java application. As
part of that discussion, I talked about using Jetty as an embedded servlet
container, which let us create and access servlets without having to package
our existing application as a WAR.

The embedded Jetty example I gave was HTTP only. However, many production
applications that expose REST interface are going to want to secure those with
some kind of authentication and protect the exchanged information using HTTP/S.
I'll visit the authentication sometime in the future as I get time to work it,
but I'd like to talk about what's required to get HTTP/S working with embedded
Jetty.

The first thing we'll need is a server-side certificate. This contains the
public key that the client will use to encrypt its initial communication with the
server, in order to establish the session key that will be used to encrypt the
regular web traffic.

In a production system, the server's certificate will need to be signed by
an authority the client will trust. If both server and client are in the same
organization, this can be accomplished by just putting the server certificate
in the client's keystore. Otherwise, the whole process of getting a certificate
signed by a signing authority (Thawte, Verisign, etc.) is involved. This
process is exactly the same for Java servers as it is for other web servers, so
there are lots of posts on the subject.

For this example, we'll use a self-signed certificate. We want to keep the
certificate with our application so we don't have to worry about adding it to
the default Java keystore if we run the server on a new machine. This is easy;
just specify a new keystore file when we generate the key using the `keytool`
utility that ships with the JDK. The command is:

{% highlight text %}
keytool -genkey -alias sitename -keyalg RSA -keystore keystore.jks -keysize 2048
{% endhighlight %}

This will provide a series of prompts. For a self-signed certificate the responses
aren't terribly important. I answered "Jetty Example" for the first, 123456 for
the keystore password, and accepted the default for the others. The resulting
`keystore.jks` file can be seen in the `src/main/java` path of the [example
application][webapp]. The location is important as it enables us to find it
no matter where the application is run. However, it does have the side effect
of making it visible to a client browser, which may be undesirable.

The required changes to our `EmbeddedServer` class are minimal. Jetty has a lot
more options, but these are the set we need to make it happen.

{% highlight java linenos %}
Server server = new Server();

ServerConnector connector = new ServerConnector(server);
connector.setPort(9999);

HttpConfiguration https = new HttpConfiguration();
https.addCustomizer(new SecureRequestCustomizer());

SslContextFactory sslContextFactory = new SslContextFactory();
sslContextFactory.setKeyStorePath(EmbeddedServer.class.getResource(
        "/keystore.jks").toExternalForm());
sslContextFactory.setKeyStorePassword("123456");
sslContextFactory.setKeyManagerPassword("123456");

ServerConnector sslConnector = new ServerConnector(server,
        new SslConnectionFactory(sslContextFactory, "http/1.1"),
        new HttpConnectionFactory(https));
sslConnector.setPort(9998);

server.setConnectors(new Connector[] { connector, sslConnector });
{% endhighlight %}

We keep the previous connector on port 9999 so we can support both HTTP
and HTTP/S. Of course, we could force the use of HTTP/S by just removing
the HTTP connector.

The `HttpConfiguration` and `HttpConnectionFactory` are essential to making
this work. The `SslConnectionFactory` handles only the SSL part of the job;
it requires a regular HTTP configuration to hand off the decrypted request.

One other important point is the way we look up the keystore. This method
of getting the URL to a classpath resource will work whether the application
is being run from a JAR, WAR, or just classes on the disk. This lets us run
equally well inside an IDE like Eclipse and in the production environment.
It also avoids the extra install step of adding the server's certificate to
the default Java keystore.

With these changes, we can access the REST API equally well from
`http://<host>:9999` and `https://<host>:9998`.

[part1]:{% post_url 2013-09-16-webmvc-server-1 %}
[part2]:{% post_url 2013-09-17-webmvc-server-2 %}
[part3]:{% post_url 2013-09-18-webmvc-server-3 %}
[part4]:{% post_url 2013-09-19-webmvc-client %}
[webapp]:https://github.com/AlanHohn/webmvc
