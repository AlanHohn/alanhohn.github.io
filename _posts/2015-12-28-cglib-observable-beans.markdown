---
layout: post
title: "Dynamic Class Enhancement with CGLib"
description: ""
category: articles
tags: []
---

*tldr*Popular libraries like Spring use CGLib to dynamically generate classes
at runtime. Understanding how it works can help you parse those notorious stack
traces when something goes wrong.*/tldr*

This is the third article on the subject of dynamic classes in Java.
In the [first article][first] I discussed proxy capabilities built into
the Java standard library. In the [second article][second] I discussed
using CGLib in order to enhance a concrete class through a dynamic
subclass. In this article I want to cover a slightly more complicated
example using CGLib to show off some of its other capabilities.

With the previous example, we created an enhanced class to add
auditing capabilities. The class we were enhancing was a concrete
class with no interfaces, and we were content to make a single instance
of it, because it was a (fake) service. However, what if we want to
apply the enhanced behavior to many different kinds of classes, and
access the enhanced behavior through an interface so it's easy to use
from regular code? In that case, there are a couple more things we need
to do.

For this article, I will be showing an example that allows any JavaBean
class (i.e. a class that follows the [JavaBeans][] approach with getter
and setter methods) to become "observable" so any listener can register
with it to be notified of property changes.

## Example Code

I will work through each of the classes in this example, but the whole
thing is available [on GitHub][intro].

First, we need a basic JavaBean class. This doesn't have anything special
about it; it just follows the getter/setter convention.

```java
public class SampleBean {

    private String stringValue;
    private int intValue;

    public String getStringValue() {
        return stringValue;
    }

    public void setStringValue(String stringValue) {
        this.stringValue = stringValue;
    }

    public int getIntValue() {
        return intValue;
    }

    public void setIntValue(int intValue) {
        this.intValue = intValue;
    }

}
```

If we were to make this bean "observable" manually, we could leverage the
[PropertyChangeSupport][pcs] class built into Java to manage the listeners and
property change events for us. We would have to provide methods to add and
remove listeners, passing the call through to the same method in
`PropertyChangeSupport`.  We would also have to modify all of the setter
methods to fire a property change event to the listeners. We would then have to
add that similar logic to all of our bean classes. Even if we have them all
inherit from some base class, we still need to add the logic to every unique
setter method.

Instead, let's look at a way to do this where we only have to implement the
logic once. To make things easier, I'm going to reuse the existing 
`PropertyChangeSupport` and `PropertyChangeEvent` classes from the standard
library. However, I'm going to declare an `Observable` interface, because it
doesn't exist in the standard library. Still regular Java here, nothing dynamic
yet:

```java
import java.beans.PropertyChangeListener;

public interface Observable {

    void addPropertyChangeListener(PropertyChangeListener listener);
    
    void removePropertyChangeListener(PropertyChangeListener listener);
    
}
```

What we want is for all of our bean classes to appear to implement
this interface so listeners can register. But first, we have one
other helper class for this example. We need an example listener
for property changes, so we'll just make one that prints out whatever
events it receives:

```java
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class LoggingPropertyChangeListener implements PropertyChangeListener {
    
    private static final Log LOG = LogFactory.getLog(LoggingPropertyChangeListener.class);

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        LOG.info("Property change: " + evt.getPropertyName() + "; Old value: " + evt.getOldValue() + ", New value: "
                + evt.getNewValue());
    }
}
```

Note that a property change event identifies what property was changed, the old
value, and the new value. If we were manually firing the event from a setter it
would be pretty easy to collect this data; it'll be a little harder to do it in
a dynamic way.

## Method Interceptor

Now that we've got the stage set, we can get to the meat of the example. First,
like the previous CGLib example, we need a method interceptor. This is the code
that will be invoked whenever a method is called on our enhanced class. It will get
information about the target of the call, the method being called, and its parameters.
It will decide what action to take, including calling the regular, non-enhanced superclass
method (if any).

The interceptor has a lot of pieces, so I'll describe it in stages. Here is the first part 
of the interceptor for this example:

```java
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;

import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;

public class PropertyChangeInterceptor implements MethodInterceptor {

    private PropertyChangeSupport pcs;

    public void setTarget(Object target) {
        this.pcs = new PropertyChangeSupport(target);
    }

    private void addPropertyChangeListener(PropertyChangeListener listener) {
        if (null != pcs) {
            pcs.addPropertyChangeListener(listener);
        }
    }

    private void removePropertyChangeListener(PropertyChangeListener listener) {
        if (null != pcs) {
            pcs.removePropertyChangeListener(listener);
        }
    }

    private void firePropertyChange(String propName, Object oldValue, Object newValue) {
        if (null != pcs) {
            pcs.firePropertyChange(propName, oldValue, newValue);
        }
    }
```

