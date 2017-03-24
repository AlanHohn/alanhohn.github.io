---
layout: post
title: "Testing REST services with pyresttest"
description: ""
category: articles
tags: []
---

Early in my career, someone explained to me why "ping" is such
a natural first test when something goes wrong with an application
or service. It's not just because it's a basic test with a quick
yes/no answer. It's also because it bisects the standard network
stack. If "ping" works, the issue is usually above the IP layer;
if not, the issue is usually below (firewalls being the exception).

Similarly, when I recently spent some time creating a "smoke test"
for an application deployment, I wanted something that would check
if the application was up and running, without checking any complex
behavior. The idea is to separate issues with the application itself
from issues with the deployment or the build process.

It only took a little bit of looking to come across [pyresttest][1].
It's a small Python library with an impressive amount of functionality
that goes beyond just checking if a REST service is up to checking
that it is behaving correctly. In this article I want to describe a
little basic functionality.

[1]:https://github.com/svanoort/pyresttest

The website has installation instructions, but for the most part it's
as simple as `pip install pyresttest`. At that point, we need to provide
tests in the form of YAML files. The syntax is then:

```shell
pyresttest url yaml-file
```

The URL parameter is used as the base; the tests themselves of course
provide a more specific path. Here are some examples, using [httpbin][2]
to make it easy to try these out.

[2]:http://httpbin.org/

First, we'll start with just a basic test, the equivalent of a ping
for HTTP. The idea is to not get bogged down in error messages from a more
complex test if the issue is basic.

```yaml
---
- test:
    - name: "Connectivity"
    - url: "/get"
```

If we run this, e.g. `pyresttest http://httpbin.org httpbin.yaml`,
we get the following output:

```
Test Group Default SUCCEEDED: : 1/1 Tests Passed!
```

If the server isn't available, e.g. `pyresttest http://bad httpbin.yaml`,
we get:

```
ERROR:Test Failed: Connectivity URL=http://bad/get Group=Default HTTP Status Code: None
ERROR:Test Failure, failure type: Curl Exception, Reason: Curl Exception: (6, 'Could not resolve host: bad')
ERROR:Validator/Error details:Traceback (most recent call last):
  File "/usr/local/lib/python2.7/site-packages/pyresttest/resttest.py", line 351, in run_test
    curl.perform()  # Run the actual call
error: (6, 'Could not resolve host: bad')

Test Group Default FAILED: : 0/1 Tests Passed!
```

As you can see, pyresttest is using Curl under the covers. The docs describe
how to customize the call to Curl.

A more complex test might check for a header in the response:

```yaml
- test:
    - name: "Expected header"
    - url: "/get?abc=def"
    - validators:
        - compare: {header: "content-type", expected: "application/json"}
```

There can be multiple validators for a test, and all must pass for the test
to be a success.

Of course, we can check for a specific value in the response body as well.

```yaml
- test:
    - name: "Expected JSON content"
    - url: "/get?abc=def"
    - validators:
        - compare: {jsonpath_mini: "args.abc", comparator: "eq", expected: "def"}
```

Note the ability to use dot notation to inspect inside deep data structures.
Square brackets also work for pulling data out of arrays and strings.

However, when writing a simple smoke test and dealing with an application that
returns dynamic data, we might want to check that it's present without getting
hung up on what the value is. That way our tests are less fragile. There are
a couple ways to do that:

```yaml
- test:
    - name: "Expect a field to be present"
    - url: "/get?abc=def"
    - validators:
        - compare: {jsonpath_mini: "args", comparator: "contains", expected: "abc"}

- test:
    - name: "Expected return type"
    - url: "/post"
    - method: "POST"
    - headers: {Content-Type: application/json}
    - body: '{"abc": "def"}'
    - validators:
        - compare: {jsonpath_mini: "args", comparator: "type", expected: "map"}
```

In the first example, we're just verifying that the 'args' field contains a field
called 'abc'; we don't care what the value is. In the second example, the check
is even simpler; we're just verifying that "args" is present and is a JSON object.
(The list of types to match is in [the advanced docs][3].)

[3]:https://github.com/svanoort/pyresttest/blob/master/advanced_guide.md

I found this last approach very useful for writing a basic test with Kubernetes,
where the goal was to make sure that at least one pod was running. 

Overall, we've found pyresttest to be quick to use and easy to learn, making it
a great choice for testing REST services without having to create any custom code.

