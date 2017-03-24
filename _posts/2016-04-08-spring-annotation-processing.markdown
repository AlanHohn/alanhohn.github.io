---
layout: post
title: "Spring Annotation Processing: How It Works"
description: ""
category: articles
tags: []
---

One of the things I emphasize when I teach Java classes is the fact that
annotations are inert. In other words, they are just markers, potentially with
some properties, but with no behavior of their own. So whenever you see an
annotation on a piece of Java code, it means that there must be some other
Java code somewhere that looks for that annotation and contains the real
intelligence to do something useful with it.

Unfortunately, the issue with this line of reasoning is that it can be pretty
difficult to identify exactly *which* piece of code is processing the
annotation, particularly if it is inside a library. And code that processes
annotations can be confusing, as it uses reflection and has to be written in a
very generic way. So I thought it would be worthwhile to look at an example
that's done well to see how it works.

I'm going to walk through the `InitDestroyAnnotationBeanPostProcessor` from
the [Spring framework][spring] to show how it works. I've chosen this one
because it's relatively simple as these things go, it does something that's
relatively easy to explain, and I happened to need it recently for some work I
was doing.

### Spring Bean Post Processing

First I would like to start with a little explanation of the purpose of Spring.
One of the things the Spring framework does is "dependency injection". This
changes the way we typically tie together modules within a piece of code. For
example, let's say that we've written some application logic that needs a
connection to the database. Rather than coding into the application logic the
specific class that provides that connection, we can just express it as a
dependency, either in the constructor or a setter method:

```java
class MyApplication {

    private DataConnection data;
    
    ...
    public void setData(DataConnection data) {
        this.data = data;
    }
    ...
}
```

Of course, we can do this dependency injection ourselves, and we might want to
if we're writing a simple library and want to [avoid adding a dependency to
Spring][avoid]. But if we're wiring together a complicated application, Spring
can be very handy.

Since there's no magic, if we're going to let Spring inject these dependencies
for us, there's going to be a tradeoff. Spring is going to have to "know"
about the dependencies and about the classes and objects in our application.
The way Spring prefers to handle this is by allowing Spring to do the
instantiation of the objects; then it can keep track of them in a big data
structure called the application context.

### Post Processing and Initialization

And here's where `InitDestroyBeanPostProcessor` comes in. If Spring is going
to handle instantiation, there are going to be cases where some "extra work"
needs to be done after that instantiation is done, but before the application
can start its real processing. One piece of "extra work" that needs doing is
calling objects to tell them when they've been fully set up, so they can do
any extra initialization they need. This is especially important if we use
"setter" injection, as above, where dependencies are injected by calling
`setXxx()` methods, because those dependencies won't be available at the time
the object's constructor is called. So Spring needs to allow users to specify
the name of some method that should be called after the object has been
initialized.

Spring has always supported using XML to define the objects that Spring should
instantiate, and in that case there was an`'init-method` attribute that could
be used to specify the method. Obviously in that case it still needed
reflection to actually look up and call the method. But since annotations
became available in Java 5, Spring has also supported tagging methods with
annotations to identify them as objects that Spring should instantiate, to
identify dependencies that should be injected, and to identify initialization
and destruction methods that should be called.

That last item is handled by the `InitDestroyBeanPostProcessor` or one of its
subclasses. A post processor is a special kind of object, instantiated by
Spring, that implements a post processor interface. Because it implements this
interface, Spring will call a method on it with each object Spring has
instantiated, allowing it to modify or even replace that object. This is part
of Spring's approach to a modular architecture, allowing easier extension of
capability.

### How It Works

It so happens that [JSR-250][jsr] identified some "common" annotations, including a
`@PostConstruct` annotation that is designed to tag initialization methods, and
a `@PreDestroy` annotation for destruction methods. However, `InitDestroyBeanPostProcessor`
is designed to work with any set of annotations, so it provides methods to identify
the annotations:

```java
	public void setInitAnnotationType(Class<? extends Annotation> initAnnotationType) {
		this.initAnnotationType = initAnnotationType;
	}
...
	public void setDestroyAnnotationType(Class<? extends Annotation> destroyAnnotationType) {
		this.destroyAnnotationType = destroyAnnotationType;
	}
```

Note that these are ordinary setter methods, so this object can itself be set up using
Spring. In my case, I was using Spring's `StaticApplicationContext`, as I've [described
previously][prev].

Once Spring has instantiated the various objects and has injected all of the
dependencies, it calls the `postProcessBeforeInitialization`
method on all the post processors, for every object. This gives the post processor a
chance to modify or replace the object before it's initialized. Because dependencies
have been injected, this is the place where `InitDestroyAnnotationBeanPostProcessor`
calls the initialization method.

```java
    LifecycleMetadata metadata = findLifecycleMetadata(bean.getClass());
    try {
        metadata.invokeInitMethods(bean, beanName);
    }
```

Since we're interested in how the code deals with annotations, we're interested
in `findLifecycleMetadata()`, since that's where the class is inspected. That
method checks a cache, which is used to avoid performing reflection more than
necessary, since it can be expensive. If the class hasn't been inspected yet,
the method `buildLifecycleMetadata()` is called. The meat of this method looks like:

```java
ReflectionUtils.doWithLocalMethods(targetClass, new ReflectionUtils.MethodCallback() {
    @Override
    public void doWith(Method method) throws IllegalArgumentException, IllegalAccessException {
        if (initAnnotationType != null) {
            if (method.getAnnotation(initAnnotationType) != null) {
                LifecycleElement element = new LifecycleElement(method);
                currInitMethods.add(element);
            }
        }
        ...
    }
});
```

The `ReflectionUtils` is a handy class that simplifies using reflection. Amongst
other things, it converts the numerous checked exceptions that go along with reflection
into unchecked exceptions, making things easier. This particular method iterates over
only local methods (i.e. not methods that are inherited) and calls the callback for
each method.

After all of that setup, the part that checks for the annotation is pretty boring;
it just calls a Java reflection method to check for the annotation and, if it's found,
stores that method away as an initialization method.

### Wrap Up

The fact that ultimately what's happening here is simple is really the point that I
try to make when I teach reflection. It can be challenging to debug code that uses
annotations to control behavior, because from the outside it's pretty opaque, so it's
hard to envision what is happening (or not happening) and when. But at the end of the
day, what's happening is really just Java code; it might not be immediately apparent
where that code is, but it's there.

[spring]:https://spring.io/
[avoid]:https://dzone.com/articles/kill-your-dependencies-javamaven-edition
[jsr]:https://jcp.org/en/jsr/detail?id=250
[prev]:https://dzone.com/articles/spring-static-application

