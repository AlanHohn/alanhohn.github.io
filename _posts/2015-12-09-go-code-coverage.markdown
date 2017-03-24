---
layout: post
title: "Building and Testing Go with GoClipse, Drone.io and Coveralls"
description: ""
category: articles
tags: []
---

In a [previous article][first] I showed building table-driven tests
in Go. I then added [another article][second] to cover testing error
conditions. Now that we have tests that cover all the cases, we
deserve to get some green badges on our GitHub repository.

To help illustrate these articles with a simple example, I've posted
a [repository on GitHub][gh] that converts Roman numerals in string
form into the numeric equivalent. I've added build support using
[drone.io][], and code coverage using [Coveralls][].

Before we get there, it's worth pointing out that Go has built-in support for
test code coverage. Here are the commands to fetch a code repository and run
its tests in verbose mode with code coverage enabled:

```bash
go get github.com/alanhohn/roman
go test -v --cover github.com/alanhohn/roman
```

This produces the following output:

```text
=== RUN   TestValid
--- PASS: TestValid (0.00s)
=== RUN   TestInvalid
--- PASS: TestInvalid (0.00s)
PASS
coverage: 100.0% of statements
ok      github.com/alanhohn/roman   0.009s
```

I've been using [GoClipse][], as I'm already familiar with Eclipse coming from
Java. It's built on Eclipse C/C++ Development Tools and can be configured with a
little effort to do source code debugging, though mostly I like it for code
completion and a familiar keyboard shortcut that runs `gofmt`. 

Because compiling and testing in Go is so fast, I configure GoClipse to run 
tests with code coverage on every save. This means I get instant feedback not just
on compile errors, but also on whether I've broken unit tests and how I'm doing on
coverage. Here's what that looks like:

<img src="/post-images/goclipse.png" style="max-width:100%;max-height:500px;"/>

Here I've customized the "run-tests" target to include "-cover". Also note the small 
blue checkmark on the "run-tests" entry in the Project Explorer; this indicates that
this build target will run automatically as part of the workspace build.

Now, to get those green badges. Adding a Go project to [drone.io][] from a
GitHub repository is a matter of logging in using GitHub credentials,
authorizing the application, clicking New Project, and selecting the
repository. The badge link in Markdown (under Settings / Status Badges) can be
added to the README.md file at the root of the Git repository. This will cause 
GitHub to display a status badge for the build.

To get a code coverage badge, I used [Coveralls][] with [goveralls][]. The goveralls
README provides instructions for drone.io. First, visit Coveralls, sign in using GitHub,
and authorize. Then, enable the repository. Copy the repo token from the right side
of the repository details page, and paste it into the Environment Variables settings
on drone.io for the repository (under Settings / Build &amp; Test):

```text
COVERALLS_TOKEN=(paste token here)
```

Finally, change the drone.io build commands to be:

```shell
go get
go build

go get github.com/axw/gocov/gocov
go get github.com/mattn/goveralls
goveralls -service drone.io
```

As with drone.io, the Coveralls repository page provides a Markdown link for a readme
badge. Once everything is done, and the updated README.md is pushed to GitHub, the
GitHub page should show something like this:

<img src="/post-images/build-passing.png" style="max-width:75%;max-height:250px;"/>

These badges will update automatically when new changes are pushed.  In
addition to the badges, drone.io and Coveralls will keep detailed information
on builds; for an example, see the [drone.io build history][drone-repo] and
[Coveralls build history][cover-repo] for my Roman numeral repository.

Now that these tools are up and running they are a great help in repository
management. Both tools can be configured to send email alerts, as well as build
pull requests and report back results to the pull request itself. Coveralls
will even let you configure a threshold for coverage decrease in order to
automatically fail a pull request that adds too much untested code.

[first]:https://dzone.com/articles/table-driven-tests-in-go
[second]:https://dzone.com/articles/covering-error-cases-in-go-unit-tests
[gh]:https://github.com/AlanHohn/roman
[drone.io]:https://drone.io/
[Coveralls]:https://coveralls.io/
[Goclipse]:http://goclipse.github.io/
[goveralls]:https://github.com/mattn/goveralls
[drone-repo]:https://drone.io/github.com/AlanHohn/roman
[cover-repo]:https://coveralls.io/github/AlanHohn/roman

