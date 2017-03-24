---
layout: post
title: "Inside VRRP: Packet Captures"
description: ""
category: articles
tags: []
---

The Virtual Router Redundancy Protocol (VRRP) provides a way for multiple hosts
to communicate so that one of them at a time can hold a virtual IP. Since VRRP
is useful for high availability and operates at the intersection of Layer 2 and
Layer 3 of the [OSI model][osi], it's an interesting topic for a better
understanding of networking.

In the [first article][1] I introduced VRRP and ARP, which is essential to its
operation. In the [second][2] I took a digression to describe the virtual lab
environment. This time I want to show the workings of VRRP through a common
implementation, [keepalived][3].

In our virtual lab, we have two servers (cleverly named `server1` and `server2`)
that both run Keepalived. These two servers work together so that exactly one of
them provides a virtual IP. This virtual IP is registered in `/etc/hosts` on all
of the machines under the name `server`, so that any of the hosts can access
something running on `server` and the traffic will go to whichever host currently
has the virtual IP.

We're going to be simulating network failures. For VirtualBox, my favorite way
of doing this is going into the network settings for a VM and unchecking the
"Cable Connected" box. This simulates disconnecting the wire. I prefer it
because it simulates a hardware failure, unlike setting the network link to down
or shutting down the machine.

One more note: when we talk about a "virtual IP" this is unrelated to "virtual lab" or
"virtual machine". It works perfectly well to have a "virtual IP" on a physical
machine. In fact, a virtual IP is an IP address on some network interface, just like
any other IP address; the only thing virtual about it is that there is no
permanent host it is assigned to.

### Keepalived Configuration

The configuration for Keepalived looks like this:

```
vrrp_instance VI_1 {
    state MASTER
    interface enp0s8
    virtual_router_id 51
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass ab55f208e802d03fc2f38a0d282b73f5
    }
    virtual_ipaddress {
        192.168.199.10
    }
}
```

There are a number of interesting notes here:

* `vrrp_instance`: There can be more than one of these, each with its own settings.
  They can be grouped together so that if one instance switches to a host, all of
  the others will follow.
* `state`: By convention we set both to MASTER, but in practice the priority and
  voting scheme decide the real master.
* `interface`: Used both to communicate between Keepalived instances and as the
  home for the virtual IP
* `virtual_router_id`: Must be the same across all hosts, and different for each
  separate virtual IP
* `priority`: 0-255. The highest priority host that is up will get the virtual IP
  (this includes "failback", where a host that lost the virtual IP comes back up
  and takes back over)
* `advert_int`: How often to send out health advertisement messages
* `authentication`: Deprecated with the [latest VRRP][vrrp]. As you will see in
  the packet captures, the password is sent in a broadcast message in the clear.
  So this wasn't even security through obscurity.
* `virtual_ipaddress`: One or more addresses that should belong to one and only
  one host.

This is the configuration from `server1`, but `server2` is identical except for
the priority, which is lower (100 by convention).

### VRRP Startup and Announcements

When Keepalived starts, it begins sending announcements. Here is an example:

![VRRP Announcement](/post-images/vrrp-announce.png)

You can see that this announcement comes from 192.168.199.2, which is `server1`.
You can also see that it informs the whole network of its advertisement interval,
so other hosts can figure out when the host has failed.

Because we didn't configure Keepalived for unicast, it sends the announcement
to the default broadcast destination of 224.0.0.18. This is why the `virtual_router_id`
setting is so important, because there might be unrelated hosts on the same subnet
that are also doing VRRP. Finally, you can see the password (first 8 characters anyway).

Note that whether we use VRRP in multicast or unicast mode, we are not using
UDP/IP or TCP/IP. VRRP is its own protocol on top of IP that is independent of
either of those. The only thing that makes it multicast is the destination. Also note
that the Ethernet address is the IPv4 multicast address of `01:00:5e:00:00:12`. This
is important, because a Layer 2 switch needs to know to send this Ethernet packet
to all of the ports on the switch.

### Failover

Because the announcement is a periodic, there isn't much logic required for failover.
Once the current master has missed a few announcements, the other hosts start
announcing, and the highest priority wins. The resulting packet capture looks pretty
similar to above; the only difference is that a new host is announcing:

![VRRP Failover](/post-images/vrrp-failover.png)

Once the new master has been elected, it sends out a "gratuitous ARP". As we discussed
in the [previous article][1], every host has an ARP table that ties IP addresses to
Ethernet addresses. A gratuitous ARP is an unsolicited message with an IP address to
Ethernet address mapping. All hosts receiving the gratuitous ARP update their tables,
which effectively means that the virtual IP address is owned by a new device on the
network.

![Gratuitous ARP](/post-images/vrrp-grat-arp.png)

The ARP is sent a few times to make sure everybody catches it.

### Failback

Failback works the same way:

![VRRP Failback](/post-images/vrrp-failback.png)

There is one subtle difference in the above. You can see that the backup waits for
two announcements from the master before it gives the virtual IP back and stops
sending announcements. The master also waits an extra second before taking over.
This prevents the two hosts from getting into an argument about who owns the
virtual IP.

### Client side

The view that the client sees is a destination that is interrupted briefly, then
is available again:

![Lost Ping](/post-images/vrrp-lost-ping.png)

As you can see, for a few seconds after the simulated network failure, pings
go unanswered. It's only after the backup kicks in and sends its gratuitous ARP
that we start sending pings to the right Ethernet address and they are answered.

Of course, the new host is not going to have any state information that was
on the previous host unless we had another way to keep it up to date. So
for anything more complicated than a simple ICMP ping, we are probably going
to have to reestablish connections in order to survive the failover. I'll talk
about that in a future article where I discuss the kinds of network and server
architectures that go along with VRRP.

[osi]:https://en.wikipedia.org/wiki/OSI_model
[1]:https://dzone.com/articles/inside-vrrp-introduction
[2]:https://dzone.com/articles/vrrp-virtual-lab-with-ubuntu-xenial-and-vagrant
[3]:http://www.keepalived.org/

