---
layout: post
title: "Language Flavors"
description: ""
category: articles
tags: []
---

It might be having a child in Spanish this year, or maybe it's the fact
that I've been switching from Java to Ruby to Go to Python over the past
couple months, but I've been giving some thought to how different
languages are "flavored". One of my favorite things about the Go
programming language is that the second thing you read while learning it
is a [whole book][1] on "writing clear, idiomatic Go code".

[1]:https://golang.org/doc/effective_go.html

I really like the term "idiomatic" in this context. It means both "natural
to a native speaker" and "appropriate to the style". But most importantly,
it comes from the root "idiom". One way to describe an idiom is that it
means something different from what it appears to mean.

So for example, in English we say, "I follow you" to mean that I understand
what you are trying to say, even though no physical movement is happening.
[Owen Barfield][2] pointed out that this is not an accident; all speech about
ideas must use some kind of metaphor. We could say, "I see your point," or "I
grasp it", and it is still a metaphor. Even "understand" was a metaphor when it
was a new word.

[2]:http://www.owenbarfield.org/

This same idea of metaphor applies everywhere in programming; as [Fred
Brooks][3] has said, programming is building "castles in the air, from air,
creating by exertion of the imagination." We talk about "objects", "classes",
"transactions", "calls", and "methods". We live so often in the world of
metaphor it's impossible to even remember most of the time that they are
metaphors.

[3]:https://www.cs.unc.edu/~brooks/

And that brings us back to programming languages (finally). Most languages
have some metaphors in common, like loops, arrays, or dictionaries. But
each language also has its own unique style that comes from which
metaphors are chosen and which are left out. 

For example, summing an array in Go, according to [Effective Go][1], looks
like this:

```go
sum := 0
for _, value := range arr {
  sum += value
}
```

While Ruby looks like this:

```ruby
sum = arr.reduce(0, :+)
```

And Java looks like this:

```java
int sum = 0;
for (int i: arr) {
  sum += i;
}
```

There's a clear difference in flavor that's related to the metaphors each
language uses. Go has a strong concept of "generators" like `range` that
produce each value of a collection for use in the code block. Ruby has 
first-class functions, so even the "+" operator can be passed to a method on an
object. Java, meanwhile, has the idea of iterators, but some syntactic sugar to
make the iteration implicit.

Of course, the last example doesn't take advantage of Java 8, where a
different approach would be possible:

```java
int sum = Arrays.stream(arr).sum();
```

Just like in human languages, programming languages borrow from each
other, which is clearly what has happened with lambdas and streams in
Java 8. Java is in some sense like the English language, which exists as
a (not totally well blended) amalgamation of words and structures from
two different language families, the Germanic and the Romance languages.

And similar to English, that means that learning Java is made more
challenging. Depending on the era in which the code was written, there might be
explicit use of `iterator()`, `hasNext()`, and `next()`. Or, there might be a
C-style `for (int i = 0...)` style loop. Or there might be one of the
approaches above. 

So what conclusions can we draw from this? Despite its uncertain parentage,
English has been a very successful language, not just because of the prominence
of the British Empire and then the United States of America, but also because
of certain flexibilities in its structure that make it easy to use for many
different kinds of topics. At the same time, at least in the modern era, there
are many competent speakers of English but very few real masters. That seems to
correlate with the history of Java, at least so far.  It would also seem to
suggest that even people who don't speak Java as a "first language" will still
retain familiarity with it as a "lingua franca".  It will be interesting to see
if the analogy holds.

