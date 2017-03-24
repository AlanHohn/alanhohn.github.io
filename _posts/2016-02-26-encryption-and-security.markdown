---
layout: post
title: "iPhone and DVD: Encryption versus Security"
description: ""
category: articles
tags: []
---

The Internet has been transfixed by the story of [San Berdardino][b],
[Cupertino][a], and [Quantico][q] in the FBI's attempt to access data from a
terrorist's smart phone. I won't take a position, other than to point out that this is
why the lawyers say, ["Hard Cases Make Bad Law"][h].  Instead, I'm
interested in the discussion about what the idea of back doors to access an
encrypted device really tells us about security.

[b]:https://en.wikipedia.org/wiki/2015_San_Bernardino_attack
[a]:http://www.apple.com/
[q]:https://www.fbi.gov/
[h]:https://en.wikipedia.org/wiki/Hard_cases_make_bad_law

## Links in a Chain

Security is famously described as a weakest link problem. Many successful
intrusions are accomplished because human beings hand over the information
that's needed, not because of any technical flaw in the system or any issue
with an encryption algorithm. In his [book][bk], Kevin Mitnick
describes his use of social engineering to get the next piece of information
or the next bit of access from someone. Often, no one decision seems terrible,
but put together they end up handing away the master key for the whole business.
For this reason, the U.S. military emphasizes what they call [Operations
Security (OPSEC)][os], which is the idea of protecting even innocuous, unclassified
information because in quantity it can be used to learn secret information.

[bk]:https://en.wikipedia.org/wiki/The_Art_of_Deception
[os]:http://www.dodea.edu/offices/safety/opsec.cfm

So what is the weakest link in this case? It's interesting to note specifically
what the FBI is looking for. They want to be able to try to enter a PIN into
the phone without being slowed down, and without risking the data being wiped.
Note that this has nothing whatsoever to do with encryption. In theory, Apple
could be using [NSA Suite B encryption][sb], approved for information up to
Top Secret, or they could be using AES-256 like they are today, or they could
be using ROT-13 "encryption", and it wouldn't matter if the only way to get at
the data was to enter a correct PIN. The FBI would still be asking for the
same thing.

[sb]:https://www.nsa.gov/ia/programs/suiteb_cryptography/

## Data at Rest and in Motion

So what good is the encryption?  Apple has a [security guide][gd] for iOS that
describes the encryption of every file in flash memory, including the use of a 
separate "per-file" key to make recovery of the keys more difficult.
In the defense business, we call this overall concept "data at rest" encryption, and it's
important, because we assume that an attacker can get physical access to the media,
while the device is off, that would allow them to read the individual bits. It
has to be impossible to reconstruct the data using the bits that are written to
persistent storage, or none of the protections the software includes while the
device is running (broadly, called "data in motion") do any good at all.

[gd]:https://www.apple.com/business/docs/iOS_Security_Guide.pdf

But here we run into the biggest problem in this type of encryption, which is that
we also have to put into the *same* device the *key* that is used to decrypt the
information! Otherwise it would be encrypt-only, which is secure but not terribly
useful. This ended up being the issue that made DVD encryption a joke; it is
possible to encrypt the data on the DVDs, but in order to let people actually watch
the movie, it is necessary to put a decryption key into the hands of literally
everyone who wants one (otherwise it would be hard to sell DVDs). Once those
encryption keys are in the hands of the users, only obsfucation protects them
being used to create an unprotected copy as opposed to just watching the movie.
And obsfucation doesn't last very long.

In the case of the iPhone, for convenience, there needs to be a master key to
decrypt all the other keys. And people can't be expected to carry a separate
secure device with their master encryption key on it. And even if people *had* a
separate secure device with the key, they wouldn't want to enter a long pass
phrase every time they check their email. So access to the encryption key on
that kind of device is always going to be a relatively short PIN, or unlock
pattern, or something similar.  There can't be too many combinations with a
short PIN or pattern. Even something seemingly complicated, like drawing with
your finger on a picture, has to be forgiving, or you get too many false
rejections and people get annoyed. (For example, the padlocks used on
classified spaces are notoriously sensitive, so that it can be very hard to get
the "knack" for opening them. The average consumer would never tolerate this
for a device that must be unlocked numerous times in a day.) So immediately, no
matter how good the "data at rest" encryption is, the weak link becomes the
PIN.

## Secure the Whole Stack

It's also interesting to notice that the court documents specify the intended mode
of attack. Right now, the phone is (possibly) configured to wipe the data after a number
of incorrect entries. To circumvent this, it is necessary to modify the behavior of
that software. According to the court documents, this can be done by uploading a new
version of the software over a physical link. Obviously, this can be done to the phone
without it first being unlocked; otherwise, what would be the point? So this becomes
another weak link. If the phone can be made to accept a software upgrade that changes
its security behavior, potentially anything can be done to it, including telling it to
scan the potential range of PINs by itself until it finds the one that unlocks the keys.
(The FBI probably didn't ask for this because they wanted to convince the court that
they were asking for something "easy".)

This reminds me of the [bad old days][sr] of "original disc checks". In order
to protect commercial software from unwanted copying, generally the trick was
to have some flaw on the original disc that could not be easily duplicated onto
a copy. Embedded security software would check for a disc with that flaw and
refuse to run if not found. Of course, in this case also, the security software
had to be put into the hands of anyone who wanted a copy. So it did not take
long for someone to figure out where the security software was embedded into
the executable and to either make sure it claimed success or to bypass it entirely.
By the time people got the hang of this, it took less than a day.

[sr]:https://en.wikipedia.org/wiki/SecuROM

Of course, in the case of the iPhone the situation is a little more complicated, because
Apple signs their iOS updates with a private key that they hold (and which I'm sure is
protected with more than a 4-digit PIN). The phone won't install and run updates that
aren't signed by Apple. This is what leads to the desire for a court order compelling
Apple to make a new, intentionally broken version of their software: not Apple's disk
encryption per se, or the feature that wipes the phone if too many incorrect PINs are
tried, but their binary code signing and presumably some hardware features that make it
difficult to run modified or unsigned code.

## Reasoning About Security

So what lesson can we take from this? The first is the old lesson that your
data, no matter how well encrypted, is only as secure as the key you use to
encrypt it, which means the physical device the key is on, as well as the PIN
or password you use to protect that key. (I didn't talk about biometrics,
because it doesn't seem to have entered this case, but just in passing I'll
point out that courts have ruled that you can be compelled to provide your
fingerprint to unlock your phone, and anyway the FBI has the slimeball
murderer's finger.) 

The second lesson is that, in a lot of cases, it doesn't require strong math skills
and a deep knowledge of encryption algorithms to think about security (though of course
they don't hurt). What is most useful is the ability to mentally open the black boxes
that comprise how computing devices process data, and just to reason about what needs to
be done to the data to secure it and what needs to be done to make it available for use.
Once you've reasoned through it, it seems obvious that no matter how encrypted, any data
you can see by typing in a four-digit number can't be considered super-secret.

