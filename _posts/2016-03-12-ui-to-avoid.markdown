---
layout: post
title: "User Interface Joys and Follies"
description: ""
category: articles
tags: []
---

Zone: Web Dev

TLDR: How can a tool with a great concept and a great user interface
ultimately fail in its promise? By taking the wrong path in just
a couple big ways.

## Markdown All the Things

In my effort to [convert][a1] all [my documents][a2] to [Markdown][a3],
I have been looking for a tool that would allow the use of Markdown
for larger technical documents (the kind of thing traditionally done
in Microsoft Word). I have been looking for two main features: first,
word processor like behavior with Markdown (to simplify adoption for
new users). Second, a "project" organization concept (to gently ease
people who are used to editing a document into editing multiple
individual files that are assembled). The latter item I think is
very important for documents that are built iteratively, over time,
as otherwise it gets difficult to see and review changes.

[a1]:https://dzone.com/articles/writing-for-the-web-in-markdown-with-strapdown
[a2]:https://dzone.com/articles/presentations-with-remark-and-mermaid
[a3]:https://daringfireball.net/projects/markdown/

For this reason, I was really excited when I saw that [GitBook][gb] has
an [editor][gbe] that is cross-platform and provides both the items
I mentioned above. Unfortunately, after exploring it, it ended up not
being usable for my particular case. I strongly considered not writing about
my experience, or writing about it in a generic way that didn't explicitly
reference the tool, but I concluded that there are enough positives from 
my experience that I can write something balanced, and the negative parts
of my opinions might have broader applicability. 

[gb]:http://gitbook.com/
[gbe]:https://www.gitbook.com/editor/

## Judging a GitBook by Its Cover

Since I am going to be a little negative in parts, let me start by saying
I love the concept of GitBook. As someone who wrote a [small book][cg] in
Markdown, committed to a Git repository, of course I'm likely to feel
positive toward it. But I also like that they have an online editor, a
platform for publishing, and have done some good work to make the toolset
accessible to a wide audience, not just those of us who choose to write
articles in [Vim][vim]. If you're interested, and especially if you can
use the online editor, I encourage you to give GitBook a try.

[cg]:http://blog.anvard.org/conversational-git/
[vim]:http://www.vim.org/

On downloading and running the editor, I hit a few unfortunate items right
away. Rather than opening a blank document, the first screen is an offer to
login to a GitBook account. I recognize that GitBook would prefer to get
people signing up for accounts on the website, but being solicited first
thing into a program is unpleasant. Worse, the program doesn't appear to
check the network state, so if I'm offline I still get presented with a login
button, but clicking it brings up a blank screen. This brings me to two
important user interface rules:

* Don't assume your preferred use case is your user's preferred use case.
* Even modern computers are offline sometimes.

Clearly the preferred use case for GitBook Editor is to use the program while
fully interactive with their servers. And of course a key reason for making
an editor that can be installed locally is to convert users into signups. But
those signups are not going to happen if someone is presented with an unusable
login button as their first impression of the program. 

To their credit, there is a "Do This Later" button on the startup screen.
Unfortunately, "later" means "the next time the program is run" and "the time
after that" and so on. Which means we need a rule:

* Preference settings are not just for preference dialogs.

