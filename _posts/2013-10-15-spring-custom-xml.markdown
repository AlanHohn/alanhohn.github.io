---
layout: post
title: "Spring Custom XML Namespaces"
description: "Including custom XML in Spring configuration"
category: articles
tags: [spring, xml]
---

Introduction
------------

One of the nice recent features of Spring (2.x era) is support for custom XML.
This is the way that Spring itself has added all kinds of new tags such as
`<util:list>` and `<mvc:annotation-driven>`. The way this works is pretty elegant,
to the point that it makes an interesting alternative for configuring Java using
XML, particularly if the application already uses Spring.

I've written an [example application][springxml] to try to give an easily-copied
example of how it's done. The example uses Spring and a custom XML parser to build
dynamic Swing menus. It makes a nice comparison to doing dynamic Swing menus using
the [Digester version][] I posted a while back.

Of course, this is not a good way to make Java menus in general! In most applications,
this would be an example of [Soft Coding][]. This would really only make sense in
an application where it was really important to be able to add or remove menus
without changing Java code. So treat it as a nice example, but please don't start
making your GUIs this way.

Spring Custom XML
-----------------

Custom XML works in a Spring configuration file because Spring can dynamically
validate and parse XML. To do this, Spring first has to be able to validate 
the XML it parses against a schema. It does this by looking for all files
on the classpath called `META-INF/spring.schemas`.  These files provide a
location on the classpath for the XML schema that goes with a given namespace.
For example, the "core" XML for Spring is defined in the `beans` namespace. The
`META-INF/spring.schemas` file in the `spring-beans` JAR has entries like this
one:

{% highlight text %}
http\://www.springframework.org/schema/beans/spring-beans-3.0.xsd=org/springframework/beans/factory/xml/spring-beans-3.0.xsd
{% endhighlight %}

So when we use the `beans` schema in our Spring XML, it knows where on the classpath
to hunt down the schema so it can validate that XML.

Once the schema is validated, Spring needs to find a "handler" that knows how to
make Spring beans based on the XML. Spring finds handlers by looking through
all the files on the classpath called `META-INF/spring.handlers`. The
`spring.handlers` file in the `spring-beans` JAR has entries like this one:

{% highlight text %}
http\://www.springframework.org/schema/p=org.springframework.beans.factory.xml.SimplePropertyNamespaceHandler
{% endhighlight %}

It's really the job of the handler to make bean *definitions*, not the regular
Java objects that will live as beans in the Spring application context. This
is because Spring still has to manage things like beans depending on other
beans, which means Spring has to parse all the XML to figure out the dependency
graph before any objects can be instantiated. 

Example Application
-------------------

Our example application has several parts:

1. The `spring.schemas` and `spring.handlers` files in `META-INF`.
1. An XML schema defining what is valid in our custom namespace.
1. `MenuNamespaceHandler`, the entry class that allows us to register what XML elements 
   go with what parser classes.
1. `MenuDefinitionParser`, the actual XML parser for our custom XML namespace.
1. A regular Spring XML configuration file that also includes our custom XML.
1. A main class to get the whole thing kicked off.

There's also a Java class called `MenuItem` that we use to store the ID, the
title, and any children of the menu item. It doesn't know anything about Spring
or XML; it's just a POJO.

Defining the custom XML
-----------------------

The `spring.schemas` file is pretty simple. Note that it's matching to a file
*on the classpath*; Spring is not going to be looking out on the Internet for your
XML schema at runtime.

{% highlight text %}
http\://anvard.org/springxml/menu.xsd=org/anvard/springxml/menu.xsd
{% endhighlight %}

The `spring.handlers` file is also pretty simple. It just points to the right
handler class:

{% highlight text %}
http\://anvard.org/springxml/menu=org.anvard.springxml.MenuNamespaceHandler
{% endhighlight %}

The XML schema is omitted here; it's an XML schema and not much need be said.
Of note is that it allows for arbitrary nesting of `<menu>` elements inside
other `<menu>` elements.

One more piece of boilerplate; the namespace handler. Since our namespace is really
simple and only contains one top-level element (`menu`), it's a one-liner:

{% highlight java %}
public void init() {
	registerBeanDefinitionParser("menu", new MenuDefinitionParser());
}
{% endhighlight %}

The parser is where it gets interesting. The parser will get called while Spring
is reading the XML file, whenever it comes across an element that belongs to the matching
namespace. *However*, it will only be called for the top-level element; it's up to
us to handle any nested elements as required.

