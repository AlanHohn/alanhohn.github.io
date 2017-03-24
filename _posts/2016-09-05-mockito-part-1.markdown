---
layout: post
title: "Mockito Basic Example Using JDBC"
description: ""
category: articles
tags: []
---

It's been a while since I did a lot of work with [Mockito][], but I like to cover
it when I teach unit testing for a couple reasons. First, it encourages
students to think about writing for testability by showing what kinds of
designs are easy to test and what kinds are very challenging.  I believe this
encourages more modular code. Second, it encourages students to write smaller,
more focused unit tests. Now that so many of our systems are radically
distributed, with multiple services interacting with each other, it can be
challenging to think in terms of true unit testing of the business logic
inside the service (as opposed to just invoking the service from outside).
The problem is that tests that invoke the service from outside tend to be
brittle (because they usually involve network connections and service
dependencies) and they tend to not be as comprehensive (because it's hard
to generate real-world failure conditions in the context of an integration
environment).

Mockito is impressive because the relatively simple, fluent API hides a
wealth of complexity. I was missing a decent Mockito example in my [Java
intro GitHub repository][1], so I wanted to add an example that would
reveal a little of the power that's available. I ended up creating [an example][2]
using the [JDBC API][3] that I think has a couple cool features.

## Code Under Test

To get started, let's walk through the code under test. It's a very basic
database access object that uses JDBC to run some standard SQL commands.

```java
package org.anvard.introtojava.jdbc;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.anvard.introtojava.Person;
import org.springframework.util.Assert;

public class PersonDao {

	private DataSource ds;

	public PersonDao(DataSource ds) {
		this.ds = ds;
	}

	public void create(Person person) {
		Assert.notNull(person);
		try {
			Connection c = ds.getConnection();
			PreparedStatement stmt = c
					.prepareStatement("INSERT INTO person (id, first_name, last_name) values (?, ?, ?)");
			stmt.setInt(1, person.getId());
			stmt.setString(2, person.getFirstName());
			stmt.setString(3, person.getLastName());
			stmt.executeUpdate();
			c.close();
		} catch (SQLException e) {
			throw new DataAccessException(e);
		}
	}

	public Person retrieve(int id) {
		try {
			Connection c = ds.getConnection();
			PreparedStatement stmt = c
					.prepareStatement("SELECT id, first_name, last_name FROM person WHERE id = ?");
			stmt.setInt(1, id);
			ResultSet rs = stmt.executeQuery();
			if (!rs.first()) {
				return null;
			}
			Person p = new Person();
			p.setId(rs.getInt(1));
			p.setFirstName(rs.getString(2));
			p.setLastName(rs.getString(3));
			c.close();
			return p;
		} catch (SQLException e) {
			throw new DataAccessException(e);
		}
	}
	
	public void update(Person person) {
		Assert.notNull(person);
		try {
			Connection c = ds.getConnection();
			PreparedStatement stmt = c
					.prepareStatement("UPDATE person SET first_name=?, last_name=? WHERE id=?");
			stmt.setString(1, person.getFirstName());
			stmt.setString(2, person.getLastName());
			stmt.setInt(3, person.getId());
			stmt.executeUpdate();
			c.close();
		} catch (SQLException e) {
			throw new DataAccessException(e);
		}
	}

	public void delete(int id) {
		try {
			Connection c = ds.getConnection();
			PreparedStatement stmt = c
					.prepareStatement("DELETE FROM person WHERE id=?");
			stmt.setInt(1, id);
			stmt.executeUpdate();
			c.close();
		} catch (SQLException e) {
			throw new DataAccessException(e);
		}
	}
}
```

To improve the testability of this code, we set it up so it is injected with a
`DataSource` rather than going out and getting its own connection using
`DriverManager`. Of course, this also has the advantage that we can use a
connection pool or run this code in a Java Enterprise environment.  Otherwise
this code just follows the JDBC API. 

## Testing It

What makes this challenging for testing is that there are multiple interfaces
involved. The `DataSource` is used to get a `Connection`, the `Connection` is
used to get a `PreparedStatement`, and the `PreparedStatement` is used to get a
`ResultSet`. If we were going to test this without Mockito or a similar mocking
framework, we would need to either use a real database (perhaps an in-memory
database like [H2][4]), or we would need to write a bunch of test code that
implements all of these interfaces; this is practically as much work as writing
a JDBC driver itself. I've done both of these in creating integration tests,
but neither is really a proper unit test approach.

Instead, we can use Mockito to create a "mock object" for each of these items. The
mock object is a dynamically generated object that pretends to implement some
interface or be an instance of some class, typically using a library like ASM. I
[discussed][5] ASM and dynamic proxies in a couple articles early this year.

The test code for this database access object looks like this:

