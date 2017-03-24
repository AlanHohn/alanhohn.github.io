---
layout: post
title: "Writing for the Web in Markdown with Strapdown"
description: ""
category: articles
tags: []
---

Zone: Web Dev

TLDR: Writing in Markdown is more enjoyable than writing in HTML,
and Markdown files are easier to version control and backup than
content in a CMS.

As a Zone Leader here at DZone, I try to contribute as many interesting
articles as time permits. So I spend a lot of time writing with a
Web page as my target.

By the way, there are a lot of fun parts to being a Zone Leader,
including getting to know the great people at DZone and in the
[Zone Leader Program][zl]. If you're someone with an interest in
writing and some expertise to share, it's worth checking out. If
nothing else, we have a great set of Slack channels.

[zl]:https://dzone.com/pages/zoneleader

Like most web sites focused on content, DZone has a Content Management
System. It does a lot of really nice things, including full page
import of articles from a URL, which helps us post content from all
the great [Most Valuable Bloggers][mvb] out there. It also handles image
import, sizing, and reflow, and other nice things.

[mvb]:https://dzone.com/pages/mvb

But most of my work is text content, and I prefer to have a backup copy
of it, in case I suddenly lose my Internet connection. I also like to
be able to version control it in a Git repository. And it may seem strange,
but I really prefer writing article content in Vim, both because of the
reduced clutter, and because I like to reserve my browser for searching for
all the random links I include.

At the same time, I don't want to just write a wall of text and upload it.
I like to be able to embed format, especially for those articles that have
lots of code samples. So I cast around for a while and settled on [Strapdown][sd],
a JavaScript library for rendering Markdown in a browser.

[sd]:http://strapdownjs.com/

Part of this was the desire to write in Markdown. As I started using GitHub
more, and especially as I started a blog using [Jekyll][jek] and wrote [a book][cg]
using [GitHub pages][ghp], I grew to really like slamming out content in that
form, to the point that I switched all of the courses I teach to using Remark,
as I described in a [previous article][pa]. Writing in Markdown allows me to
render to HTML with formatting included, which then copies and pastes nicely into
a CMS, whether the DZone CMS or something like [Atlassian Confluence][confl].

[jek]:https://jekyllrb.com/
[cg]:http://blog.anvard.org/conversational-git/
[ghp]:https://pages.github.com/
[pa]:https://dzone.com/articles/presentations-with-remark-and-mermaid
[confl]:https://www.atlassian.com/software/confluence

For a while, I used Jekyll to write DZone articles, but I wanted to get away
from having to have a separate process running while I was writing. Strapdown
answers the need. With Strapdown, I keep every article in its own HTML file,
starting with a basic HTML template that wraps the content and is the same for
every article.

For example, the template in which I'm writing this article started out
like this:

```html
<!DOCTYPE html>
<html>
<title>DZone Article</title>
<link rel="stylesheet" href="assets/mermaid.css" type="text/css"/>
<xmp theme="united" style="display:none;">

---
layout: post
title: "content here"
description: ""
category: articles
tags: []
---

< /xmp>

<script src="assets/strapdown-0.2.min.js"></script>
<script src="assets/mermaid-0.5.3.min.js" type="text/javascript"></script>
<script type="text/javascript">
    mermaid.initialize({startOnLoad:true});
</script>
</html>
```

I had to sneak a space in there, since the "xmp" end tag marks the end of the Markdown
content. However, I didn't have to escape any of the rest of the HTML. This is a big
deal since code and XML tends to be full of characters that would cause issues
if the browser tried to render them.

Strapdown supports GitHub-flavored Markdown, including fenced code blocks with
syntax highlighting. Things like embedded image tags work, so I can include content
and see how it will render in the article. Best of all, starting a new article is
just copying a template file, and I can give the content one last review in the browser
before pasting it into a CMS; writing in Vim is nice but for some reason some grammatical
issues don't come up until I read it in the browser.

Overall I'm pretty satisfied with this approach, though like all good software developers
I'm always interested in new tools, because [yak shaving][ys] is always more interesting
than getting real things done. So I'm interested to see if anyone has suggestions in the
comments.

[ys]:http://sethgodin.typepad.com/seths_blog/2005/03/dont_shave_that.html

