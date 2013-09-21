---
layout: post
title: "Reflection Method Matching"
description: "Matching a method using Java reflection"
category: articles
tags: [java, reflection]
---

Even though reflection is used widely in popular libraries such as Spring
and Jackson, direct use of reflection is thankfully pretty rare, as it can
be challenging to make robust. One issue with reflection is that it can
work in ways that break typical assumptions about Java. For example, looking
up a method using reflection works very differently from the way Java finds
and calls a method in normal code.

In object-oriented programming languages, we're used to the idea that a class
has its own methods plus all the methods from the classes it extends, as long
as those methods are `protected` or `public`. This works in Java reflection as
well. For an example, try this block of code:

{% highlight java %}
public static void main(String[] args) {
  for (Method m: List.class.getMethods()) {
    System.out.println(m.getName());
  }
}
{% endhighlight %}

This will print a list of method names that includes methods such as `notify`
and `wait` that are defined in `Object.class` and are inherited by `List`.

In object-oriented programming languages, we're also used to the idea that a
class has an "is-a" relationship with the classes it extends, so that for all
purposes it can be used anywhere its parent classes can be used. A `List` is-a
`Collection`, so anywhere we can use a `Collection`, we can use a `List`,
including as a parameter to a method that asks for a `Collection`.

When we invoke methods using Java reflection, this is-a relationship holds.
But when looking up a method using reflection, Java is more strict.
`Class.getMethod` and its cousins (`getDeclaredMethod`, `getConstructor`,
and `getDeclaredConstructor`) will only match a method if the exact types
of the parameters are used. This has been true basically forever in Java,
as evidenced by [this discussion][bug].

An example is as follows:

{% highlight java %}
public static void main(String[] args) throws Exception {
  Method m1 = List.class.getMethod("addAll", Collection.class);
  System.out.println("Found method: " + m1.getName());

  try {
    // This will fail
    Method m2 = List.class.getMethod("addAll", List.class);
    System.out.println("Found method: " + m2.getName());
  } catch (NoSuchMethodException e) {
    System.out.println("Method not found");
  }
}
{% endhighlight %}

The `getMethod()` call in the try block will fail. Even though List is a
subclass of Collection, so that it would be valid Java to pass a List object to
this method, reflection won't find it because the parameter type match is not
exact.

Unfortunately, when we're using reflection, we tend to be looking up methods
with parameters that match object instances we're currently holding. We don't
know what type those objects are going to be at compile time (or we wouldn't be
using reflection), so there isn't a simple solution to this problem.

There may be a more elegant workaround out there, but this at least does the 
job for me:

{% highlight java %}
public static Method getMethod(Class<?> clazz, String name, 
  Class<?>... params) throws NoSuchMethodException {

  methods: for (Method m: clazz.getMethods()) {

    if (name.equals(m.getName())) {
      Class<?>[] mParams = m.getParameterTypes();

      if ((null == params || params.length == 0) 
         && (mParams.length == 0)) {
        return m;
      }

      if (mParams.length != params.length) {
        continue methods;
      }

      for (int i = 0; i < params.length; i++) {
        if (!mParams[i].isAssignableFrom(params[i])) {
          continue methods;
        }
      }

      return m;
    }
  }

  throw new NoSuchMethodException("No matching method: " + name);
}
{% endhighlight %}

This code looks through all the methods whose name matches. For
each method, it determines if the number of parameters match, and if
so, it determines whether the type of each parameter could be legally
cast to the type the method is expecting. If all parameters pass, then
the method is valid and it is returned to the caller. If there's a mismatch,
it goes on to the next method.

With this method available, we can write:

{% highlight java %}
Method m3 = getMethod(List.class, "addAll", List.class);
System.out.println("Found method: " + m3.getName());
{% endhighlight %}

Because `addAll` takes 1 parameter and `Collection` is assignable from
`List`, we will find the correct match and be able to invoke it.

[bug]:http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4287725
