---
layout: post
title: "Google Places client using Spring WebMVC"
description: "REST client using Spring RestTemplate"
category: articles
tags: [java, spring, webmvc, rest]
---

While giving a series of presentations on using Java in a distributed environment
(focusing on Java EE and Spring), I got a lot of interest in web programming. I
did an extra presentation on servlets, but I didn't want to leave it there, because
writing Java servlets directly is not very efficient compared to tools like Spring
WebMVC.

So I made an extra presentation on WebMVC, which led me to make a [sample application][webapp]
that provides both a client and a server using Spring WebMVC. I'll describe the
client and the server in subsequent posts, but first I want to talk about one
little extra package I included for the sake of the class.

Homemade examples with silly capabilities can be pretty boring. I still think it's
important to teach that way most of the time, because it avoids getting students hung
up in issues with the business logic when what you're trying to present is how the
integration takes place. So my example client and server provide the ability to submit
'add', 'subtract', 'multiply', and 'divide' jobs to a server, which returns the result.

I figured that would bore everyone to the extent that the power of Spring WebMVC wouldn't
come through. So I made an extra little client that queries Google's Places API for local
food shops. The key thing was to show a slightly more real-world example, and to also
show how easy WebMVC makes these things.

Even though I'm using Spring WebMVC for the client, I decided not to use a Spring
application context for this example, because it's too simple for that. So the
Java code just looks like this:

{% highlight java lineno %}
    private static final String URL = "https://maps.googleapis.com/maps/api/place/search/json?location={location}&radius=1000&types=food&sensor=false&key={key}";
    private static final String LOCATION = "39.016249,-77.122993";

public static void main(String[] args) {
    trustAllSSL();
    String key = args[0];
    RestTemplate tmpl = new RestTemplate();
    List<HttpMessageConverter<?>> converters = new ArrayList<HttpMessageConverter<?>>();
    converters.add(new MappingJacksonHttpMessageConverter());
    tmpl.setMessageConverters(converters);
    PlaceResponse response = tmpl.getForObject(URL, PlaceResponse.class,
            LOCATION, key);
    System.out.println(response);
}
{% endhighlight %}

The heavy lifting is done by Spring's [RestTemplate][]. It handles crafting the
HTTP GET, encoding the URL using the template provided, setting HTTP headers, and
doing whatever conversions are necessary for both request and response.

What comes back from Google's servers looks in part like this:

{% highlight json %}
    {
         "geometry" : {
            "location" : {
               "lat" : 39.024087,
               "lng" : -77.123862
            }
         },
         "icon" : "http://maps.gstatic.com/mapfiles/place_api/icons/cafe-71.png",
         "id" : "5ab64fcca2f315b207e56b22eddfb696d9cbfa44",
         "name" : "Starbucks",
         "opening_hours" : {
            "open_now" : true
         },
         "price_level" : 1,
         "rating" : 3.9,
         "reference" : "CnRmAAAAdb1p-Hs1Mafz8EE6J46k5pfUQBJfuTVr-pvQbD6p0ySZcr5kGWPyJIAya_sRLB8D2tM27D4kCl6rCN0jApXI6gx5w1Hf3edAGnhJmdwdSr-NgXPBxSKhOWqY3I2xFFh9ccg0VWs0tjBoK8cce5IIbRIQnZInW9WcIENOe-6NgIoLJxoUW2PwBB0XiaCwHuw5ird_0Z04qlw",
         "types" : [ "cafe", "food", "establishment" ],
         "vicinity" : "10251 Old Georgetown Road, Bethesda"
      },
{% endhighlight %}

You can see in the Java code that I've explicitly provided the template with a
message converter using [Jackson][]. In a future post I'll talk about the
registration happening automatically as part of Spring's annotation-driven
detection of REST endpoints.  The JSON response that comes back from Google's
servers is converted by Jackson into a `PlaceResponse` instance. The
`PlaceResponse` class is below; its helper classes are shown in the [webapp][].
What's nice is that the classes are just POJOs, though the names are a little
odd to match the JSON as this avoids some Jackson annotations.

{% highlight java linenos %}
package org.anvard.webmvc.googleplaces;

import java.util.List;
import org.codehaus.jackson.annotate.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class PlaceResponse {

    private List<String> html_attributions;
    private List<Place> results;
    private String status;
    
    public List<String> getHtml_attributions() {
        return html_attributions;
    }
    
    public void setHtml_attributions(List<String> html_attributions) {
        this.html_attributions = html_attributions;
    }

    public List<Place> getResults() {
        return results;
    }
    
    public void setResults(List<Place> results) {
        this.results = results;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("Status: " + status + "\n");
        if (null != html_attributions) {
            sb.append("Attributions:\n");
            for (String attr: html_attributions) {
                sb.append("  " + attr + "\n");
            }
        }
        if (null != results) {
            sb.append("Places:\n");
            for (Place place: results) {
                sb.append(place.toString() + "\n");
            }
        }
        return sb.toString();
    }
}
{% endhighlight %}

There's more in the JSON than I bothered to put into the Java classes, but
the Jackson annotation `@JsonIgnoreProperties(ignoreUnknown = true)` on the
class tells Jackson not to get worked up about that.

Because this is part of a larger sample app, I didn't go to the trouble of adding
to the `pom.xml` so it could be run from the command line. Also, in order to get
it to work, it's necessary to pass it a command-line parameter with your own 
[Google API key][gapi].

My original version used Ant with no dependency management, so I'm appreciative for
[an example][maven] of WebMVC with Maven. For some reason the computer on which I ran
the examples did not like the SSL certs from Google, so [this page][ssl] was a big help
too.

[maven]:http://www.mkyong.com/maven/how-to-create-a-web-application-project-with-maven
[ssl]:http://raymondhlee.wordpress.com/2012/07/28/using-spring-resttemplate-to-consume-restful-webservice
[webapp]:https://github.com/AlanHohn/webmvc
[jackson]:http://jackson.codehaus.org/
[resttemplate]:http://static.springsource.org/spring/docs/3.0.x/javadoc-api/org/springframework/web/client/RestTemplate.html
[gapi]:https://developers.google.com/api-client-library/python/guide/aaa_apikeys


