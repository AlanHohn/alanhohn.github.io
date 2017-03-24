---
layout: post
title: "Inside VRRP: Applications"
description: ""
category: articles
tags: []
---

Suggested Zone: Cloud

TLDR: Despite the name, VRRP isn't just for router redundancy.

Over the past few articles, I've been showing the details of the Virtual Router
Redundancy Protocol (VRRP). In the [first][1] article I introduced the
technologies. In the [second][2] I showed a virtual lab using Vagrant, while in
the [third[3] I showed packet captures to reveal the details behind how it
works.

This time I want to discuss real-world applications. It's obvious from the name
that the original purpose is to provide redundancy for routers. So let's start
with that one first.

### Redundant Routers

Imagine a typical local area network (LAN) like you might find in a home or
small office setting. Most of the nodes on this network are hosts connected
through a switch or wireless access point. A single router provides the
connection to the broader Internet.  (A lot of times the router serves as
switch and wireless access point, but if your network is like mine that doesn't
get you far enough for all devices.) So the setup looks like this:

![Small LAN](/diagrams/vrrp-router.uml.png)

The key insight is that this is an edge network, with a single path for
internetworking. As a result, in this configuration the router is a single point
of failure. For home or small office networks we live with this and just
quickly buy a replacement if there's a failure. But we might have a similar
setup for a corporate extranet, where a few servers (including a web server,
email server, and virtual private network (VPN) server) are exposed to the
Internet in a "demilitarized zone" (DMZ), connected through a single router with
a firewall in order to protect the corporate intranet from attacks from the
public Internet.

In this case, downtime is not acceptable, and we need a different solution.
This is the case that VRRP was originally designed for. We instead have
two or more routers, each with an address on the Internet side. On the
"inside" the routers share a virtual IP (VIP), which is the default gateway for
all of the nodes on the inside. It looks like this:

![Redundant Routers](/diagrams/vrrp-redundant-router.uml.png)

We would also want to make the switch and the wireless access
point redundant, but this can be accomplished at lower levels of the
network stack (i.e. link level or physical). Note that the two routers
don't even have to be connected to the same Internet Service Provider
(ISP), so we can ensure service even if the failure is outside our
control.

One more thing to note is that we're getting redundancy but not load
balancing from this setup. Our hosts are only configured with one
default gateway, and only one router has the VIP at a time. 

### Redundant Servers

So far VRRP has gotten us redundant routers, so our network doesn't
lose connection to the Internet if we lose a router. But our individual
hosts are still single points of failure. If we are in a DMZ, with a
web and email server on a corporate extranet, we need those services
to be redundant so the loss of a server doesn't take us down.

We can still use VRRP in this scenario. We install a VRRP implementation
like [keepalived][4] on each server, and configure separate virtual
router IDs for each service. The result looks like this:

![Redundant Servers](/diagrams/vrrp-redundant-servers.uml.png)

Again, I left off the redundant switch connections to keep the diagram simpler.

Each separate server type has a separate VIP within the DMZ LAN. To really get
the benefit of this design, the VIP addresses assigned to the servers should be
publicly addressable; that way there can be a single entry in the Domain Name
Service (DNS) for the service. If we tried to use private addresses, with our
router performing Network Address Translation (NAT) and port forwarding, we
would have to work around our redundant routers, either with multiple DNS
entries (DNS round robin) or with a VIP on the Internet side of the routers.
Neither is straightforward.

This still doesn't get us load balancing, so let's add that next.

### Load Balanced Servers

To add load balancing, I need another service that will accept connections
on its "front end" and then choose a "back end" service to send it to. For
Linux, [HAProxy][5] is an excellent choice, able to handle everything from
basic TCP/IP up to specific applications like HTTP. It can do sophisticated
things like session affinity through HTTP cookies. This avoids the need for a
single user session store across all the back end services by sending the same
user to the same back end during the entire session. So our back end services
are less dependent on each other and are easier to create.

HAProxy does the back end load balancing, but it doesn't provide failover on
the front end. So we use both HAProxy and Keepalived together. Only one
HAProxy will be active at a time, but it doesn't use much resources so that's
OK. If we focus on the web server from our previous example, it looks like
this:

![Load Balance](/diagrams/vrrp-load-balance.uml.png)

This topology diagram doesn't do justice to the architecture, so let's just
take the Ethernet switch as understood and show the TCP/IP connection
architecture:

![Load Balance Connections](/diagrams/vrrp-load-balance2.uml.png)

I labeled the connections from the load balancers to the web servers as "LB"
to show that they are all in use simultaneously rather than just used for
failover. Only one pair of "LB" connections is used at a time, based on
which load balance server has the VIP.

Of course, we can have as many web servers as we need to meet demand, and
as many load balance servers as we need to sleep at night.

### Router Load Balancing

One more topic is worth adding. Let's say that we have multiple Internet
providers and have connected one to each redundant router. We want to
use both providers under normal conditions to improve performance. Each
router will have a different IP address on its exterior connection, so
we need some way to get traffic coming in and going out over both
routers.

We start by ensuring we have a public IP address for the services we're
providing (like our web server). That way, no matter where the client
traffic is coming from, there's one destination for routing.

Next, we need some cooperation from our Internet providers. They are
going to need routing table entries for our public IP addresses.
Depending on where we get the addressses, at least one of our providers is
going to need to add a special route for us. If we get our address
from one provider, the other provider needs a special route so they don't
send traffic for us through the other provider. If we get our address
independent of either provider, they both have to add routes.

Once we have that, we have a way for our clients to route traffic
through whichever of our routers is "closer" to them. But we need
to get the traffic back efficiently as well. To do this, we need to
customize our routers. We add routes to each of our routers that
reference the other router. So if we know that certain address ranges
are best routed through provider A, we add a route to router B so it
sends the packet over to router A rather than just sending it to its
default gateway. And vice versa for cases where provider B is better.

If one of our routers fails, this route will stop working and the
remaining router will just use its default gateway for everything.
So we still keep our failover but we get load balancing too.

At this point, we've gone about as far as we can go with the
available technologies. The next step would be to put our services
in different physical locations so we can provide quality service
no matter where the client is located. Unfortunately we can no
longer have a single IP address for our service, so we need a
smarter DNS with something like geolocation routing (for example
a service like [Amazon Route 53][6]).

[1]:https://dzone.com/articles/inside-vrrp-introduction
[2]:https://dzone.com/articles/vrrp-virtual-lab-with-ubuntu-xenial-and-vagrant
[3]:https://dzone.com/articles/inside-vrrp-packet-captures
[4]:http://www.keepalived.org/
[5]:http://www.haproxy.org/
[6]:http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html#routing-policy-geo


