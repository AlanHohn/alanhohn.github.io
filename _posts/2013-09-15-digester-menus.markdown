---
layout: post
title: "Menus with Apache Digester"
description: "An example of Digester XML parsing"
category: articles
tags: [java, digester, xml]
---

[Apache Digester][digester] is a venerable library for parsing XML and turning it into
a graph of Java objects. There are a _lot_ of libraries out there for parsing and
writing XML, and Digester isn't the most performant at runtime, doesn't support
writing XML back out again, and can seem a little inaccessible to new users. But I
like it very much, and it's a very powerful tool in my toolbox.

[digester]:http://commons.apache.org/proper/commons-digester/

XML Configuration
-----------------

There is a particular use case for XML where the XML is used as a human-edited
configuration file. Of course, properties files are simple to use for this purpose,
but where more complex configuration is needed, especially with a natural hierarchy
to the configuration, XML just seems more logical. For an example, compare a simple
`log4j.properties` file with a simple `log4j.xml` file.

{% highlight properties %}
log4j.rootLogger=INFO,A1
log4j.appender.A1=org.apache.log4j.ConsoleAppender
log4j.appender.A1.layout.ConversionPattern=%-4r %-5p [%t] %c{4} - %m%n
{% endhighlight %}

{% highlight xml %}
<log4j:configuration xmlns:log4j="http://jakarta.apache.org/log4j/">
  <appender name="A1" class="org.apache.log4j.ConsoleAppender">
    <param name="Target" value="System.out"/>
    <param name="Threshold" value="INFO"/>
    <layout class="org.apache.log4j.PatternLayout">
      <param name="ConversionPattern" value="%-4r %-5p [%t] %c{4} - %m%n"/>
    </layout>
  </appender>
  <root>
    <appender-ref ref="CONSOLE"/>
  </root>
</log4j>
{% endhighlight %}
 
Both these do the same thing, and the XML is far more verbose. But its advantage
is that it has a natural hierarchy that avoids error (it's impossible to apply
a pattern to an appender that isn't otherwise defined) and makes it easier to
edit (it's not necessary to search a large file for all the places the
appender is configured).

Of course, with Ruby, Python, and similar syntax, we have ways of providing 
hierarchical data that aren't as verbose as XML. But still, XML is quick,
in wide use, and it's easy to find tools that will catch obvious syntax
errors.

In cases where we're using XML for configuration, we don't generally care
about being able to write it back out again, and we don't necessarily want
to conform our Java object structure to match the XML. What we want is
something quick and something that requires very few lines of code. Digester
is designed for this kind of use case.

Digester for Menus
------------------

Recently I had a need to provide for dynamic Swing menus. The menu items are
going to be customized after the software is delivered, and I don't want that
customization to include a general-purpose programming language. There probably
exists some library out there for dynamic Swing menus, but I didn't want to
find and integrate yet another third-party library for something that will be
less than 250 lines of code. So XML menus and Digester were a logical fit. With
Digester, my approach is always to make a sample of what I want the XML to look
like. I wanted arbitrary nesting of menus, and the menu items just had to send
a message when selected, so the result was pretty simple, similar to this:

{% highlight xml %}
<?xml version="1.0"?>
<menus>
  <menu id="1" title="Parent">
    <menu id="2" title="Child" />
    <menu id="3" title="Second Child" />
  </menu>
  <menu id="4" title="Menu" />
</menus>
{% endhighlight %}

The next step with Digester is to provide it with the rules to map the XML to Java.
Digester supports annotations and provides a "fluent" API to make rules in Java, but
I prefer the XML rule set. This is where Digester shines, as the rules for this
example are very simple:

{% highlight xml %}
<?xml version="1.0"?>
<digester-rules>
  <pattern value="*/menu">
    <object-create-rule classname="org.anvard.digester.MenuItem" />
    <set-properties-rule/>
    <set-next-rule methodname="add"/>
  </pattern>
</digester-rules>
{% endhighlight %}

The MenuItem class is a POJO with getters and setters for the `id` and `title`
attributes. It also keeps a list of its own children and provides an 'add'
method. 

The pattern specifies a set of actions that happen whenever it finds a menu
element at any level. The `object-create-rule` tells Digester to instantiate
a `MenuItem`. This new object is pushed onto a stack, so it becomes the default
target for the next rules. The `set-properties-rule` tells Digester to match 
attributes to Java properties. The `set-next-rule` tells Digester to pass the
current top of the stack as a parameter to the object that is next on the stack
by calling the method `add`. Finally, when the `</pattern>` closing tag is
reached, the new object is popped off the stack.

To use this from Java is a matter of a few lines.

{% highlight java %}
List<MenuItem> menus = new ArrayList<MenuItem>();
File file = new File("/some/directory/menu-config.xml");
Digester digester =
  DigesterLoader.createDigester(MenuManager.class
    .getResource("/menu-rules.xml"));
digester.push(menus);
try {
    digester.parse(file);
} catch (IOException e) {
    LOG.warn("Could not load file", e);
} catch (SAXException e) {
    LOG.warn("Invalid file", e);
}
{% endhighlight %}

This code uses the fact that the `List` class has a method called 'add' that
takes a single parameter. Because the list is pushed on the stack before Digester
parses the file, it serves as the parent for all of the menu items at the top
level. This saves us having to write a Digester rule for the `<menus>` element.

The final version I wrote allowed XML provided menus to be integrated with existing
hard-coded menus, and of course created real `JMenuItem` instances with action 
listeners. 

Why Digester, Plus Alternatives
-------------------------------

Digester uses SAX under the covers. Using SAX directly, even for this simple example,
would be painful. The less said about that, the better.

JAXB is a very valid alternative. With JAXB, I could create Java objects with
annotations to bring this data in, and it wouldn't be too complicated. There
would be a little complexity with the need to allow multiple children within
each object, but nothing you couldn't manage. But Digester seems to me a more
elegant way to handle this. In real-world examples, it's often necessary to
change the XML layout to meet someone else's idea of what makes the most sense,
and it gets very complicated messing with JAXB to convince it to relate an
arbitrary XML structure to an arbitrary set of Java objects. With Digester,
it's just a rule change.

The Spring framework, with its support for custom XML namespaces, is now
another good alternative to Digester. I've had success with custom XML for
Spring, and if the particular Java code I was working already used Spring, I
probably would have chosen it. But for projects that aren't already using
Spring, it seems heavyweight to pull it in and write custom namespace handlers
to read a couple files. Also, if non-programmers are going to edit the file,
they have to know not to touch the boilerplate at the top. 

On the downside, my experience working on a team has been that it can take a
little time for new folks to grasp what's happening with Digester. I've seen
some of those go on to use it themselves, which I think says good things
about it. It bears a resemblance to the Spring framework in that you have to
become comfortable with reflection and introspection in order to be able to
picture what's happening behind the scenes. As much as I like it, the XML
rule language can also be a little hard to read and remember.

Digester has been around since before most of the current crop of XML tools,
but it's still being maintained and it's been a very good library to know.

