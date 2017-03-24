---
layout: post
title: "Table Driven Tests in Go"
description: ""
category: articles
tags: []
---

*tldr*For a Java programmer, transitioning to Go can evoke
"Where's My JUnit?" Fortunately Go has both a built-in testing
library and a very smooth way to write tests idiomatically.*/tldr*

I've started working in [Go][] both professionally and personally
and have enjoyed the experience. One reason is that Go takes a quite
different approach to Java in some areas, which makes switching between
the two a mind-expanding experience.

One such area is in unit testing. Go puts enough value on unit tests
to make testing a part of the standard library (including code coverage,
which I intend to discuss in the future). But the approach is different 
from a library like JUnit in that there are no assertions. Instead there
are just functions like `Errorf` to fail the test with a log message.

To write a unit test in Go, we create a Go file that ends in `_test.go`.
This file will not be built with the normal code, but will be inspected
for unit tests.  In this file, we write functions starting with `Test` that
take a single parameter, of [type][testing] `*testing.T`. For example:

```go
import "testing"

...

func TestValid(t *testing.T) {
   // Run tests
}
```

The function does not need a return type; if the function ends as expected,
the test passes. To fail the test, we use functions on the `*testing.T` type.
As mentioned above, this type does not provide "assertion" style functions;
instead there are functions that log errors and fail the test. For this reason,
Go tests use regular if/else expressions, such as:

```go
if err != nil {
    t.Errorf("Unexpected error for input %v: %v", tt.input, err)
}
```

This is more verbose than an assertion, but it has the advantage of being
more explicit. The code is comprehensible to anyone who understands the
language, and doesn't require learning a separate library. It also aligns
test code with regular Go code, since checking for things like non-nil
errors is a standard practice in Go (in place of the exception handling seen
in other languages).

To make up for the extra verbosity in checking for errors, Go encourages
[table driven testing][tt]. The idea is to build a data structure, usually a
slice, that contains test inputs and expected outputs, then to iterate over the
slice, testing each case.

While this kind of table-driven test is easy to do in other languages, such as
Java, it is made very simple in Go by the ability to declare and populate data
structures in a single statement. 

For example, to test a function that takes a string and returns an int, we can
declare the following [slice][]:

```go
var validTests = []struct {
    input    string
    expected int
}{
    {"", 0},
    {"I", 1},
}
```

The equivalent in Java would probably be done by declaring a class, then creating 
a static initializer to build a collection of instances of that class. Not
difficult, but more verbose.

The code to iterate over the table can be basic; of course, it needs to be tailored
to reflect how the code under test should be initialized and called.

```go
for _, tt := range validTests {
    res, err := RomanToInt(tt.input)
    if err != nil {
        t.Errorf("Unexpected error for input %v: %v", tt.input, err)
    }
    if res != tt.expected {
        t.Errorf("Unexpected value for input %v: %v", tt.input, res)
    }
}
```

This code takes advantage of Go's simple [iteration over slices][range]. The use of
`for _, tt` allows us to ignore the index of each item and just use the item
itself.

The best part about table-driven tests is that, once the test is written,
we can ignore the test method and just add cases to the table. Also, the
input and expected output are easily visible and associated together in the
test file. The downside is that we have to be careful crafting error messages
to make sure that it is clear exactly which test case is failing. It is also a
bit more difficult to create breakpoints on specific test cases.

To illustrate table-driven tests, I've created a small [GitHub repository][gh].
It contains a function that returns the numeric value for a Roman numeral in
string form. At the moment, the function handles valid strings, but lacks
checking for invalid strings. In a future article I'll use a table-driven test
to perform that type of testing as well.

[Go]:https://golang.org/
[tt]:https://github.com/golang/go/wiki/TableDrivenTests
[testing]:https://golang.org/pkg/testing/
[slice]:http://blog.golang.org/go-slices-usage-and-internals
[range]:https://tour.golang.org/moretypes/12
[gh]:https://github.com/AlanHohn/roman

