---
layout: post
title: "Algorithms: The Assignment Problem"
description: ""
category: articles
tags: []
---

One of the interesting things about studying optimization is that the
techniques show up in a lot of different areas. The "assignment
problem" is one that can be solved using simple techniques, at least
for small problem sizes, and is easy to see how it could be applied
to the real world.

## Assignment Problem

Pretend for a moment that you are writing software for a famous
ride sharing application. In a crowded environment, you might have
multiple prospective customers that are requesting service at
the same time, and nearby you have multiple drivers that can take
them where they need to go. You want to assign the drivers to the
customers in a way that minimizes customer wait time (so you keep
the customers happy) and driver empty time (so you keep the drivers
happy).

The assignment problem is designed for exactly this purpose. We
start with `m` agents and `n` tasks. We make the rule that every
agent has to be assigned to a task. For each agent-task pair, we
figure out a cost associated to have that agent perform that task.
We then figure out which assignment of agents to tasks minimizes
the total cost.

Of course, it may be true that `m != n`, but that's OK. If there
are too many tasks, we can make up a "dummy" agent that is more
expensive than any of the others. This will ensure that the least 
desirable task will be left to the dummy agent, and we can remove
that from the solution. Or, if there are too many agents, we can
make up a "dummy" task that is free for any agent. This will ensure
that the agent with the highest true cost will get the dummy task,
and will be idle.

If that last paragraph was a little dense, don't worry; there's
an example coming that will help show how it works.

There are special algorithms for solving assignment problems, but
one thing that's nice about them is that a general-purpose
solver can handle them too. Below is an example, but first it will
help to cover a few concepts that we'll be using.

## Optimization Problems

Up above, we talked about making "rules" and minimizing costs.
The usual name for this is optimization. An optimization problem
is one where we have an "objective function" (which tells us
what our goals are) and one or more "constraint functions" (which
tell us what the rules are). The classic example is a factory
that can make both "widgets" and "gadgets". Each "widget" and
"gadget" earns a certain amount of profit, but it also uses
up raw material and time on the factory's machines. The
optimization problem is to determine exactly how many "widgets"
and how many "gadgets" to make to maximize profit (the objective)
while fitting within the material and time available (the
constraints). 

If we were to write this simple optimization problem out,
it might look like this:

```
maximize 45g + 40w    // Step 3: Profit!
subject to
  120g + 100w <= 4000 // Raw material 1 (we have 4000 lbs)
  80g + 80w <= 2500   // Raw material 2 (we have 2500 lbs)
  3.8g + 3.7w <= 200  // Machine time (200 hours available)
```

In this case, we have two variables: `g` for the number of
gadgets we make and `w` for the number of widgets we make.
We also have three constraints that we have to meet. Note
that they are inequalities; we might not use all the available
material or time in our optimal solution.

Just to unpack this a little: in English, the above is saying
that we make 45 dollars / euros / quatloos per gadget we make.
However, to make a gadget needs 120 lbs of raw material 1,
80 lbs of raw material 2, and 3.8 hours of machine time. So
there is a limit on how many gadgets we can make, and it
might be a better use of resources to balance gadgets with
widgets.

Of course, real optimization problems have many more than
two variables and many constraint functions, making them much
harder to solve. The easiest kind of optimization problem
to solve is linear, and fortunately, the assignment problem
is linear.

## Linear Programming

A linear program is a kind of optimization problem where both
the objective function and the constraint functions are linear.
(OK, that definition was a little self-referential.)
We can have as many variables as we want, and as many constraint
functions as we want, but none of the variables can have exponents
in any of the functions. This limitation allows us to apply
very efficient mathematical approaches to solve the problem,
even for very large problems.

We can state the assignment problem as a linear programming problem.  First, we
choose to make "i" represent each of our agents (drivers) and "j" to represent
each of our tasks (customers). Now, to write a problem like this, we need
variables. The best approach is to use "indicator" variables, where `xij = 1`
means "driver i picks up customer j" and `xij = 0` means "driver i does not
pick up customer j".

We wind up with:

```
minimize sum(i,j) Cij * xij for all i,j
subject to
  sum(j) xij = 1 for all i in A
  sum(i) xij = 1 for all j in T
  xij >= 0
```

This is a compact mathematical way to describe the problem,
so again let me put it in English. 

First, we need to figure out the cost of having
each driver pick up each customer. Then, we can calculate the
total cost for any scenario by just adding up the costs for
the assignments we pick. For any assignment we don't pick,
xij will equal zero, so that term will just drop out of the
sum.

