---
layout: post
title: "Beyond Beginning Git: Working Tree, Index and HEAD"
description: ""
category: articles
tags: []
---

TLDR: Once you get past the first few commands, you learn Git
by solving the next problem. This article describes a common
problem that helps us learn a little about how Git works. /TLDR

Every team using Git has that person who is an expert; the person
that everyone asks when some strange thing goes wrong. That person
usually got where they are one command at a time, starting with
just a little more knowledge and then building on it by helping
other people. At least that was my experience. I'm hoping to
help people jumpstart this process with some articles that 
present common problems I've seen where the solution comes
in handy lots of times.

This article is not intended for people who are brand new at Git.
If that's you, there are lots of articles and books out there to 
help you, but I hope you'll consider reading through [Conversational
Git][cg], my short open source ebook.

## Adding with Dry Run

It's a common problem, especially with the first commit to a repository, to end
up with files that shouldn't be staged. Of course, the `.gitignore` file is the
way to prevent this; Git will respect patterns it's told to ignore when adding
a directory tree. But sometimes the right patterns aren't in `.gitignore` yet.

The best thing, when adding a directory that might have undesired files is to
use `-n` to dry run the add command first. For example, if we have a directory
`code` with `code.c` and `code.o`, and we haven't committed yet, we might see
this status:

```
$ git status
On branch master

Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)
  
    code/
    
    nothing added to commit but untracked files present (use "git add" to track)
```

If we run `git add code` but we forgot to exclude object files first, we
will stage both source and object files:

```
$ git add code
$ git status
 On branch master

 Initial commit

 Changes to be committed:
   (use "git rm --cached <file>..." to unstage)

    new file:   code/code.c
    new file:   code/code.o
```

If we use `-n` or `--dry-run` we would find out the issue in advance:

```
$ git add -n code
add 'code/code.c'
add 'code/code.o'
```

Then we could fix it:

```
$ echo '*.o' > .gitignore
$ git add -n code
add 'code/code.c'
```

## Unstaging Files

But what happens if we forget to check first? There is a fix, right
there in the Git output: 

```
(use "git rm --cached <file>..." to unstage)
```

So the mistake and the fix look like this:

```
$ git add code
$ git status
On branch master

Initial commit

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

    new file:   code/code.c
    new file:   code/code.o

$ git rm --cached code/code.o
rm 'code/code.o'
$ git status
On branch master

Initial commit

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

    new file:   code/code.c

Untracked files:
  (use "git add <file>..." to include in what will be committed)

    code/code.o
```

That seems great, but don't get used to that command. Instead, keep
reading.

## HEAD, Index, and Working Tree

If you've read tutorials on "unstaging" files, they generally suggest using
`reset HEAD` to unstage a file. So why does Git tell us to use `rm --cached`
in this case? We don't want to delete the file, just avoid committing it.
The answer is, we can't do `reset HEAD` because we don't have a HEAD yet.

First, a brief word about how Git keeps track of files that have been committed
or are ready to commit. The area where we view and edit files, Git calls the
"working tree". When we run `git add`, whether it's on a brand new file or
just one we've changed, Git doesn't just mark the file for commit, it saves a
copy from the working tree to an area it calls the "index". You can verify this
by creating a file, adding it, editing it, then doing `git status`. The file
will show up both as added and modified. 

So when we've accidentally added a file we don't want committed, what we
really want Git to do is remove it from the index. That's exactly what
`git rm --cached` does.

"HEAD", meanwhile, is Git's name for the latest commit on the current branch
(the "tip"). For our brand-new repository, there is no "HEAD" yet, so it really
doesn't make any sense.

But usually we do want `reset HEAD`. In fact, if `reset HEAD` is the right
answer, Git will even tell us so:

```
( After an initial commit )

$ git add .gitignore code
$ git status
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

    new file:   .gitignore
    modified:   code/code.c
```

In this case, `reset HEAD` will update the index to match "HEAD". (Updating
the index, but not the working tree, is the default for `reset`.) That
means the working tree still has the changes, but the index has no change since
the latest commit, which is exactly what we want.

For the added file, we could choose to use `git rm --cached` or `git reset HEAD`,
because either removes the file from the index. But for the modified file, we
don't want to use `rm --cached`, because that will tell Git to stage the file
for deletion! This is true because Git will now mark that file as removed in
the index, when it exists in HEAD. So there's now a pending deletion if we do
`git commit`.

This is a pretty confusing situation. The confusion comes in because the term
"add" is overloaded for both adding new files and for staging modifications to
existing files. Really, it would be best if we could use `reset` as the universal
command for unstaging files. And with a modern version of Git, we can. If
we use `git reset` in a case where there is no HEAD, it will just remove the file
from the index, which is exactly what we want.

So our previous example becomes:

```
$ git status
On branch master

Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)

    code/

nothing added to commit but untracked files present (use "git add" to track)
$ git add code
$ git status
On branch master

Initial commit

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

    new file:   code/code.c
    new file:   code/code.o

$ git reset code
$ git status
On branch master

Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)

    code/
```

So the only thing left is for the suggestion message to reflect the
new capability of `reset`, so we don't have to be confused. But
at least we picked up a little more detail about Git along the way.

[cg]:http://blog.anvard.org/conversational-git/

