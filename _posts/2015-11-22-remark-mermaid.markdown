---
layout: post
title: "Presentations with Remark and Mermaid"
description: ""
category: articles
tags: []
---

*tldr*Browser-based presentations are portable, easy to edit, and
they convert easily to PDF. Plus embedded code snippets are a lot
easier.*/tldr*

Browser-based presentations seem to have taken over conferences, and
for good reason. They can be hosted on the Internet, there's less 
concern about portability between operating systems, and file
sizes are very reasonable. However, in big companies PowerPoint is
still the norm. Since I tend to split pretty equally between the
two, I thought the story of how I moved toward browser-based
presentations might be interesting.

Several years back I volunteered to teach technical classes for my
company. I have now taught an Introduction to Java and a more advanced
series of classes, mostly walking through the Spring Framework and
Java EE, but from the perspective of explaining the design of large
distributed systems.

The first time I taught Introduction to Java, I used a set of
"free" instructor slides from a textbook; unfortunately, they were
worth what I paid. Since then, I've made my own slides, and gone through a
variety of technologies. The first set of slides I made were in PowerPoint, but
I found it very difficult to make code snippets look good in slides.  I also
found I was spending a lot of time making each slide look the way I wanted.

At the time I was doing a little university work, and had a professor
who used [Beamer][] for his slides. I was submitting a lot of homework
electronically with lots of embedded formulae, so I was doing a lot
of work in LaTeX anyway. So I re-did all the slides using LaTeX,
Beamer, and the "lstlistings" package.

There were two big advantages. First, code snippets could be embedded
as-is, or even linked in a separate file, and still come out looking
good. Second, Beamer has a strong aesthetic about limiting the amount
of text per slide. I found that my slides were much better after I
simplified and divided them to meet Beamer's standards, and I think
my teaching improved as a result.

Unfortunately, after several months of not using LaTeX, I went back
and looked at my slides, and found the LaTeX source hard to read.
There was too much mental friction involved in separating the content from the
styling, and as a result editing was not a smooth process. Fortunately, by that
time I had started using [Markdown][] and so I knew I still wanted to be
writing in a plain text editor, and I knew the kind of simplicity I wanted.

So I started using [Remark][], a JavaScript library that renders [Markdown][]
to HTML, with some tweaks that are specific to slides, and some support
for embedded CSS classes to make styling simpler. I ended up converting
hundreds of slides from LaTeX to Markdown; fortunately [Pandoc][] got me
a lot of the way. I've taught my way through both sets of classes again
using the Remark-based slides and was very happy with how easy it is to
read through the slides in text form and make changes.

Here's an example slide from my recent class on JAX-RS:

<img class="ctr" src="/post-images/remark-sample.png" style="max-width:100%;max-height:375px;" />

And here's the source in Remark Markdown. The `---` at the top acts as a
divider between slides rather than a horizontal rule. The square brackets
specify CSS classes; in this case, creating a two-column layout.

```markdown
---

.right-column[

---
layout: post
title: "JAX-RS Application Class"
description: ""
category: articles
tags: []
---

* JAX-RS allows configuration through an application class
  * Extends from `javax.ws.rs.core.Application`
  * Provides JAX-RS classes, singletons, and properties

* Jersey provides a `ResourceConfig` class that is useful for making
  JAX-RS application classes
  * Registers packages to search for JAX-RS annotations
  * Registers existing object instances
  * Provides an implementation for required methods

``java
public class CalculatorApp extends ResourceConfig {

    public CalculatorApp() {
        packages("org.anvard.jaxrs");
    }
}
``

]
```

Note that I removed one backquote from the fenced code
block since I also used Markdown to generate the HTML source for
this article.

Mixing bullets and code on a slide is something that was always
a little challenging in both PowerPoint and Beamer. Here it works
seamlessly. And since I have control of the style using CSS, it
is very easy to make global style changes.

The one piece that is missing is figures, especially diagrams.
So far I've been creating figures using Visio or LibreOffice Draw,
then saving as a PNG and including. I intend to transition to
embedded diagrams, and my tool of choice is [Mermaid][]. Mermaid
converts text diagram descriptions into embedded SVG, turning
this:

```markdown
graph LR
subgraph one
A-- flows -->B
end
subgraph two
C-- connects -->D
end
A-->D
```

Into this:
<img class="ctr" src="/post-images/mermaid-sample.png" style="max-width:100%;max-height:375px;" />

Best of all, since Mermaid searches for graph descriptions inside a `<div>` with the
"mermaid" CSS class, and Remark supports CSS classes, I can drop this graph into a
set of square brackets and render it right into a slide. 

As an aside, I struggled a little with this combination, since on non-displayed
slides the rendered SVG ends up with zero size. I'm sure there's a more elegant solution;
for the moment my workaround is to ask Mermaid to render each slide as it is displayed,
using a Remark hook to find out when the current slide changes.

Of course, for presentations that need to look really good, rendering slides this way
can take as long or longer since you can't just grab a piece of text in a WYSIWYG editor
and move it where it needs to go. But for slides that need to look reasonably nice,
while being very easy to generate, I think I've finally found a solution I'm happy with.

[Remark]:http://remarkjs.com/#1
[Markdown]:https://daringfireball.net/projects/markdown/
[Beamer]:https://en.wikipedia.org/wiki/Beamer_(LaTeX)
[Pandoc]:http://pandoc.org/
[Mermaid]:http://knsv.github.io/mermaid/