Of course, the way we set up the objective function, the 
cheapest solution is for no drivers to pick up any 
customers. That's not a very good business model. So we need
a constraint to show that we want to have a driver assigned
to every customer. At the same time, we can't have a driver
assigned to mutiple customers. So we need a constraint for
that too. That leads us to the two constraints in the problem.
The first just says, if you add up all the assignments for
a given driver, you want the total number of assignments
for that driver to be exactly one. The second constraint
says, if you add up all the assignments to a given customer,
you want the total number of drivers assigned to the customer
to be one. If you have both of these, then each driver is
assigned to exactly one customer, and the customers and
drivers are happy.  If you do it in a way that minimizes costs, then the
business is happy too.

## Solving with Octave and GLPK

The [GNU Linear Programming Kit][glpk] is a library that
solves exactly these kinds of problems. It's easy to
set up the objective and constraints using [GNU Octave][octave]
and pass these over to GLPK for a solution.

[glpk]:https://www.gnu.org/software/glpk/
[octave]:https://www.gnu.org/software/octave/

Given some made-up sample data, the program looks like this:

```matlab
% Assignment Problem Example

% Cost information (to minimize)
c = [20 10 12 11 15 14 12 24 18 11 9 5 0 0 0 0]';

% Right-hand side (constraint)
b = [1 1 1 1 1 1 1 1];

% Coefficients (for constraints)
a = [
1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1
1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0
0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0
0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0
0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1
];

lb = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
ub = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
ctype = "SSSSSSSS";
vartype = "IIIIIIIIIIIIIIII";
s = 1;
[xmin, fmin, status, extra] = glpk(c, a, b, lb, ub, ctype, vartype, s)
```

Start with the definition of "c", the cost information. For
this example, I chose to have four drivers and three customers.
There are sixteen numbers there; the first four are the cost
of each driver to get the first customer, the next four are
for the second customer, and the next four are for the third
customer. Because we have an extra driver, we add a "dummy"
customer at the end that is zero cost. This represents one of the
drivers being idle.

The next definition is "b", the right-hand side of our constraints.
There are eight constraints, one for each of the drivers, and one
for each of the customers (including the dummy). For each
constraint, the right-hand side is 1.

The big block in the middle defines our constraint matrix "a". This
is the most challenging part of taking the mathematical definition
and putting it into a form that is usable by GLPK; we have to
expand out each constraint. Fortunately, in these kinds of cases,
we tend to get pretty patterns that help us know we're on the right
track.

The first line in "a" says that the first customer needs a driver.
To see why, remember that in our cost information, the first four
numbers are the cost for each driver to get the first customer. With
this constraint, we are requiring that one of those four costs be
included and therefore that a driver is "selected" for the first
customer. The other lines in "a" work similarly; the last four
ensure that each driver has an assignment.

Note that the number of *rows* in "a" matches the number of items
in "b", and the number of *columns* in "a" matches the number of
items in "c". This is important; GLPK won't run if this is not
true (and our problem isn't stated right in any case).

Compared to the above, the last few lines are easy. 

* "lb" gives the lower bound for each variable. 
* "ub" gives the upper bound.
* "ctype" tells GLPK that each constraint is an equality ("strict" 
as opposed to providing a lower or upper bound).
* "vartype" tells GLPK that these variables are all integers
(can't have half a driver showing up). 
* "s" tells GLPK that we want to minimize our costs, not maximize them.

We push all that through a function call to GLPK, and what comes
back are two values (along with some other stuff I'll exclude
for clarity):

```
fmin =  27
ans =
   0   1   0   0   0   0   1   0   0   0   0   1   1   0   0   0
```

The first item tells us that our best solution takes 27 minutes, or
dollars, or whatever unit we used for cost. The second item tells us
the assignments we got. (Note for pedants: I transposed this output 
to save space.)

This output tells us that customer 1 gets driver 2, customer 2 gets driver 3,
customer 3 gets driver 4, and driver 1 is idle. If you look back at the cost
data, you can see this makes sense, because driver 1 had some of the most
expensive times to the three customers.  You can also see that it managed to
pick the least expensive pairing for each customer. (Of course, if I had done a
better job making up cost data, it might not have picked the least expensive
pairing in all cases, because a suboptimal individual pairing might still lead
to an overall optimal solution. But this is a toy example.)

## Conclusion

Of course, for a real application, we would have to take into consideration
many other factors, such as the passage of time. Rather than knowing all of our
customers and drivers up front, we would have customers and drivers continually
showing up and being assigned. But I hope this simple example has revealed some
of the concepts behind optimization and linear programming and the kinds of
real-world problems that can be solved.

