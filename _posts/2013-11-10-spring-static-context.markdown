---
layout: post
title: "Spring Static Application Context"
description: "Using Spring Programmatically / Spring Java DSL"
category: articles
tags: [spring,java]
---

Introduction
------------

I had an interesting conversation the other day about custom domain-specific languages
and we happened to talk about a feature of Spring that I've used before but doesn't
seem to be widely known: the static application context. This post illustrates a basic
example I wrote that introduces the static application context and shows how it might
be useful. It's also an interesting topic as it shows some of the well-architected
internals of the Spring framework.

Most uses of Spring start with XML or annotations and wind up with an application
context instance. Behind the scenes, Spring has been working hard to instantiate objects,
inject properties, invoke context aware listeners, and so forth. There are a set of
classes internal to Spring to help this process along, as Spring needs to hold
all of the configuration data about beans before any beans are instantiated.
(This is because the beans may be defined in any order, and Spring doesn't have the
exhaustive set of dependencies until all beans are defined.)

Spring Static Application Context
---------------------------------

Spring offers a class called `StaticApplicationContext` that gives programmatic access
from Java to this whole configuration and registration process. This means we can define
an entire application context from pure Java code, without using XML or Java annotations
or any other tricks. The Javadoc for `StaticApplicationContext` is [here][sacdoc], but
an example is coming.

[sacdoc]:http://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/context/support/StaticApplicationContext.html

Why might we use this? As the Javadoc says, it's mainly useful for testing. Spring uses
it for its own testing, but I've found it useful for testing applications that use
Spring or other dependency management frameworks. Often, for unit testing, we want to
inject different objects into a class from those used in production (e.g. mock objects, or
objects that simulate remote invocation, database, or messaging). Of course, we
can just keep a separate Spring XML configuration file for testing, but it's
very nice to have our whole configuration right there in the Java unit test
class as it makes it easier to maintain.

Example
-------

I've added an example to my [intro-to-java][] repository on GitHub. I created a `StaticContext`
class that provides a very basic Java domain-specific language (DSL) for Spring beans. This is
just to make it easier to use from the unit test. The DSL only includes the most basic Spring
capabilities: register a bean, set properties, and wire dependencies.

[intro-to-java]:https://github.com/AlanHohn/java-intro-course

{% highlight java %}
package org.anvard.introtojava.spring;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.factory.config.ConstructorArgumentValues;
import org.springframework.beans.factory.config.RuntimeBeanReference;
import org.springframework.beans.factory.support.RootBeanDefinition;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.StaticApplicationContext;

public class StaticContext {

    public class BeanContext {
        private String name;
        private Class<?> beanClass;
        private ConstructorArgumentValues args;
        private MutablePropertyValues props;
        
        private BeanContext(String name, Class<?> beanClass) {
            this.name = name;
            this.beanClass = beanClass;
            this.args = new ConstructorArgumentValues();
            this.props = new MutablePropertyValues();
        }
        public BeanContext arg(Object arg) {
            args.addGenericArgumentValue(arg);
            return this;
        }
        public BeanContext arg(int index, Object arg) {
            args.addIndexedArgumentValue(index, arg);
            return this;
        }
        public BeanContext prop(String name, Object value) {
            props.add(name, value);
            return this;
        }
        public BeanContext ref(String name, String beanRef) {
            props.add(name, new RuntimeBeanReference(beanRef));
            return this;
        }
        public void build() {
            RootBeanDefinition def = 
              new RootBeanDefinition(beanClass, args, props);
            ctx.registerBeanDefinition(name, def);
        }
    }
    
    private StaticApplicationContext ctx;
    
    private StaticContext() {
        this.ctx = new StaticApplicationContext();
    }
    
    public static StaticContext create() {
        return new StaticContext();
    }
    
    public ApplicationContext build() {
        ctx.refresh();
        return ctx;
    }
    
    public BeanContext bean(String name, Class<?> beanClass) {
        return new BeanContext(name, beanClass);
    }
    
}
{% endhighlight %}

This class uses several classes that are normally internal to Spring:

* `StaticApplicationContext`: Holds bean definitions and provides regular Java methods for 
  registering beans.
* `ConstructorArgumentValues`: A smart list for a bean's constructor arguments. Can hold both 
  wire-by-type and indexed constructor arguments.
* `MutablePropertyValues`: A smart list for a bean's properties. Can hold regular objects and 
  references to other Spring beans.
* `RuntimeBeanReference`: A reference by name to a bean in the context. Used for wiring beans
  together because it allows Spring to delay resolution of a dependency until it's been
  instantiated.

The `StaticContext` class uses the builder pattern and provides for method chaining. This makes for 
cleaner use from our unit test code. Here's the simplest example:

{% highlight java %}
@Test
public void basicBean() {
    StaticContext sc = create();
    sc.bean("basic", InnerBean.class).prop("prop1", "abc").
      prop("prop2", "def").build();
    ApplicationContext ctx = sc.build();
    assertNotNull(ctx);
    InnerBean bean = (InnerBean) ctx.getBean("basic");
    assertNotNull(bean);
    assertEquals("abc", bean.getProp1());
    assertEquals("def", bean.getProp2());
}
{% endhighlight %}

A slightly more realistic example that includes wiring beans together is not much more complicated:
{% highlight java %}
@Test
public void innerBean() {
    StaticContext sc = create();
    sc.bean("outer", OuterBean.class).prop("prop1", "xyz").
      ref("inner", "inner").build();
    sc.bean("inner", InnerBean.class).prop("prop1", "ghi").
      prop("prop2", "jkl").build();
    ApplicationContext ctx = sc.build();
    assertNotNull(ctx);
    InnerBean inner = (InnerBean) ctx.getBean("inner");
    assertNotNull(inner);
    assertEquals("ghi", inner.getProp1());
    assertEquals("jkl", inner.getProp2());
    OuterBean outer = (OuterBean) ctx.getBean(OuterBean.class);
    assertNotNull(outer);
    assertEquals("xyz", outer.getProp1());
    assertEquals(inner, outer.getInner());
}
{% endhighlight %}

Note that once we build the context, we can use it like any other Spring application context, including
fetching beans by name or type. Also note that the two contexts we created here are completely separate,
which is important for unit testing.

Conclusion
----------

Much like my post on custom Spring XML, the static application context is a specialty feature that
isn't intended for everyday users of Spring. But I've found it convenient when unit testing and
it provides an interesting peek into how Spring works.