For starters, note that we are using `PropertyChangeSupport` to help us track
listeners and fire events. The `PropertyChangeSupport` class expects to have
a reference to the event source passed in when it is constructed. We want this
event source to be our enhanced version of the bean, not the interceptor. So we
have to treat it as a dependency and provide a `setTarget()` method so the
interceptor can be told what object it is enhancing.

This is a minor flaw with this example, because it means we will need an
interceptor instance per object we are enhancing. To get around it, we would
have to forego the use of `PropertyChangeSupport` and roll our own listener logic.
Not a big effort but not needed for this example. 

Next, we provide a way to use reflection to look up and call the getter for a
property using the name of the setter:

```java
    private Object tryForGetter(String setterName, Object target) {
        String getterName = "get" + setterName.substring(3);
        try {
            return target.getClass().getMethod(getterName, new Class<?>[]{}).invoke(target, (Object[]) null);
        } catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException | NoSuchMethodException
                | SecurityException e) {
            return null;
        }
    }
```

We will use this method to fetch the previous value for a property so we can include
that in the `PropertyChangeEvent`. In the event the property has no getter, or something
else goes wrong, we just return null. The event will be missing the old value, but otherwise
everything will work fine. (As an aside, if I were writing this method for production purposes, I would
probably use [Apache BeanUtils][beanutils], as it has a lot of nice methods for dealing
with getters and setters via reflection.)

With these methods available to us, we can now write the important method, which is the one
that actually handles the intercepted method calls. Note that all method calls will be routed
through this `intercept()` method, so we have to handle both requests to add or remove listeners,
as well as regular interactions with the bean.

```java
    @Override
    public Object intercept(Object target, Method method, Object[] args, MethodProxy proxy) throws Throwable {
        Object targetReturn = null;

        // See if this method call should stop here
        if (method.getName().equals("addPropertyChangeListener")) {
            Class<?>[] paramTypes = method.getParameterTypes();
            if (paramTypes.length == 1 && paramTypes[0].equals(PropertyChangeListener.class)) {
                addPropertyChangeListener((PropertyChangeListener) args[0]);
                return null;
            }
        } else if (method.getName().equals("removePropertyChangeListener")) {
            Class<?>[] paramTypes = method.getParameterTypes();
            if (paramTypes.length == 1 && paramTypes[0].equals(PropertyChangeListener.class)) {
                removePropertyChangeListener((PropertyChangeListener) args[0]);
                return null;
            }
        }

        // Otherwise pass through to the real object
        Object oldValue = null;
        String name = method.getName();
        boolean isSetter = (name.startsWith("set") && args.length == 1 && method.getReturnType() == Void.TYPE);
        if (isSetter) {
            oldValue = tryForGetter(name, target);
        }
        if (!Modifier.isAbstract(method.getModifiers())) {
            targetReturn = proxy.invokeSuper(target, args);
        }
        if (isSetter) {
            String propName = Character.toLowerCase(name.charAt(3)) + name.substring(4);
            firePropertyChange(propName, oldValue, args[0]);
        }
        return targetReturn;
    }

}
```

Who says Java doesn't have [duck typing][duck]? This looks a lot like a Ruby [method_missing][mm]
implementation.

If we recognize the method call as one to add or remove a listener, we fully intercept it
and handle it here. Otherwise, we want to make sure we delegate it to the superclass we are
enhancing (since the bean class might have other methods besides just setters).

If it is a setter method, we use the JavaBeans naming convention to figure out the name of 
the property. We then try to get the old value of the property before invoking the real
setter, which will of course change the value. Once we tried to get the old value, we
call the real setter, then we fire an event to anyone that might be listening. Note that
by waiting until after we call the real setter, we avoid firing a change event where the
setter throws an exception (e.g. due to validation), and we avoid a race condition where
the event listener calls methods on the bean before its state has been fully updated.

## Enhanced Class Factory

So now we have a way to enhance a class with both add / remove listener behavior, and with
behavior that fires a property change event when a setter method is called. To wire this
in so we can have enhanced beans, we need to work with CGLib's `Enhancer`. We want to be able
to enhance any class written as a JavaBean, so what we really want is a factory that will
hide the CGLib work from users and make enhanced instances of beans. Here is our factory
class:

```java
import net.sf.cglib.proxy.Enhancer;

public final class ObservableBeanFactory {

    public static <T> T createObservableBean(Class<T> beanClass) {
        PropertyChangeInterceptor interceptor = new PropertyChangeInterceptor();

        Enhancer e = new Enhancer();
        e.setSuperclass(beanClass);
        e.setCallback(interceptor);
        e.setInterfaces(new Class[] { Observable.class });

        @SuppressWarnings("unchecked")
        T bean = (T) e.create();
        
        interceptor.setTarget(bean);
        
        return bean;
    }
}
```