{% highlight java %}
protected AbstractBeanDefinition parseInternal(Element element,
		ParserContext context) {

	BeanDefinitionBuilder builder = parseItem(element);

	List<Element> childElements = DomUtils.getChildElementsByTagName(
			element, "menu");

	if (null != childElements && childElements.size() > 0) {
		ManagedList<AbstractBeanDefinition> children = new ManagedList<>(
				childElements.size());

		for (Element child : childElements) {
			children.add(parseInternal(child, context));
		}
		builder.addPropertyValue("children", children);
	}

	return builder.getBeanDefinition();
}

private BeanDefinitionBuilder parseItem(Element element) {
	BeanDefinitionBuilder builder = BeanDefinitionBuilder
			.rootBeanDefinition(MenuItem.class);

	String id = element.getAttribute("id");
	if (StringUtils.hasText(id)) {
		builder.addPropertyValue("id", id);
	}

	String title = element.getAttribute("title");
	if (StringUtils.hasText(title)) {
		builder.addPropertyValue("title", title);
	}

	String listener = element.getAttribute("listener");
	if (StringUtils.hasText(listener)) {
		builder.addPropertyReference("listener", listener);
	}

	return builder;
}
{% endhighlight %}

In this case, because we allowed for the idea that a menu could contain child
menus, we have to handle that here with some recursion. Note that for every
`<menu>` element at whatever level, we are creating a separate Spring bean
definition (that's one purpose of the `rootBeanDefinition()` static method
call). The really important thing to notice is that as we build the bean
definition, we are not creating a `MenuItem` object directly, nor are we
setting any properties directly. In fact, in the case of the `children`
property, we are not even building a list of the correct type, as the
`MenuItem` class expects to receive a list of `MenuItem` children, but we are
building a list of `AbstractBeanDefinition`. Spring handles all of the
necessary wiring when it actually instantiates our `MenuList` objects,
including looking up each of the references in the list and populating a new
list with the real objects.

One other thing that's slightly confusing is that a reference to a single
other Spring bean uses `addPropertyReference()`, while a managed list of
Spring bean definitions uses `addPropertyValue()`.

Using the custom XML
--------------------

Now that these items are in place, we can use the custom XML just the same
as any other XML in a Spring configuration file. For example:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<bean:beans xmlns="http://anvard.org/springxml/menu"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xmlns:bean="http://www.springframework.org/schema/beans"
	xmlns:util="http://www.springframework.org/schema/util"
	xsi:schemaLocation="http://anvard.org/springxml/menu 
						  http://anvard.org/springxml/menu.xsd
                        http://www.springframework.org/schema/beans
                          http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
                        http://www.springframework.org/schema/util
                          http://www.springframework.org/schema/util/spring-util-3.0.xsd">

	<bean:bean id="simpleListener" class="org.anvard.springxml.SimpleMenuItemListener" />

	<menu id="menu1" title="Parent 1">
		<menu id="menu2" title="Child 1" listener="simpleListener" />
		<menu id="menu3" title="Child 2" listener="simpleListener" />
		<menu id="menu4" title="Child 3" listener="simpleListener" />
		<menu id="menu5" title="Child 4" listener="simpleListener" />
	</menu>

	<menu id="menu6" title="Item 1" listener="simpleListener" />

	<menu id="menu7" title="Grand Parent 1">
		<menu id="menu8" title="Parent 2">
			<menu id="menu9" title="Child 5" listener="simpleListener" />
		</menu>
	</menu>
	
	<util:list id="toplevel">
		<bean:ref bean="menu1" />
		<bean:ref bean="menu6" />
		<bean:ref bean="menu7" />
	</util:list>

</bean:beans>
{% endhighlight %}

Note that we can make our custom XML the default namespace so we don't have to
prefix our XML elements; we can also make the `bean` namespace the default as is
more typical in a Spring XML configuration file. We can mix our custom XML freely
with standard Spring XML.

Also note that our custom XML can make references back to ordinary Spring beans
as long as we do the right thing in our parser to make this work.

We use a list called `toplevel` as a handy way of finding the outermost menu items
for our menu bar. Once the XML is parsed, the beans are all loaded into the Spring
application context and the structure of the XML no longer really applies.

Using this file from our main class looks just the same as any Spring code:
{% highlight java %}
ClassPathXmlApplicationContext ctx = new ClassPathXmlApplicationContext("/menuDefinition.xml");
{% endhighlight %}

All of our menu items are available in the Spring application context, so we could
do `ctx.getBean("menu9")` and get back the menu item with the title "Child 5". 

Conclusion
----------

Even though many Spring users are shifting toward annotation-driven configuration, there
are still things that are easier to do in XML, like creating many instances of a class
with different properties. A custom XML namespace is a way to make Spring XML configuration
more compact and more readable.

[springxml]:https://github.com/AlanHohn/springxml-menu
[Digester version]:{% post_url 2013-09-15-digester-menus %}
[Soft Coding]:http://thedailywtf.com/Articles/Soft_Coding.aspx

