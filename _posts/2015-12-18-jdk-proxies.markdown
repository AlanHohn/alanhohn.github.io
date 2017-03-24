---
layout: post
title: "Java Dynamic Proxies"
description: ""
category: articles
tags: []
---

*tldr*A lot of modern Java frameworks use dynamically generated code. This article
is designed to demystify a little of what is happening behind the scenes.*/tldr*

When I've worked with new users of the [Spring framework][spring] and Java EE, I've seen a lot
of initial confusion over why injection works in some places but not others, or at
some times but not others. My theme when teaching this material is to repeat, "there
is no magic". Wherever there is an annotation that "magically" injects some object
or manages a transaction, there is some piece of code somewhere doing the dirty work.
Annotations by themselves are inert; they don't do anything. Instead, another class
somewhere uses Java reflection to find the annotation and take some action based on it.

In this article I want to show one of the behind-the-scenes techniques: creating
dynamic proxies using classes built into the standard Java library. A proxy is a class
that replaces or sits in between some regular class to add some extra behavior. For example,
let's say we have a requirement to create an audit log of all the calls to certain services.
We could modify every service to update the audit log, but we don't really want to mix in
auditing behavior with the behavior of the real service. Instead, we can write a single
class that does the auditing consistently, then use a proxy approach to apply this behavior
to lots of services.

So we might have a class that looks like:

```java
public class Auditor {

  public void audit(String service, String extraData) {
    // ... Do the auditing
  }

}
```

Let's say we had a real service. For the purposes of this article I'll use a calculator,
which is what I like to use when I can't be bothered to think of something useful:

```java
public interface Calculator {
  int add(int left, int right);
}

public class CalculatorImpl implements Calculator {
  public int add(int left, int right) {
    return left + right;
  }
}
```

Note that we create an interface; this makes it easier to write a proxy, and
for the dynamic proxies built into the Java standard library it is an
essential step.

We can now make a very simple proxy that provides auditing for our calculator:

```java
public class AuditingCalculator implements Calculator {
  private Calculator inner;
  private Auditor auditor;
  public AuditingCalculator(Calculator inner, Auditor auditor) {
    this.calculator = calculator;
    this.auditor = auditor;
  }
  public int add(int left, int right) {
    auditor.audit("calculator", "before add");
    int result = inner.add(left, right);
    auditor.audit("calculator", "after add");
    return result;
  }
}
```

As long as they have a way to get the correct instance (e.g. a factory or
dependency injection), users of the calculator do not need to know whether 
they are using the real service directly or the proxied version.

Unfortunately, looking at this example reveals some important flaws. We have
to write a separate class for every service we are auditing, so we really are
not saving any lines of code. Additionally, our proxy is tightly coupled to
the interface it is proxying, so every time a service has to change we have
multiple places to make code changes.

This is where the need for a dynamic class comes in. When we write Java source
code and compile it, the compiler writes class files containing `bytecode`,
which is a pseudo-assembly language designed to be run on the Java Virtual
Machine (JVM). This bytecode is read dynamically by the JVM when a class is
loaded, while the program is running. Of course, there is no reason the bytecode
has to exist in files on the disk. When we write in scripting languages (e.g.
Groovy) on the JVM, the bytecode generation is saved until runtime. Similarly,
when using a dynamic class, the JVM is dynamically generating bytecode, then
loading it in as it does any other class.

To make it easier to dynamically generate bytecode, the JVM provides static
methods in the class `java.lang.reflect.Proxy`. These methods can generate
a dynamic class that implements one or more interfaces. Real frameworks,
like Spring, Java EE, or [Blueprint][], use this capability; however, in some
cases they must dynamically generate proxies for concrete classes, not just
interfaces, so they also use third-party libraries like [CGLib][] and [ASM][].

In our case, we can use a dynamic proxy to save ourselves the work of writing
an auditing proxy for every service we need to audit. We start by creating an
"invocation handler", which is a class that can accept any method call and
take some action based on it:

```java
public class AuditingInvocationHandler implements InvocationHandler {
  private final Auditor auditor;
  private final Object target;
  public AuditingInvocationHandler(Auditor auditor, Object target) {
    this.auditor = auditor;
    this.target = target;
  }
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    auditor.audit(target.getClass().getName(), "before " + method.getName());
    Object returnObject = method.invoke(target, args);
    auditor.audit(target.getClass().getName(), "after " + method.getName());
    return returnObject;
  }
}
```

This code is a little more complicated, because it has to be able to handle
any kind of method on any object. This example does not make very good audit
logs, but note that we can pass this invocation handler any data through its
constructor, so if we need to improve the behavior we can.

To use this invocation handler, we will dynamically generate a proxy that
pretends to implement the `Calculator` interface, but really calls the invocation
handler. The invocation handler audits, then delegates to some "real" calculator:

```java
Auditor auditor = ...;
Calculator real = new CalculatorImpl();
InvocationHandler handler = new AuditingInvocationHandler(auditor, real);

Calculator proxy = (Calculator) Proxy.newProxyInstance(
  ClassLoader.getSystemClassLoader(), new Class[] { Calculator.class }, handler);

real.add(2, 2); // Will not be audited
proxy.add(2, 2); // Will be audited
```

The key is the `newProxyInstance()` method, which dynamically generates a
class that claims to implement `Calculator`. When any method is called on
the dynamically generated class, that method call is routed to the invocation
handler. Note that this way of doing things means that we can use the same
invocation handler for many different dynamic proxies, each implementing
a different interface. So we can write this code once and use it to audit
many services.

The last two lines of the above code illustrate a very important point about
using proxies and especially dynamic proxies. There is no magic, so in
order for the service call to be audited, the proxy must actually be invoked!
If we allow non-proxied instances to get passed around and used, we will not
get the proxied behavior. I have seen this confusion many times when using
transaction support in Spring and Java EE, where someone will directly
instantiate a class annotated as `@Transactional` but not get transactional
behavior. The transactional behavior is performed by a proxy, so only proxied
instances will work right. In general, for both Spring and Java EE, if the
container injects the object, it will contain all the right proxy logic as
needed.  

Of course, there is much more complexity with a dependency injection framework,
including scanning for Java annotations, matching constructors to instantiate classes
using reflection, and matching dependencies by type for dependency injection. Hopefully
this small example has given some insight into a key piece of how these frameworks
are able to provide functionality where the implementation is hidden from users of
the framework.

[spring]:http://projects.spring.io/spring-framework/
[blueprint]:http://aries.apache.org/modules/blueprint.html
[CGLib]:https://github.com/cglib/cglib
[ASM]:http://asm.ow2.org/