```java
package org.anvard.introtojava.jdbc;

import static org.junit.Assert.*;
import static org.mockito.Matchers.*;
import static org.mockito.Mockito.*;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.sql.DataSource;

import org.anvard.introtojava.Person;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

@RunWith(MockitoJUnitRunner.class)
public class PersonDaoTest {

	@Mock
	private DataSource ds;
	
	@Mock
	private Connection c;
	
	@Mock
	private PreparedStatement stmt;
	
	@Mock
	private ResultSet rs;
	
	private Person p;
	
	@Before
	public void setUp() throws Exception {
		assertNotNull(ds);
		when(c.prepareStatement(any(String.class))).thenReturn(stmt);
		when(ds.getConnection()).thenReturn(c);
		
		p = new Person();
		p.setId(1);
		p.setFirstName("Johannes");
		p.setLastName("Smythe");

		when(rs.first()).thenReturn(true);
		when(rs.getInt(1)).thenReturn(1);
		when(rs.getString(2)).thenReturn(p.getFirstName());
		when(rs.getString(3)).thenReturn(p.getLastName());
		when(stmt.executeQuery()).thenReturn(rs);
	}
	
	@Test(expected=IllegalArgumentException.class)
	public void nullCreateThrowsException() {
		new PersonDao(ds).create(null);
	}
			
	@Test
	public void createPerson() {
		new PersonDao(ds).create(p);
	}
	
	@Test
	public void createAndRetrievePerson() throws Exception {
		PersonDao dao = new PersonDao(ds);
		dao.create(p);
		Person r = dao.retrieve(1);
		assertEquals(p, r);
	}
		
}
```

## JUnit and Runners

Let's take some time to walk through each part of this code in order to understand
what's going on. First, we see an annotation on the class:

```java
@RunWith(MockitoJUnitRunner.class)
```

Ordinarily, when we run a JUnit test, we tell JUnit about our class and it uses
reflection to inspect it for annotations. All of our methods annotated with
`@Test` are added to a list of test methods. For each test method, it
instantiates the class, runs any methods annotated with `@Before`, runs the
test method, then runs any methods annotated with `@After`. 

When JUnit sees the `@RunWith` annotation, instead of doing its normal
processing, it delegates all operations to the separate runner class that was
identified. In this case, the `MockitoJUnitRunner` ultimately ends up calling the
regular JUnit code to run the tests; however, before running the `@Before` methods,
it inspects the class using reflection and creates mock objects for everything
annotated with `@Mock`. So even though there's no code in the class that sets
the `ds` variable, by the time we get into our `setUp()` method we can confidently
assert that it is not null.

## Configuring a Mock Object

A mock object, as I said above, is a dynamic object that pretends to implement
an interface or be an instance of a class. I say "pretends to" because there
isn't any Java source code you can point to that implements the interface or
provides any instance methods. Instead, there is generic code that is invoked,
no matter what method is called.  Mockito uses CGLib to generate its mock
objects, so as I discuss in [my article on CGLib][6], all method calls are sent
to an `MethodInterceptor`. This interceptor in Mockito looks at any specific
configuration that might have taken place for that mock object, or falls back
to some default behavior.

The default behavior in Mockito is to return `null` for object return types, and
the "default" value for primitives (basically "0" or "false"). This behavior 
lets us get pretty far without having to do any additional configuration. And it
already represents the primary advantage over writing our own test classes; there
are dozens of methods in the `ResultSet` interface, and we don't have to write any
code to deal with the ones we don't care about.

Where the default behavior won't work, we can tell Mockito what to do differently.
This is where the fluent API is fun to use. Once we've got the knack, we can write
statements like this:

```java
when(ds.getConnection()).thenReturn(c);
```

Under the covers, Mockito is building an `OngoingStubbing`, which stores the
method that is being configured and the provided return value.  It's called an
`OngoingStubbing` in part because we can chain together instructions, for
example to return a value the first time and then return a different value or
throw an exception.

In this case, we are telling Mockito that when the `getConnection()` method is
called, we want it to return our mock connection. We work similarly through
the `Connection` and `PreparedStatement` mocks so that the code under test will
get back the kind of objects it expects as it uses the JDBC API.

For methods that take arguments, Mockito has a sophisticated matching scheme.
The simplest is to allow any argument to match:

```java
when(c.prepareStatement(any(String.class))).thenReturn(stmt);
```

The `any()` method takes a class parameter not to match the type of the argument,
since the Java compiler is already making sure of that, but to provide a generic
type for the argument matching to avoid any type casting in our test code.

When we call `when()` like this, both the argument matcher and the return are
saved up to be used later when the dynamic object is invoked. 

## Some Caveats

Note that in this example we do just enough work to make sure things behave as
expected. We expect the code under test to use only prepared statements, so we don't
bother to configure any behavior for `createStatement()` on the connection. We
know what order the parameters are in for the `SELECT` statement to retrieve data from
the database, so we know exactly how to configure the `ResultSet` to behave as
expected. Of course, this has the potential to make our test brittle, because there
are lots of changes to the code under test that would cause the test to incorrectly
report failure. We have to trade off between improving the realism of the test
and its simplicity.

In the next article, I'll show a more complex example where we pay closer attention
to some of the parameters we receive and use them to make the behavior of the mocks
more realistic.

[mockito]:http://mockito.org/ 
[1]:https://github.com/AlanHohn/java-intro-course
[2]:https://github.com/AlanHohn/java-intro-course/tree/master/src/test/java/org/anvard/introtojava/jdbc
[3]:https://docs.oracle.com/javase/8/docs/technotes/guides/jdbc/
[4]:http://www.h2database.com/html/main.html
[5]:https://dzone.com/articles/fully-dynamic-classes-with-asm
[6]:https://dzone.com/articles/dynamic-class-enhancement-with-cglib

