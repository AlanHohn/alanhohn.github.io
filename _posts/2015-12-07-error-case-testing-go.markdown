---
layout: post
title: "Covering Error Cases in Go Unit Tests"
description: ""
category: articles
tags: []
---

In a [previous article][prev] I showed table-driven tests in Go, which are a
compact way to run lots of test cases. In this article I will show another
way to improve unit tests in Go: table-driven tests with invalid values.

To illustrate this, I've created an [example][ex] library in Go that
converts Roman numerals in string form to their numeric value. Of course,
not all strings are valid Roman numerals. In Go, functions typically return
an error value rather than throwing an exception. However, this is not done
using "special" return values as in C; instead, functions return multiple
values, one of which is an error value that is non-nil if an error occurred. 
Go provides an error type for use in these cases.

Here is an example from [the Go blog][gb]:

```go
func Sqrt(f float64) (float64, error) {
    if f < 0 {
        return 0, errors.New("math: square root of negative number")
    }
    // implementation
}
```

The `(float64, error)` indicates that the function returns both a value of type
`float64` and a value of type `error`. If the error value is non-nil, the
primary return value should be ignored.

Users of this function should check the error on return:

```go
result, err := Sqrt(-1.0)
if err != nil {
    // Don't use the result
    fmt.Println("I sent a bad input")
}
```

In a unit test, we want to ensure that errors that should be
returned are returned. To do this, we can again leverage a
table-driven test, with the input and the expected error.

For example:

```go
var invalidTests = []struct {
    input    string
    expected error
}{
    {"XXXX", ErrInvalidFormat},
    {"VV", ErrInvalidFormat},
    {"VX", ErrInvalidFormat},
}
```

The test code looks like this:

```go
func TestInvalid(t *testing.T) {
    for _, tt := range invalidTests {
        res, err := RomanToInt(tt.input)
        if err == nil {
            t.Errorf("Expected error for input %v but received %v", tt.input, res)
        }
        if err != tt.expected {
            t.Errorf("Unexpected error for input %v: %v (expected %v)", tt.input, err, tt.expected)
        }
    }
}
```

In the [example library][ex] I simplified this since all cases
resulted in the same error.

Similar to our previous use of table-driven tests, this allows us to add test
cases quickly and to easily see what error is expected for a given input. As before,
we need to be careful when logging any test failure to make sure we indicate which
test case failed and what we were expecting instead; otherwise debugging becomes
very difficult.

Now that we can test both normal and error cases, we can cover our entire Roman
numeral function. In the next article I will show how to turn that excellent
unit test code coverage into a green badge on a GitHub repository.

[prev]:https://dzone.com/articles/table-driven-tests-in-go
[ex]:https://github.com/AlanHohn/roman
[gb]:http://blog.golang.org/error-handling-and-go

