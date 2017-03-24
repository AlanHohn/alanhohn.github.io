---
layout: post
title: "Dynamic Proxies with CGLib"
description: ""
category: articles
tags: []
---

In a [previous article][prev] I discussed creating dynamic classes using
the functionality built into the standard Java library. However, it suffers
from an important limitation, as it can only create dynamic classes that
proxy interfaces. In order to provide services such as container-managed
transactions (as done by the Spring Framework) or transparent lazy fetching
of data (as done by [Hibernate][]) it is necessary to create dynamic classes
that appear to be an instance of a concrete class. In this article I will
show how these frameworks use [CGLib][cglib] to create these dynamic classes.

Proxying for a concrete class is more challenging, because while there can be
many classes that implement an interface, there is only one version of a
concrete class per class loader. In order to work around this, CGLib creates
a dynamic child class of the class being proxied. Of course, this only works
if the class is not final.

In the previous article I gave an example of needing to perform audit logging
whenever a service is called. As before, we'll assume the existence of some
auditing logic that we want to use everywhere:

```java
public class Auditor {

  public void audit(String service, String extraData) {
    // ... Do the auditing
  }

}
```

In the previous example I created a calculator service that implements an
interface. But what if the service is just a plain concrete class?

```java
public class Calculator {
  public int add(int left, int right) {
    return left + right;
  }
}
```

With CGLib this is almost as easy as the JDK proxy example. We start, as before,
by creating a class that handles any method call and performs the auditing
behavior we want, before delegating to the original method call:

```java
public class AuditingInterceptor implements MethodInterceptor {

  private Auditor auditor;
  private String service;

  public AuditingInterceptor(Auditor auditor, String service) {
    this.auditor = auditor;
    this.service = service;
  }

  public Object intercept(Object target, Method method, 
    Object[] args, MethodProxy proxy) throws Throwable {

    auditor.audit(service, "before " + method.getName());
    targetReturn = proxy.invokeSuper(target, args);
    auditor.audit(service, "after " + method.getName());

    return targetReturn;
  }
}
```

The style of this code is very similar to our previous example,
except that the method name to invoke the "real" method is
`invokeSuper()` because we are creating a dynamic proxy that will
pretend to be a child class of the class we are proxying.

With this class in place we can create our proxied calculator
(our "enhanced" class in CGLib terms):

```java
Auditor auditor = ...;
AuditingInterceptor interceptor = new AuditingInterceptor(auditor, "calculator");
Enhancer e = new Enhancer();
e.setSuperclass(Calculator.class);
e.setCallback(interceptor);
Calculator calc = (Calculator)e.create();
calc.add(2, 2); // Will be audited
```

Unlike the JDK proxy, there is no need to create an instance of
the "real" class, because we are creating an instance of its subclass.
Of course, this also means that when we call `e.create()` the constructor
of the proxied class will be called. If the class we are proxying has
a no-arg constructor, it will be used; otherwise, we need to pass constructor
arguments when we call `e.create()` so the Enhancer can properly set things
up.

Earlier, I mentioned Hibernate's use of CGLib to create a proxy for lazy
initialization. Hopefully, now that we've looked under the covers of CGLib,
this behavior makes more sense. Consider a simple example where two Hibernate
entities are dependent on one another (I will use the [JPA][] annotations):

```java
@Entity
@Table(name = "A")
public class A {
  private B b;
  // ... More fields

  @ManyToOne(fetch = FetchType.LAZY)
  public B getB() {
      return b;
  }

  public void setB(B b) {
    this.b = b;
  }
}

@Entity
@Table(name= "B")
public class B {
  // ... Some fields
}
```

For this simple example, eager fetching might be fine from a performance standpoint. But
if `B` has many fields or itself requires a number of joins to fetch, we may not want it
fetched when we fetch A.

When we annotate the field as `LAZY`, Hibernate creates a proxy using CGLib for `B` and
populates `A` with the proxy. This proxy has a reference back to the Hibernate session.
Whenever a method is called on the proxy, it checks to see if the proxy has been initialized.
If it has not, it uses the Hibernate session to create a new query to the database and populates
the object. After this, it just delegates all method calls to the populated object. The result is
that users of `A` are able to ignore `B`, in which case it won't be fetched, or use `B` as normal,
in which case its data will be invisibly fetched (assuming low latency and an available database).
This is much easier than having to manually load `B` when it is needed.

This behavior from Hibernate provides important functionality that makes Object Relational
Mapping (ORM) more performant, but it also introduces some issues. First, object serialization
doesn't work as expected when Hibernate proxies are in the way. Second, if the Hibernate session
is closed before the proxy gets a chance to initialize, it cannot fetch data from the database.
This is a cause of many of the issues people have when using Hibernate. (The entire "[open session
in view][osiv]" discussion is one controversial way to work around this issue.)

One final note about CGLib proxies. This example shares an issue that was
discussed in the [previous article][prev]. Nothing prevents anyone from
creating instances of the `Calculator` class directly, in which case they won't
get any of the enhanced behavior. Since we often use interceptors for important
things like validation and authorization, it is important to ensure that
unenhanced instances of objects are not being created or exposed. Fortunately, for our
Hibernate example, it is responsible for instantiating objects fetched from the database,
so it can ensure that the proxies are in place as needed.

This is a very simple example of CGLib. A slightly more advanced example
will allow us to create "observable" objects that automatically call listeners when
their properties change. In the next article I will cover that example.

[prev]:https://dzone.com/articles/java-dynamic-proxies
[Hibernate]:http://hibernate.org/
[CGLib]:https://github.com/cglib/cglib
[JPA]:http://www.oracle.com/technetwork/java/javaee/tech/persistence-jsp-140049.html
[osiv]:https://developer.jboss.org/wiki/OpenSessionInView

