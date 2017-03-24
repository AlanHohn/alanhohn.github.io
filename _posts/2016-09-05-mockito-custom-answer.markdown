---
layout: post
title: "Mockito Custom Answers"
description: ""
category: articles
tags: []
---

In a [previous article][1] I introduced using Mockito to mock a
database by mocking all the classes involved in the JDBC API.
However, that simple example didn't include any complex cases, like
wanting the mocks to respond differently to different kinds of
inputs.

## Argument Matchers

Mockito argument matchers are very powerful. We saw a simple example
in the last article:

```java
when(rs.getString(2)).thenReturn(p.getFirstName());
```

This creates a rule in the mock object that is only invoked when the
`getString()` method is called with an argument of `2`. Otherwise
some other rule will fire, or Mockito will perform its default
(which generally means returning `null`).

We can do more than just supply a single argument. We can also supply
a matcher, which will be run against the argument. (When we specify a
static argument we are implicitly using the `eq()` matcher, which 
uses regular Java `equals()`.) Mockito has a number of matchers to
choose from and custom matchers are easy to write:

```java
// Emulate the real service error handling
when(svc.updateDistance(argThat(new ArgumentMatcher<Integer> {
  public boolean matches(Integer i) {
    return null != i || i < 0;
  }
}).thenThrow(new IllegalArgumentException());
```

## Applications

Our previous mocks were too simple in that they didn't ensure
anything about the query that was created and the parameters that
were passed in. We would like to ensure that our database access
code passes in the expected ID when retrieving data, that it
doesn't incorrectly hold onto any data, and that it correctly deals
with the case where the database doesn't return any results.

It might help to show the test we would like to write. Note that
there is nothing Mockito-specific about this test; we are just
describing our expectations after interacting with the code.

```java
	@Test
	public void wrongIdReturnsNull() throws Exception {
		PersonDao dao = new PersonDao(ds);
		dao.create(p);
		assertEquals(p, dao.retrieve(1));
		for (int i = 2; i < 10; i++) {
			assertNull(dao.retrieve(i));
		}
		assertEquals(p, dao.retrieve(1));
	}
```

We start with an empty table, add an item, and verify that only
the expected item is there. We also ensure that retrieving it the
first time wasn't a fluke.

To make this happen with Mockito, we are going to need a more
intelligent mock; it is going to have to know whether the "right" ID
was passed in to the prepared statement before it decides what kind
of result set to return.

## An Aside: Verify

Instead of doing things this way, we could write a similar test using Mockito's
`verify()` support. Mockito keeps a record of all method calls received by a
mock object and allows us to verify that the right calls were made:

```java
// Perform the action that causes the mock to be invoked
Person p = dao.retrieve(1);
// Check that it was invoked correctly
verify(stmt).setInt(1, 1);
```

This has the advantage of simplicity, and it's probably all we would
really need to test code as simple as my example. But it has the disadvantage
that you have to be careful how many things are interacting with your mock
objects, how many times, and potentially in what order. The result is that
it can contribute to the brittleness of the tests. So while it's a very good
approach, and the right approach for simple cases, it's worth knowing how
to do things another way as well.

## Argument Matching and Memory

So we would like to try to write this unit test using argument matchers.
However, the situation gets much more complicated than our custom argument
matcher above, because we are using prepared statements. As a result, the
parameters we are interested in are set in earlier methods, and the call to
`executeUpdate()` that actually returns the result set doesn't have any
parameters.

So what we need is a kind of "memory", where we store the argument that our
mock receives in one call and then use it to make a decision in a later call.
That ends up looking like this:

```java
		doAnswer(new Answer<Void>() {
			@Override
			public Void answer(InvocationOnMock invocation) throws Throwable {
				lastRetrieve = (int)invocation.getArguments()[1];
				return null;
			}
		}).when(retrieveStmt).setInt(eq(1), anyInt());

		when(retrieveStmt.executeQuery()).thenAnswer(new Answer<ResultSet>() {
			@Override
			public ResultSet answer(InvocationOnMock invocation) throws Throwable {
				return lastRetrieve == 1 ? rs : nullRs;
			}
		});
```

It's worth taking some time to unpack this. First, the `doAnswer()` bit.
Mockito's fluent API has some trickery associated with it, because from the
Java compiler's perspective, the mock object isn't special; it's just one more
object of whatever type we're mocking. Mockito can work around that when the
method we're configuring returns some value. But when it's a void method,
there's no way to attach the `OngoingStubbing` to anything. So Mockito provides
a slightly different syntax where we provide the outcome we want first, then we
specify the method and argument matcher last.

Specifying behavior for a void return isn't generally useful for a mock object,
since mostly we configure mocks to just return whatever is expected by the
code under test. But there is value in being able to look at incoming parameters
and throw exceptions, or in this case to save off the values that were passed in.

Once we've saved the ID that is being passed into the mock prepared statement,
we can use it to decide which result set to use. In this case, if the ID equals
1, we return a mock result that's configured to return content, and if it's
anything else, we return a mock result that's configured with no content.

One other note on the configuration above. We explicitly use `eq()` in the
`setInt()` matcher. Because of the way it's written internally, Mockito
either requires all of the parameters to be specified explicitly as argument
matchers, or none to be. So we could use `setInt(1, 1)` or `setInt(eq(1),
anyInt())`, but not `setInt(1, anyInt())`.

## Wrapping Up

Now that we have what we want for this unit test, we could expand this mocking
behavior pretty easily to provide different content for different IDs that are
passed in. Or we could configure it to only return the "record" from the
"table" in cases where it's been previously created. But at some point we would
move from checking out the code under test to checking out the behavior of the
mocks, which isn't really the purpose of this exercise.

That gets to an important rule about using mocking when testing, which is that
our focus needs to change a little. When integration testing, we want to make
sure that the collection of classes does the "right thing" at a macro level
(ultimately the right thing from the user's perspective). But when focusing on
a single class or method in unit testing, typically the "right thing" just
involves: handling error cases correctly; calling other methods as expected; and
returning expected values. The fact that our mock object would let us write a
test that pretended data was in the database before we inserted it doesn't
bother us in the slightest.

The above example barely scratches the surface of the advanced things we can do
with Mockito. The only downside is that the more of this kind of thing we do,
the less we are producing the kind of fluent configuration that makes Mockito
easy to work with and maintain. But for cases where we have to test interaction
between our code under test and a complex API, it's nice to have this kind of
access to the underlying behavior.

[1]:https://dzone.com/articles/mockito-basic-example-using-jdbc

