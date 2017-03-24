---
layout: post
title: "Beyond Beginning Git: Exclude and Interactive Add"
description: ""
category: articles
tags: []
---

This article is the second of a series describing tips and tricks on the way to
mastery. The [first article][first] described how Git uses the index to track
changes ready for commit and what it means when we need to back out changes
before commit.  This time, I want to describe a couple different things I've
found useful: negative exclusions and interactive add.

## Negative Exclusion

In Git, we use a `.gitignore` file to exclude certain files, usually build
outputs or per-developer customizations. The `.gitignore` file can be at
any level of the tree and applies to that directory and all its subdirectories.

Recently, I had a whole subdirectory that I wanted to exclude from the commit,
because it contains build time customizations that each person creates.
However, I wanted the directory to exist and include a README file to help
describe the purpose of the directory and the format of the files that should
appear there. (Of course, because Git does not store directories, there has
to be a file in it for the directory to be created on a `clone` or `merge`.)

It so happens that `.gitignore` is applied at `git add` time. So it would be
possible to add the file first, then create the entry into `.gitignore`. But
this would be pretty confusing to anyone maintaining the code, and it would
mean having to use `add -f` to force the README file in if it has to be
changed later.

Instead, we can explicitly "re-include" that one file. To do this, add an
exclamation point to the front of the pattern. For example, if the directory is
called "custom", the `.gitignore` entries would look like:

```
custom
!custom/README
```

Git applies items from `.gitignore` in order, so the "re-include" needs to be
after the exclude in the file.

## Interactive Add and Staging Hunks

One of Git's advantages is that commits and branches are cheap and local.
Even when using tools like [Gerrit][] that make a big deal out of individual
commits for some reason, we can work in local feature branches and [squash merge][squash].

So if we're doing things right, we're committing often and keeping the
working tree clean. Or, if we're in the middle of some changes and need to switch
over to working on something else, we can use `git stash` to tuck the changes away
temporarily, make the other change, then `git stash pop` to get them back.

But sometimes it happens that we decide a change to a file should be split into
two commits, or we have some long running work that isn't ready to be
committed, and when we made the quick change we forgot to stash. In that case,
there is a nifty little feature in `git add` that can help: interactive mode.

Since we're talking about staging, and bad puns aren't yet against the law in
the state where I live, I'll use a Shakespeare example somewhat modified from
my [Git book][book]. Start with a basic text file; we'll call it "spear":

```
Claudio: Can the world buy such a jewel?
```

And add it to the index with `git add spear`.

If we edit the file a little:

```
Benedick: Would you buy her, that you enquire after her?
Claudio: Can the world buy such a jewel?
Benedick: Yea, and a case to put it into.
```

If we wanted to pick up the first change, but not the second, we can run `git
add -i spear` to get a menu:

```
$ git add -i spear
           staged     unstaged path
  1:        +1/-0        +2/-0 temp/spear

*** Commands ***
  1: status   2: update   3: revert   4: add untracked
  5: patch    6: diff     7: quit     8: help
What now> 
```

If we answer `5` or `p` we go into patch mode and Git will prompt us with
each file, then once we've selected the files, with each "hunk" individually:
```
What now> 5
           staged     unstaged path
             1:        +1/-0        +2/-0 temp/spear
Patch update>> 1 
           staged     unstaged path
* 1:        +1/-0        +2/-0 temp/spear
Patch update>> <<< hit enter >>>
diff --git a/temp/spear b/temp/spear
index ff2a04f..9be7492 100644
--- a/temp/spear
+++ b/temp/spear
@@ -1 +1,3 @@
+Benedick: Would you buy her, that you enquire after her?
 Claudio: Can the world buy such a jewel?
+Benedick: Yea, and a case to put it into.
Stage this hunk [y,n,q,a,d,/,s,e,?]? 
```

Note at this point Git is treating these two changes as a single hunk,
even though they are separated by an unchanged line, because of how close 
together they are. Fortunately, we can quickly change this by using
the "split" option:

```
Stage this hunk [y,n,q,a,d,/,s,e,?]? s
Split into 2 hunks.
@@ -1 +1,2 @@
+Benedick: Would you buy her, that you enquire after her?
 Claudio: Can the world buy such a jewel?
Stage this hunk [y,n,q,a,d,/,j,J,g,e,?]? 
```

Now we can select the first change, but not the second:

```
Stage this hunk [y,n,q,a,d,/,j,J,g,e,?]? y
@@ -1 +2,2 @@
 Claudio: Can the world buy such a jewel?
+Benedick: Yea, and a case to put it into.
Stage this hunk [y,n,q,a,d,/,K,g,e,?]? n

*** Commands ***
  1: status   2: update   3: revert   4: add untracked
  5: patch    6: diff     7: quit     8: help
What now> 7
```

This was a lot of menus to traverse. Fortunately we can skip straight to
looking at patches for an individual file by just using `git add -p`. That
avoids the top-level command menu. But I wanted to show the top level command
menu as well because there are some other neat functions there to explore.

Of course, this might seem unnecessary when there are good graphical diff tools
integrated into IDEs like Eclipse that can also stage partial files. But if
you're like me, you often work on remote machines, editing and committing in
environments where firing up those tools isn't straightforward. Knowing how to
do this on the command line is like knowing how to use `vi` or `emacs`; it
seems unnecessary until you make the leap, then it becomes a treasured part of
the toolbox.

[first]:https://dzone.com/articles/beyond-beginning-git-working-tree-index-and-head
[Gerrit]:https://code.google.com/p/gerrit/
[squash]:https://git-scm.com/docs/git-merge
[book]:http://blog.anvard.org/conversational-git/