The use of a generic static method just makes things a little cleaner for users so
they have less casting to do. First, we make a new instance of our property change
interceptor (since, as discussed above, we can't reuse it). Then we make an `Enhancer`
instance. Note that, per the CGLib documentation, we should not try to reuse `Enhancer`
instances. We set the superclass of the enhanced class to be whatever was passed in,
then provide the interceptor that will handle method calls. Finally, we tell CGLib
to create a bean that implements the `Observable` interface we made above. This way,
it will appear to users that our bean class provides the `addPropertyChangeListener`
and `removePropertyChangeListener` methods. Of course, we do support those methods,
because the interceptor looks for them by signature and handles them. Again, who
says Java doesn't have duck typing?

Finally, we create an instance of the new enhanced bean class we just made, and pass
it to the interceptor so its `PropertyChangeSupport` is set up correctly.

This is a simple factory that we could make almost arbitrarily complex. For example,
while the CGLib `Enhancer` should not be reused, every enhanced class made with CGLib
implements a `Factory` interface that can be used to make more instances. If we were
to improve our interceptor so it can be reused with all bean instances, we could
cache each enhanced bean class and reuse it if an instance is requested of a bean
we've already seen before. This would be much better, because as-is this code has
a potential issue with PermGen: it makes a new class for every bean instance, which
would never go away. If we were to cache bean classes, we would probably have to
deal with thread-safety issues to make sure we didn't have concurrent map modifications
or two versions of the same enhanced bean class floating around.

## Finishing Up the Example

In any case, now that we have our factory, we can use it to make enhanced
beans. Here is the main method to illustrate how users would interact with the factory
and our enhanced bean:

```java
public class PropertyChangeExample {

    public static void main(String[] args) {

        SampleBean regular = new SampleBean();
        SampleBean observableBean = ObservableBeanFactory.createObservableBean(SampleBean.class);

        ((Observable) observableBean).addPropertyChangeListener(new LoggingPropertyChangeListener());

        /* Will not be observed */
        regular.setStringValue("abc");
        regular.setStringValue("def");
        regular.setIntValue(1);
        regular.setIntValue(2);

        /* Will be observed */
        observableBean.setStringValue("zyx");
        observableBean.setStringValue("wvu");
        observableBean.setIntValue(10);
        observableBean.setIntValue(20);

    }
}
```

Note that there is nothing specific to CGLib in this example, and that the enhanced bean
can be used just like the regular bean. However, the enhanced bean can also be cast to the
`Observable` interface and a listener can be registered.

At runtime, the enhanced bean will have a class name like:

```
org.anvard.introtojava.dynamic.cglib.SampleBean$$EnhancerByCGLIB$$140acd09
```

And `observableBean.getClass().getSuperclass()` will be `SampleBean.class`.

## Conclusion

The ability to add "observable" behavior to any JavaBean strikes me more as a
cool trick that illustrates CGLib than as something I would want to try in a
production environment. We have added an extra step to every method call, and
added Java reflection to every call to a setter (since we use reflection to
call the getter to get the previous value). We could probably find some ways to
make that performant, but it would be a rare use case where it would be worth
the effort of building a thread-safe, performant version of this code and
maintaining it.

However, it makes a great illustration of the kind of things CGLib does and why it
is so valuable for framework code. For that reason, I like to use it when I teach
Java EE and the Spring Framework. Most importantly, it helps get across the key
point I want students to get when learning these frameworks, which is that there is
no magic involved. Writing to a framework can be daunting when something goes wrong
down in the internals and you are presented with a massive stack trace. Understanding
what kinds of techniques are being used can help with learning what to ignore and what
to pay attention to in those stack traces.

[first]:https://dzone.com/articles/java-dynamic-proxies
[second]:https://dzone.com/articles/cglib-proxies-and-hibernate-lazy-fetching
[JavaBeans]:https://docs.oracle.com/javase/tutorial/javabeans/
[intro]:https://github.com/AlanHohn/java-intro-course/tree/master/src/main/java/org/anvard/introtojava/dynamic/cglib
[pcs]:http://docs.oracle.com/javase/7/docs/api/java/beans/PropertyChangeSupport.html
[beanutils]:http://commons.apache.org/proper/commons-beanutils/
[duck]:https://en.wikipedia.org/wiki/Duck_typing
[mm]:http://ruby-doc.org/core-2.1.0/BasicObject.html#method-i-method_missing

