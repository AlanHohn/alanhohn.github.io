---
layout: post
title: "Minimal Docker Container"
description: "Tiny example Docker container written in Go"
category: articles
tags: [docker, golang]
---

Most Docker images start from the [Docker Hub][dh],
with its set of base OS images and application images
built from them. With Docker's layered architecture for
images, the fact that typical images are 50MB to 100MB
is not a major issue.

At the same time, there are uses for Docker where
building from scratch is desirable, and when building
from scratch, the image might as well be as small as
possible.

Of course, the reason the base OS images are the size
they are is because they include base utilities
and dynamically linked libraries. If our purpose is 
just to run a statically linked application, only the 
application file needs to be included in the Docker image.

The [Go programming language][golang] provides statically
linked executables (with the right compiler flags). I've
been working with Go and figured it would be interesting
to try out packing a small sample application into a
Docker container.

The Go application is basic:

{% highlight go linenos %}
package main

import (
        "fmt"
        "log"
        "net/http"
        "os"
)

func ArgServer(w http.ResponseWriter, req *http.Request) {
        fmt.Fprintln(w, os.Args)
}

func main() {
        http.Handle("/args", http.HandlerFunc(ArgServer))
        log.Fatal(http.ListenAndServe(":8080", nil))
}
{% endhighlight %}

This application uses the `net/http` library, which is
one library that Go potentially links dynamically, so 
it makes a good example for creating a statically 
linked Go executable. It also uses command-line arguments,
allowing those to be demonstrated as well.

To create a fully statically linked version of this application,
I used the following compile command:
{% highlight bash %}
CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w' ...argserver
{% endhighlight %}

According to [this article][a] this form only works with Go 1.3 or older, but
for me this command worked fine while running Go 1.5.1. 
If you do have trouble, the linked article suggests using `installsuffix` to keep static versions 
of components separate in newer versions of Go.

With the `argserver` executable and a Dockerfile in the current directory, this command
will create and tag our minimal Docker image:
{% highlight bash %}
docker build -t argserver .
{% endhighlight %}

Here is the Dockerfile:

{% highlight dockerfile %}
FROM scratch

ADD argserver /argserver

ENTRYPOINT ["/argserver"]

CMD ["a", "b", "c", "d"]
{% endhighlight %}

Note that we start from "scratch", we add only the single executable, and
we set it as the entry point. The `CMD` line provides default arguments
which we can override.

When running this image, it is necessary to expose port 8080 outside
the container so we can access the HTTP server:

{% highlight bash %}
docker run -d -p 8081:8080 argserver
{% endhighlight %}

This command will run the container in the background and map port 8081
on the host to port 8080 in the container. We can then access the HTTP
server:

{% highlight bash %}
> curl http://localhost:8081/args
[/argserver a b c d]
{% endhighlight %}

Or, we could override the command line args:
{% highlight bash %}
> docker run -d -p 8081:8080 argserver g h i j
> curl http://localhost:8081/args
[/argserver g h i j]
{% endhighlight %}

When testing this with Ubuntu Wily running Go 1.5.1, the resulting
Docker image was 4.9MB. Most of this is static libraries, so we
could add quite a bit more HTTP server functionality without the
image getting much larger.

[dh]: https://hub.docker.com/
[golang]: https://golang.org/
[a]:https://github.com/kelseyhightower/rocket-talk/issues/1

