---
layout: post
title: "Beyond Beginning Git: Bundle and Retrospective Branching"
description: ""
category: articles
tags: []
---

Zone: Agile

TLDR: Useful Git fixes for special circumstances.

In a couple previous articles, I talk about features that go beyond the first
steps in Git. In the first I discussed [the working tree, index, and HEAD][1].
In the second I discussed [exclude and interactive add][2].

Recently a couple other features became useful to me: bundle and retrospective
branching. As always, I will discuss the "why" of the feature and how it should
be used but much more information is available in places like [this one][3].

### Git Bundle

One of the earliest features of Git was the ability to format patches, which
are plain text lines representing the changes being made by a commit. The
advantage of using a plain text format is that it can be sent by any
Internet means, including being embedded into the body of an email, and can
be reviewed by a human being to see if it makes sense before applying it is
applied. The Git patch format is standard enough that the tool can apply
patches to an existing code base. This meant that, even before the existence
of tools like [Gitlab][4] or [GitHub][5] with web-based code review, Git
users could leverage email or mailing lists to perform review. Git itself
still [works this way][6].

But this format really doesn't lend itself to lots of changes, and it loses
some information like the names of branches and tags. So for transferring a
repository from one place to another without direct ability to push / pull,
format-patch isn't the right answer. Of course Git is a distributed version
control system, so it would work just fine to tar up the `.git` directory
of some repository, untar it elsewhere, and use it as a temporary "remote"
for ordinary push / pull. But this represents a few extra steps that could
accidentally be messed up, and it's very inefficient to do this with large
repositories when only a few changes are being made.

This is where `git bundle` comes in. Let's say we have a computer that is
not connected to the Internet. (In my business, this is very common for
labs, as we try not to be extremely or grossly careless or negligent in the
protection of information.) We want to carry source code over to this
system, because we need it for reference or in order to compile in some
data or algorithms that can't leave the private network. We start by
making a bundle on the Internet side:

```
git bundle create repo.bundle master
```

Git spits out the file `repo.bundle` that includes all of the commits
necessary to create the master branch. Since every commit references
at least one parent, all the way back to the beginning of the repository,
this will end up giving you all the commits in master's history as well.

This file gets transferred to another machine. Since this is the first
time, we want a new repository, so we clone directly from the bundle:

```
git clone -b master repo.bundle myrepo
```

The `-b master` is needed for bundles because, unlike normal remote
repositories, they don't have the concept of a HEAD. So we have to
tell Git "choose the branch named 'master' inside the bundle to be
our new HEAD".

So far this isn't much easier than just tarring up a whole Git
repository. But when it's time to update, the bundle is better.
Let's say a week has gone by and we want all the changes made since
the last time we synced things up. This time we do:

```
git bundle create repo.bundle --since=8.days master
```

This will create a bundle with just the necessary commits. (I added
an extra day to make sure we don't get bitten by the clock. Extra
commits are OK; Git will know it already has them.)

We put this bundle file onto our lab system, replacing the previous
one, and just do:

```
git pull
```

And it works! When we cloned from the bundle, Git set up a remote
"origin" just like any other clone. So we can pull from it, and
any commits we don't have will be brought in.

This is much easier. And it can go both ways; we can use bundles
on the disconnected system to update the original. We've used this
technique when sharing code with team members that is proprietary
but where there's no common private Git repository everyone can
write to.

### Retrospective Branching

This is a technique I use a lot, because while I'm a proponent of
[feature branching][7], I don't always practice what I preach. So
I get in the habit of just committing to master.

As a result, lots of times I commit to master, then remember that
I should have made a feature branch. Fortunately, Git is flexible
enough that I can quickly fix it.

First step is to make sure the working copy is clean. Any time we
are going to mess with branches it's best to start clean. If
`git status` doesn't say, "nothing to commit, working tree clean"
we should start by doing `git stash` to save things away.

Next, we make the branch we should have made. We can just do this
with `git branch <name>`. We don't want to check out this branch.
The new branch will already have the commit we made because that's
the point we're branching from.

Next step is to fix "master". We want master to back up one commit.
The right command for this is `git reset`, but we have a decision
to make. I'm really careful about `git stash` before I start this,
so I use:

```
git reset --hard HEAD^
```

The `HEAD^` part tells Git to set the branch to the parent of the current
commit. (Since we're talking about some work we just did and committed, we
don't have to worry about this being a merge, which wouldn't work the same.)

The `--hard` part tells Git to update the [working tree][1] to match the new
HEAD. This is potentially dangerous if we weren't careful about `git stash` for
any changes. If you want something safer, you can try `git reset` without the
`--hard` parameter to get the branch and index updated, then `git checkout master`
to update the working tree. That's safer because it will abort instead of
overwriting changes. Or, you can try `git reset --keep HEAD^`, which does about
the same thing in one step.

Either way, the result is that master is fixed. The commit we made is still safe,
because we left it on the other branch. We can now `git checkout` to that branch
to work with it again. We should also `git stash pop` if we ran `git stash` to
get our uncommitted changes back.

If we need a specific commit that is not the immediate parent, Git has some
fancy tricks, like `HEAD@2` for going back two commits. But I find it easier to
just use `git log` to figure out exactly which one I want, then copy/paste the
SHA-1 for the `git reset` command.

I use exactly this technique for tagging as well; a lot of times I'm tagging
retrospectively as the code moves quickly and we identify a specific commit that
should become a release. Any commit in the repository can become a tag
retrospectively, like this:

```
git tag mytagname <SHA-1>
```

You can even backdate the tag if that's important to you.

In my short book [Conversational Git][8] I am trying to introduce Git to people
for whom it is not yet second nature, so I intentionally don't talk about Git
in terms of its Directed Acyclic Graph (DAG) of commits. But here's a case
where I find it very useful to think in those terms, because it helps to
visualize exactly what each command above is going to do and what the target
state of the repository is.  Being able to think in those terms will get you to
the point where you become the "Git expert" for your team, if that's the kind
of thing you're interested in.

[1]:https://dzone.com/articles/beyond-beginning-git-working-tree-index-and-head
[2]:https://dzone.com/articles/beyond-beginning-git-exclude-and-interactive-add
[3]:https://git-scm.com/book/en/v2
[4]:https://about.gitlab.com/
[5]:https://github.com/
[6]:http://git.kernel.org/cgit/git/git.git/plain/Documentation/SubmittingPatches?id=master
[7]:http://martinfowler.com/bliki/FeatureBranch.html
[8]:http://blog.anvard.org/conversational-git/

