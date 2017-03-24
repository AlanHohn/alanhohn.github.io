---
layout: post
title: "Inside VRRP: Introduction"
description: ""
category: articles
tags: []
---

The Virtual Router Redundancy Protocol (VRRP) is a useful approach to provide
failover at the network level on a subnet. I thought it might be interesting
to see the details at the individual packet and frame level, so I put
together a set of virtual machines for the purpose. On the way there were
some other interesting challenges, so I'll spend a little time writing about
those as well.

To start, I'd like to introduce the technologies to show their purpose. In
particular, in addition to VRRP itself, the Address Resolution Protocol (ARP)
is critically important on an Ethernet network in order to make VRRP work,
so I'll introduce that too.

### VRRP Architecture

VRRP is a protocol designed to provide high availability and redundancy at
the level of a network address. The idea is that multiple hosts all communicate
with each other to determine which has the highest priority. This highest
priority host then adds a virtual IP address. The process of communication
(via announcements) continues. If the highest priority host stops announcing,
another host will become the highest priority host (just by virtue of being
the highest priority host to announce within a period of time). It will then
take over the virtual IP.

From the perspective of the client, this is handled seamlessly. The client uses
the same protocols it's used to (Domain Name Service, TCP/IP or UDP/IP, ARP).
There is a little work that's done automatically when a failover happens, but
most of the network stack is unaffected.

### Network Stack

For the rest of this discussion to make sense, it helps to have a picture of
the [OSI model][osi] handy. In particular, we're going to be working at Layer
2 (Data Link) and Layer 3 (Network). The whole idea of VRRP is that Layer 3
stays exactly the same (one IP address continues to work) while the traffic
is going to a different host at Layer 2 (different Ethernet address).

The first thing to note is that there are different kinds of addresses at
Layers 2 and 3. When using Ethernet for Layer 2, the address is a Media Access
Control (MAC) address. A MAC address identifies a piece of network hardware (or
some pretend network hardware in a virtual machine). For example, one of my
server virtual machines has the address `08:00:27:19:5d:24`. 

When using Internet Protocol (IP) for Layer 3, addresses might be IP version 4
(IPv4) or IP version 6 (IPv6). In this case, we'll be working with a "virtual"
IP address of `192.168.199.10`. This address is going to move around between
servers, but their MAC addresses will stay the same.

Note that even though these two styles of address look very different, they
are both just a series of bytes. The way we write them is just a convention.
We could say that `C0:A8:C7:0A` is the virtual IP address rather than
`192.168.199.10`; they mean the same thing. (192 in decimal is C0 in hexadecimal.)
It's useful to understand this, because when we look at the actual data that
goes across the network, we'll see it in either form.

The other thing worth mentioning is that while IPv4 uses only four bytes for
an address, a MAC address is six bytes. This means that there are 2^32 possible
IPv4 addresses (about 4 billion) and 2^48 possible MAC addresses (about 281
trillion). This may seem a little odd, since Ethernet networks tend to max out
at a couple hundred hosts, while IPv4 is used for the whole Internet. But the
reason is that it makes it much easier for hardware manufacturers to build
in the MAC address for each device they make; the whole space of MAC addresses
is divided up amongst hardware manufacturers, so each manufacturer can use
addresses from their own space. 

(For what it's worth, my virtual server with its address of `08:00:27:19:5d:24` 
is using an address from "Cadmus Computer Systems", which seems like a strange
thing for an Oracle (formerly Sun Microsystems, formerly innotek) VirtualBox
VM. Therein lies [a tale][cadmus].)

### Network Layers

To make this discussion of network layers clear, let's talk a little bit about
what happens when we send data on an Ethernet network. We are going to look
closely at a ping. The `ping` command uses the Internet Control Message
Protocol (ICMP) to send a quick message to another host on the Internet and get
a reply. From the perspective of the OSI model, here's how it works:

