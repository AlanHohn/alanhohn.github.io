---
layout: post
title: "About Transactions"
description: ""
category: articles
tags: []
---

Zone: Integration

TLDR: Transactions are important but can be complex and confusing
when getting started. This article provides an introduction
to the terms and thinking behind transactions.

## Transactions Are Important

The famous "pennies for everyone" scheme in the movie *Office Space*
was based on transferring fractions of a cent to an account with
every transaction a bank performs. So obviously transactions are
important, at least to the plot of that movie.

But banking software that didn't have transactions would be in
even worse shape. Every transfer from one account to another involves
changes to two different data items in different places. If
only one of those changes happens, someone is not happy. If I'm
transferring money to a savings account, and my checking account
doesn't get reduced, I'm happy but the bank is not. If the money
doesn't make it into the savings account, the bank has an angry
customer.

So if the bank didn't have transactions, our movie characters could
accumulate money very quickly by just adding a bug that caused one
half of a few transfers to fail. Then they could exploit that bug
to create "free money".

Since I'm old enough to have played games on Bulletin Board Systems, I remember
a similar example from the famous game Trade Wars. One of its exploitable bugs
was the ability to "clone" a planet, complete with all its resources, by taking
the right series of steps when displaying planet data. First, you loaded a
planet's data into the right memory structure, then skipped over to another
planet in a way that wouldn't load its data. Then, you took one more step that
would write the first planet's data to the second planet's storage location.
Again, free money.

This, too, is a bug related to transactions. The act of changing a
data store needs to be encapsulated; if it happens as a side effect,
then it is not "transactional" and there is a risk of data integrity
issues.

Nowadays, when we often choose NoSQL document or graph
stores, transactions are still important. If anything, they are more
important, because when we're dealing with a distributed database that
is "eventually consistent", we can live with the idea that we are reading
old data, but we can't live with the idea that we are dealing with
partially updated data. Even the recent MtGox Bitcoin debacle can be
[laid at the feet of transaction issues][mtgox], specifically failure
to identify and properly roll back an invalid transaction.

[mtgox]:http://falkvinge.net/2014/02/11/the-embarrassing-fact-mtgox-left-out-of-their-press-release/

## Basic Transactions

A transaction is really just a way to combine multiple actions so either
they all happen, or none of them happen. There is no magic that makes sure
that the parts of a transaction will succeed; the transaction just creates
a way to box them up so that, if any one fails, no changes are made.

The simplest kind of transaction takes place within a database. When making
changes in a transaction, the database keeps track of the multiple SQL
statements we issue, and holds those changes back. While we're continuing to
make those changes, anyone who reads the same tables will see the data as if
none of our statements had been issued. Then, when we perform the "commit",
all of the changes are made at once. If done correctly, there is no "window"
where someone reading from the database would see some but not all of the
changes. We use the term "atomic", coming from the Greek word "atomos", which
means "indivisible". (Turns out the atom itself wasn't atomic, but our
transactions should be.)

This same concept applies to distributed databases with eventual consistency.
It might take a relatively long time for my local copy of the database to
reflect changes that were made on the other side of the network, but I should
never be able to see part of a data update.

## Distributed Transactions

That simple approach to transactions works fine as long as there is a single
database. It even works with a distributed database as long as any one node
can accept changes on behalf of all of the nodes. Where it doesn't work is
when multiple services get involved across a distributed system. For example,
we can introduce the idea of coordinating a change with a remote system. In
this case, not only do I need to make changes to my local database, I need to
make sure the remote system has accepted the change and makes it to the remote
system as well. Otherwise, I risk having data integrity issues where I think
something went through, but the other system thinks it didn't.

To address this, we need a way to carry out the transaction in a distributed
way across all of the systems involved. We start by informing all of the systems
of the start of the transaction. Then we tell the systems what the changes are,
giving each system a chance to acknowledge or reject the change.  Then we tell
everyone that the transaction is committed. This way, if there is some problem
in the request to the remote system, we find out about it before committing the
local change, and no one is updated. Also, if we find some issue in our local
change, we can tell the remote system to roll back the transaction, and it will
not change.

## Two Phase Commit

There is one small problem left with this approach, which is that it leaves
a window where a system accepts a change, but that change later becomes invalid.
This can happen because there's no guarantee that a transaction will be done
"quickly"; the whole point of transactions is that we can take our time, because
no one will see our changes until we commit.

For example, let's say that we accepted a change to update a row in a table.
Then, before that change is committed, some really fast transaction comes through
(probably running on a nicer computer) and deletes the row. We can't update it
any more, and it wouldn't be right to just pretend we updated it before it was
deleted, because the order of the operations might matter. (Picture someone
closing their account while a money transfer is in progress. Another chance for
free money!)

Instead, what we need is a way to reject the transaction just at the point it's
committed. This would be fine if the transaction is local to us. But by that 
point, everyone else involved has also been told to commit, so it's too late
for us to back out now.

To address this, distributed transaction processing, like [XA transactions][xa]
from [the Open Group][og], splits transactions up into two phases. In the first
phase, like Col. Sanders in *Spaceballs*, everyone is told to "prepare" to
commit. This is the time to check to make sure we can still perform the change
we accepted previously. It is also a time to lock down any resources we are
going to change, because the commit is coming quickly. ("Sir, hadn't you better
sit down?")

[xa]:https://dzone.com/articles/xa-transactions-2-phase-commit
[og]:http://pubs.opengroup.org/onlinepubs/009680699/toc.pdf

If we reject the prepare step, the transaction is rolled back, and no one changes.
If we accept the prepare step, we are agreeing that when the transaction is
committed, we definitely are going to be able to perform it. No waffling around.
When the commit does come, then, all the interested systems can be confident that
everyone else also performed the change.

## The SMOD Scenario

I'm sure you can think of scenarios where even this level of protection isn't 
enough. What if there's a bug and the change isn't made correctly? What if
the power goes out on the data center just as the transaction is half committed?
What if the [Sweet Meteor O' Death][smod] wins the 2016 U.S. presidential
election and destroys us all?

[smod]:https://twitter.com/smod2016?lang=en

Of course, the answer is, sometimes bad things happen to good computers. In these
cases, there are a few things we can do. We can keep good logs (including transaction
logs, which are just statements about the changes we intend to make), so we can go back,
forensic scientist style, to figure out what happened and how to manually make it right.

We can build in "compensatory" logic, so if we issue a commit and don't hear back from
everyone that was supposed to do the commit, we have a way to "undo" the change. (Of
course, that presents its own issues, because the absence of evidence is not evidence
of absence. Just because the other system didn't acknowledge the commit doesn't mean
it didn't do it. Maybe it was the acknowledgement that got lost.)

Overall, fortunately, these are extreme edge cases, and we often have human beings
involved to check that things were done correctly, especially for very important
transactions. There are multiple reasons that banks have a daily limit on ATM withdrawls;
a computer bug is definitely one of them.

## Conclusion

If you've never had to write code that uses transactions, or if you just followed the
usual rules for transactional code (i.e. if anything goes wrong, throw any handy exception
to cause a rollback), I hope this was a useful explanation of why that transactional
code is important and why it needs to be as complex as it is. If you're already familiar
with transactions, but you read to the end, I hope the literary and cultural references
were entertaining enough to be worth your time.

