---
layout: post
title: "Generics and Capture Of"
description: "Java SE 7 type inference"
category: articles
tags: [java,generics]
---

I taught an introductory Java session on generics, and of course demonstrated
the shorthand introduced in Java SE 7 for instantiating an instance of a
generic type:

{% highlight java %}
// Java SE 6
List<Integer> l = new ArrayList<Integer>(); 
// Java SE 7
List<Integer> l = new ArrayList<>();
{% endhighlight %}

This inference is very friendly, especially when we get into more complex
collections:

{% highlight java %}
// This
Map<String,List<String>> m = new HashMap<String,List<String>>();
// Becomes
Map<String,List<String>> m = new HashMap<>();
{% endhighlight %}

Not only the key and value type of the map, but the type of object stored
in the collection used for the value type can be inferred.

Of course, sometimes this inference breaks down. It so happens I ran across an 
interesting example of this. Imagine populating a set from a list, so as to
speed up random access and remove duplicates. Something like this will work:

{% highlight java %}
List<String> list = ...; // From somewhere

Set<String> nodup = new HashSet<>(list);
{% endhighlight %}

However, this runs into trouble if the list could be `null`. The `HashSet`
constructor will not just return an empty set but will throw 
`NullPointerException`. So we need to guard against `null` here. Of course,
like all good programmers, we seize the chance to use a ternary operator
because ternary operators are cool.

{% highlight java %}
List<String> list = ...; // From somewhere

Set<String> nodup = (null == list) ? new HashSet<>() :
                      new HashSet<>(list);
{% endhighlight %}

And here's where inference breaks down. Because this is no longer a simple
assignment, the statement `new HashSet<>()` can no longer use the left hand
side in order to infer the type.  As a result, we get that friendly error
message, "`Type mismatch: cannot convert from HashSet<capture#1-of ? extends
Object> to Set<String>`". What's especially interesting is that inference
breaks down even though the compiler *knows* that an object of type
`Set<String>` is what is needed in order to gain agreement of types. The rules
for inference are written to be conservative by doing nothing when
an invalid inference might cause issues, while the compiler's type checking is
also conservative in what it considers to be matching types.

Also interesting is that we only get that error message for the `new
HashSet<>()`. The statement `new HashSet<>(list)` that uses the list to
populate the set works just fine. This is because the inference is completed
using the `list` parameter. Here's the constructor:

{% highlight java %}
public class HashSet<E> extends ... implements ...
{
  ...
  public HashSet(Collection<? extends E> c) { ... }
  ...
}
{% endhighlight %}

The `List<String>` that we pass in gets captured as `Collection<? extends String>`
and this means that `E` is bound to `String`, so all is well.

As a result, we wind up with the perfectly valid, if a little funny looking:
{% highlight java %}
List<String> list = ...; // From somewhere

Set<String> nodup = (null == list) ? new HashSet<String>() :
                      new HashSet<>(list);
{% endhighlight %}

Of course, I imagine most Java programmers do what I do, which is try to use the
shortcut and then add the type parameter when the compiler complains. Following
the rule about not meddling in the affairs of compilers (subtle; quick to anger),
normally I would just fix it without trying very hard to understand why the
compiler liked or didn't like things done in a certain way. But this one was
such a strange case I figured it was worth a longer look.