* The `ping` command builds a ping request. This is a collection of bytes.
  To keep things simple, we can ignore the differences between Layers 4
  to 7 of the OSI model; the key is that when those layers are done, we
  have a series of bytes that need to travel from a source IP address to
  a destination IP address.
* The ping command hands this collection of bytes to the underlying IP
  handler in the network stack, with the source and destination address
  and the protocol (ICMP).  The IP handler builds an IP packet, which is a
  header (that includes protocol, source and destination) and a body with the
  data.  
* The IP stack looks at the destination address. If it's a local address
  (i.e. on the same network as the source) it will send the packet directly
  to the destination. Otherwise it will send it to another host that will
  "route" the packet.

This last step is important, because it's how hosts all over the Internet
are able to communicate, even though they aren't directly connected together.
But this topic is way too large to handle here.

To get back to our steps:

* The IP stack then consults a table (called the ARP cache) to figure out
  the MAC address of the destination (either the real destination or the
  router).
* The IP stack hands the data to the data link layer with the destination
  MAC address. The data link layer then builds an Ethernet "frame", which
  is another header, then the IP packet as the body (including its own
  header and body).
* The bytes are then sent over the wire.

Here's an example of this, from a network capture. In a future article I
will go through the capture process in detail. The capture is displayed
in [Wireshark][].

![ICMP Example](/post-images/vrrp-ping.png)

At the bottom you can see Wireshark's analysis of this particular packet,
including the Ethernet frame, the IP packet, and the ICMP (ping) data.

### ARP

For this article, the big unanswered question is, where does the table
come from that relates IP addresses to MAC addresses? There has to be a
program to build that table, since we can plug any computer from any
manufacturer into a network and it can communicate, no matter what IP
address it got.

This table is built using Address Resolution Protocol (ARP). ARP is a
pretty simple protocol. It's one of those things that can mostly be
ignored as it "just works", but without which a network couldn't function.
It also is one of the things that bounces around a network even when computers
are "idle", causing network activity lights to light up cheerily.

When a computer first joins a network, its ARP cache is empty. It builds the
ARP cache by receiving ARP messages from other computers on the network. These
messages are all broadcast at the Ethernet level (which means their destination
is `ff:ff:ff:ff:ff:ff`).

If a computer has been on the network for a while, it will have a pretty full
ARP cache, and so it will know the MAC address for every IP address out there.
But if it needs to send a packet to an IP address, and it doesn't have the
corresponding MAC address yet, it sends an ARP request. This is also a broadcast
Ethernet message. All hosts listen for this request, and if they have that IP
address, they reply with a regular ARP broadcast. That way every host on the
network gets the ARP information, which cuts down on the total ARP traffic that
needs to fly around.

Similarly, when a host gets a direct message from another host, the source IP
address and the source MAC address are both in the message. So the destination
host gets an entry in its ARP cache "for free" without having to request it.
(This behavior is not specifically required by the RFC but it happens; I'll
show an example of it in a future article.)

### IP Address Collisions

This whole structure relies on one and only one host on an Ethernet network being
configured with a particular IP address. If multiple hosts are configured with
the same IP, they will both respond to ARP requests. Generally, the latest one
will "win" and will get the traffic for that IP address (which it may not be
expecting). Also, depending on when devices join the network, they may have one
or the other host in their ARP cache, so some hosts may talk to one and some to
the other. This is a source of much confusion and frustration.

Modern operating systems manage to avoid this. When you set a static IP address
in a modern operating system, the OS sends an ARP request for that IP. If any
other host replies, it recognizes that as a collision and rejects the IP address
configuration. This greatly cuts down on collisions compared to older operating
systems, but it can be a source of confusion when a seemingly valid address won't
work.

### Wrapping Up

Next time we'll shift gears and I'll walk through a virtual machine configuration
that will enable us to do some testing and packet capture from servers using VRRP.

[osi]:https://en.wikipedia.org/wiki/OSI_model
[cadmus]:http://comments.gmane.org/gmane.comp.emulators.virtualbox.devel/2199
[wireshark]:https://www.wireshark.org/

