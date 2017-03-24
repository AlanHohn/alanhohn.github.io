---
layout: post
title: "Alpine Linux Desktop"
description: ""
category: articles
tags: []
---

I recently resurrected an older but relatively small laptop to use
in cattle class on an airplane, where a full size laptop is eternally
in danger of being crushed by the seat in front. Unfortunately, the
laptop was running Windows Vista, a curse inflicted on many
laptops of its era, when Microsoft went through one of its phases of
pretending that people seek [deeper meaning][vista] from an operating
system as opposed to just hoping it will keep running and not break
their applications. (What's that, you say? They're doing it [right now][win10]
by pretending that the next generation of children will be transformed by the
tiny, incremental improvements they made to Windows? So surprising.)

[vista]:http://adage.com/article/digital/microsoft-pumps-500-million-vista-marketing-campaign/114589/
[win10]:http://www.theverge.com/2015/7/20/9002001/microsoft-windows-10-ads-babies-no-passwords

## Selection

Unfortunately, for this older specimen of a laptop, even newer versions of Ubuntu
are a bit sluggish. So, in keeping with the [teachings of our sect][sect]
that the latest thing is always better, I decided to try [Alpine Linux][alpine].
I justified it by saying to myself that I really only wanted to use it
for writing, that I write in Markdown using Vim, and so an operating system
that is as stripped down as possible is really what I'm looking for.

[sect]:http://www.joelonsoftware.com/articles/fog0000000069.html
[alpine]:http://www.alpinelinux.org/

Of course, lots of people are using Alpine Linux as the base for hypervisors
and Docker containers, because it makes a very small base in cases where the
entire typical stack of Linux utility programs is not needed (or can be replaced
by the basic implementation inside [Busybox][]. But I was interested to see what
it would be like to treat Alpine Linux like a regular Linux variant, do a proper
boot and disk install, and then try to use it.

[busybox]:https://www.busybox.net/

## Installation

The laptop in question lacks an optical drive and a physical Ethernet port, so
initial installation had to be a combination of a USB stick and wireless. I
expected this to be a sticking point but it was relatively easy to work through.
Building the USB installer was just a matter of using `dd` to write the image
to the device. Of course, there was the sudden surprise of failing to boot a
64-bit kernel on a 32-bit device, but that was just an enjoyable moment of
nostalgia. With a 32-bit kernel, the machine booted well, and the instructions
on the [wiki][] related to adding a wireless device worked the first time. I
was a little concerned that those instructions included installing packages,
but they were included on the live image and installed just fine. There also
was none of that dealing with not having the right device drivers for the
wireless device that was a staple of setting up Linux on a laptop five or six
years ago. Instead, it was just a matter of configuring `wpa_supplicant` with
the ESSID and password of my wireless network, and updating
`/etc/network/interfaces` telling it to use DHCP on `wlan0`.

[wiki]:https://wiki.alpinelinux.org/wiki/Connecting_to_a_wireless_access_point

With the wireless configured, I wanted to perform a regular disk installation
of Alpine, what Alpine calls a "sys" installation because it is using a
permanent disk for the system as opposed to just data or backup. Here I did run
into a minor problem. I had intentionally stopped short of copying the WPA setup
into /etc and enabling `wpa_supplicant` as a service, because I knew it wouldn't
persist after the reboot into the disk installation. But on running the installation
script `setup-alpine`, and verifying the `wlan0` configuration as part of the 
installation, I managed to get into a mode where the installation script
would not download and install packages even though it successfully got through
finding the fastest mirror. After a decent amount of time wasted playing with it,
I ended up rebooting the box, starting over with the wireless configuration, and
then enabling `wpa_supplicant` as a boot service using `openrc` before running the
installer. I was then able to skip over any network changes during the installer, and
while the installer still restarted `wpa_supplicant` on me, it came up correctly
again and the install was successful.

## First Usage

The default installation is reasonably functional for console use. Even `vi` is
present, though it is provided by Busybox and therefore doesn't contain all the
glorious features to which I'm accustomed. I did have to immediately go back through
setting up the wireless, as expected, but fortunately the changes are permanent.

The most interesting part of getting started was to decide what to install. The
notion of performing installations of bash, grep, awk, sed, and other common
tools seems a little strange, since we just automatically expect them to be
present in non-Busybox form. The best part about the whole experience is that
it feels like using Linux from five (or twenty) years ago, but with completely
new and modern versions of things. It reminds me of my first Slackware install
back in the mid-90s, but instead of feeding floppies I'm installing Git 2.6
from a fast Internet connection over a wireless network.

I spent far more time than I should selecting a console font. For a small laptop,
the screen is relatively high resolution, which means console mode is unusable with
the default font size. (The initial joy in seeing Alpine figure out the resolution
of the display automatically was lost when dealing with letters a tenth of an inch
tall.) It's been long enough since I used `setfont` for the console that figuring
it out and installing and finding font files was a slow process. I started out using
the sun12x22 font, but after hours of use, even that font involved too much hunching
for someone of my age and myopia.

In happens that Alpine does have a package for the Terminus font, which is a great
font for both console and X11. It's in the "testing" repo, but for a laptop
environment like this there's no reason not to be on the bleeding edge. To enable
the testing repository involves uncommenting the relevant line in
`/etc/apk/repositories`, then running `apk update`. The Terminus font can then be
installed with `apk add terminus-font`. Lots of files get installed; the ones we
care about are in `/usr/share/consolefonts` and are the 16x32 fonts. I ended up
adding this line to `$HOME/.bash_login`.

```
setfont /usr/share/consolefonts/ter-132n.psf.gz
```

## Real Usage

I've been delighted with this little companion so far. Battery life on such an old
laptop is not great, but I have to imagine it would be even worse if I was trying
to use a full operating system or graphical user environment. For the same reason, I
did an initial X11 install but wound up not even trying to configure it to work as
just running `startx` was worth a couple percentage on the battery life.

Of course, this raises the question: how does one find out the battery life
with no cute little icons at the top of the screen? The answer was on
ServerFault and ended up being:

```
#!/bin/bash
upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E 'state|to\ full|percentage'
```

On travel, of course I had to add a second wireless network, and this was
considerably less well documented. I ended up finding what I needed on a forum
linking to some Gentoo documentation, which tends to be a sign that you're
trying to do something that very few people are doing. It is worth mentioning,
though, that the advice ended up being "just try this and it will find the new
network automatically" and that was accurate. There is a real advantage to
running the latest versions of things, even on a system that looks like 1995.

For what it's worth, my wpa_supplicant.conf ended up looking like this. Note that
the password hash is generated by `wpa_passphrase` and hashes in the ESSID, so
`wpa_passphrase` must be used with each network even if passwords are the same.

```
network={
	ssid="wireless1"
	#psk="my wireless password"
	psk=[long hash string generated by wpa_passphrase"
	id_str="wireless1"
	priority=100
}
network={
	ssid="wireless2"
	#psk="my wireless password"
	psk=[long hash string generated by wpa_passphrase"
	id_str="wireless2"
	priority=99
}
```

## Wrapping Up

I can't imagine this being the sole computer I carry.  While you can add
wireless networks, hotel and airport networks that expect you to use a browser
to log in are not satisfied with `links`. (At least Hilton wasn't.) And
smartphone browsing gets old. But it's enormously enjoyable to be sitting in an
airplane seat with a computer that leaves some space for a beverage or a snack
on the tiny little tray.  At least for now, it's enjoyable enough that I'm
willing to pay the relatively small weight penalty. So it'll be coming with
me next time too.