Users express preferences sometimes by the choices they make. In this case, my
choosing to defer signing into an account could be saved as a preference, maybe
with a dialog that tells me where to go to do it later. (In this case, there's
already a permanent login button in the corner of the main editor, so there's
no concern I'll forget how to do it.)

## Friendliness and Configurability

At this point we've gotten to a nice library screen. This is a positive, in that
it recognizes that finding previous work is a hassle, and there's real value for
a program to keep track of previous work and present it in a friendly way. At
this point, I noticed both an "Open" and an "Import" button, which was a little
confusing and should have been ominous. (Foreshadowing...) I had a few existing
Markdown files, so I tried the "Import" option. In came my files, and I could see 
my new project in the library and click it to open the editor.

At this point, I was delighted by some of the functionality. The sidebar includes
both a Table of Contents and a Files Tree; the Table of Contents is built from
a `SUMMARY.md` file.

* Don't be afraid to present a user with the same information, organized in
  different ways, as long as the difference is clear.

Depending on whether the file organization matches the book's organization, there
might be a lot of duplication between the two lists, and I can see where presenting
both could be confusing. But the two views are different, and especially since
it's possible to have files that aren't in the summary, keeping both is a smart idea.

I started editing and saving, and then started looking for the button to commit
my changes to Git. When I didn't find one, I started looking through the available
buttons and settings, and discovered that the default behavior is to commit changes
to Git on every save. This doesn't work for me, because I would like changes to
be bundled together to make them easier to review. But I don't really mind, because
I understand the motivation in hiding that from new users, and it's a configurable
setting anyway. 

* Power users don't mind customizing their preferences, as long as you make the
  settings available for them to do so.

---
layout: post
title: "The Worm Has Turned "
description: ""
category: articles
tags: []
---

#### And Full on the Town He Fell

After a few more edits, I switched back over to a terminal window that was open
to the original location where I had my files. And here's when things
started to go horribly wrong. I looked at the local file system, and none of my
changes were there! I started to realize that "Import" meant "relocate these
files".

* Don't relocate your user's files.
* No, really, just don't.
* OK, you shouldn't, but if you have to, please tell them exactly what you did.

Nothing is quite as disconcerting to a user as the idea that a program lost
changes that should have been saved. Even once you figure out that the files
are not lost, they are just somewhere else, you never really trust a program
the same way again.

I eventually found the files, conveniently hidden in `$HOME/GitBook/Library/Import`.
With relief, I moved into that directory, and started looking at both the local
files and at `git log`. Imagine my horror when I realized that even in that
directory, the working copy of my files didn't contain my most recent changes!
Sure, the changes were there in `git log`, but they weren't reflected in the
files themselves. Worse, since I turned off auto-commit, when I made changes,
saved them, but didn't commit them yet, they existed in some nebulous state,
neither in the working copy nor in the index.

This behavior is completely inexplicable to me. Why insist on relocating an
imported project into your own directory, unless it's because you want to be sure
you completely control the changes to the files? In which case, why leave files
at old versions? As just one small example of the horror that results, this approach
means that `git diff HEAD` actually shows the *opposite* of my most recent commits,
because the working copy is older than HEAD!

* Don't confound your user's understanding of how computers work.
* [You don't own][tg] those files, the user does.

[tg]:http://www.imdb.com/title/tt0092099/quotes?item=qt0447353

In his discussion of [the Unix philosophy][up], Eric Raymond talks about assuming
that the output of one program will be the input of another, and about preferring
text streams, because they are universal. The fundamental idea beneath these concepts
is to not assume that your program is the only way that the user will interact with
*their* data. Locking a user's data in a database or hiding it in an inaccessible
place on the filesystem is an anti-social practice. It might be necessary to store
data in some inaccessible place or internal format for performance, but what comes
with that is a responsibility to provide a way to get the data back out again, in
some widely accepted format. And if your whole premise is editing files in a
human-readable plain text format, and storing those files in a well known version
control tool, you really need to be making those files available in *exactly* the
same way that a user would see them if not using your tool.

[up]:http://www.catb.org/esr/writings/taoup/html/ch01s06.html

## Conclusion

At this point I concluded that, as much as I liked the concept, there was no way
I could ask my teammates to use GitBook Editor. I envisioned the confusion that
would be my responsibility to handle, as people tried to figure out how to
get at their documents without going through the tool. At the moment, I'm left
without a perfect solution; there are great Markdown "word processors", and great
editors that manage multiple files in a project, but nothing that quite combines
the two. But I have hope for the future.

