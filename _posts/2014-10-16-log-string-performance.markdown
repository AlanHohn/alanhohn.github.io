---
layout: post
title: "Logging Performance"
description: "Measuring string concatenation in logging"
category: articles
tags: [java, slf4j, logging, benchmark]
---

Introduction
------------

I had an interesting conversation today about the cost of using string
concatenation in log statements. In particular, debug log statements
often need to print out parameters or the current value of variables,
so they need to build the log message dynamically. So you wind up with
something like this:

{% highlight java %}
logger.debug("Parameters: " + param1 + "; " + param2);
{% endhighlight %}

The issue arises when debug logging is turned off. Inside the `logger.debug()`
statement a flag is checked and the method returns immediately; this is
generally pretty fast. But the string concatenation had to occur to build
the parameter prior to calling the method, so you still pay its cost. Since
debug tends to be turned off in production, this is the time when this
difference matters.

For this reason, we have pretty much all been trained to do this:

{% highlight java %}
if (logger.isDebugEnabled()) {
  logger.debug("Parameters: " + param1 + "; " + param2);
}
{% endhighlight %}
  
The discussion was about how much difference this "good practice" makes.

Caliper
-------

This kind of question is perfect for a micro benchmark. My own favorite
tool for this purpose is [Caliper][]. Caliper runs small snippets of code
enough times to average out variations. It passes in a number of
repetitions, which it calculates in order to make sure that the whole method
takes long enough to measure given the resolution of the system clock. Caliper
also detects garbage collection and hotspot compiling that might impact the
accuracy of the tests.

Caliper uploads results to a Google App Engine application. Its sign-in supports
Google logins and issues an API key that can be used to organize results and list
them.

A typical timing methods looks like this:

{% highlight java %}
  public String timeMultStringNoCheck(long reps) {
    for (int i = 0; i < reps; i++) {
      logger.debug(strings[0] + " " + strings[1] + " " + strings[2] + " "
          + strings[3] + " " + strings[4]);
    }
    return strings[0];
  }
{% endhighlight %}

The return string is not used; it is included in the method solely to ensure that
Java does not optimize away the method. Similarly, the content of the variables
used should be randomly generated to avoid compile-time optimization.

The full example is available in [one of my GitHub repositories][gh], in the
`org.anvard.introtojava.log` package.

Results
-------

The outcome is pretty interesting.

![Benchmark Results](/post-images/2014-10-16-log-benchmark.png)

String concatenation creates a pretty significant penalty, around two orders
of magnitude for our example that concatenates five strings. Interesting is
that even in the case where we do not use string concatenation (i.e. the
`SimpleString` methods), the penalty is around 4x. This is probably the
time spent pushing the string parameter onto the stack.

The examples with doubles, using `String.format()`, is even more extreme,
four orders of magnitude. The elapsed time here about 4us, large enough 
that if the log statement were in a commonly used method, the performance hit 
would be noticeable. 

The final method, `MultStringParams`, uses a feature that is available in
the [SLF4J][] API. It works similarly to `String.format()`, but in a simple
token replace fashion. Most importantly, it does not perform the token replace
unless the logging level is enabled. This makes this form just as fast as the
"check" forms, but in a more compact form. 

Of course, this only works if no special formatting is needed of the log 
string, or if the formatting can be shifted to a method such as `toString()`. 
What is especially surprising is that this method did not show a penalty 
in building the object array necessary to pass the parameters into the method. 
This may have been optimized out by the Java runtime since there was no 
chance of the parameters being used.

Conclusion
----------

The practice of checking whether a logging level is enabled before building
the log statement is certainly worthwhile and should be something teams
check during peer review.

[Caliper]:https://code.google.com/p/caliper/
[SLF4J]:http://www.slf4j.org/
[gh]:https://github.com/AlanHohn/java-intro-course

