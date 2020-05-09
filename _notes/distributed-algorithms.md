---
title: CS-451 Distributed Algorithms
description: "My notes from the CS-451 Distributed Algorithms course given at EPFL, in the 2018 autumn semester (MA1)"
date: 2018-09-18
course: CS-451
---

- [Course website](http://dcl.epfl.ch/site/education/da)
- The course follows the book [*Introduction to Reliable (and Secure) Distributed Programming*](https://www.springer.com/gp/book/9783642152597) (available from the library or through SpringerLink)
- Final exam is 60%
- Projects in teams of 2-3 are 40%. The project is the implementation of various broadcast algorithms
- No midterm

<!-- More -->

* TOC
{:toc}

*[ATTA]: According To The Algorithm
*[FLL]: Fair Loss Link
*[BEB]: Best Effort Broadcast
*[SL]: Stubborn Link
*[PL]: Perfect Link
*[RB]: Reliable Broadcast
*[CB]: Causal Broadcast
*[CO]: Causal Order
*[VC]: Vector Clock
*[TOB]: Total Order Broadcast
*[FIFO]: First In First Out
*[SM]: Shared Memory
*[ACK]: Acknowledgment
*[NACK]: Negative Acknowledgment
*[NBAC]: Non-Blocking Atomic Commit
*[2PC]: Two-Phase Commit
*[URB]: Uniform Reliable Broadcast
*[TRB]: Terminating Reliable Broadcast
*[GM]: Group Membership
*[VS]: View-Synchronous broadcast

## Introduction
In terms of abstraction layers, distributed algorithms are sandwiched between the application layer (processes) the network layer (channels). We have a few commonly used abstractions in this course:

- **Processes** abstract computers
- **Channels** (or communication *links*) abstract networks
- **Failure detectors** abstract time

We consider that a distributed system is composed of $N$ processes making up a static set $\Pi$ (i.e. it doesn't change over time). These processes communicate by sending messages over the network channel. The distributed algorithm consists of a set of distributed automata, one for each process. All processes implement the same automaton.

When defining a problem, there are two important properties that we care about:

- **Safety** states that nothing bad should happen
- **Liveness** states that something good should happen eventually

Safety is trivially implemented by doing nothing, so we also need liveness to make sure that the correct things actually happen.

### Links
Two nodes can communicate through a link by passing messages. However, this message passing can be faulty: it can drop messages or repeat them. How can we ensure correct and reliable message passing under such conditions?

A link has two basic types of events:

- **Send**: we place a message on the link
- **Deliver**: the link gives us a message

#### Fair loss link (FLL)
A fair loss link is a link that may lose or repeat some packets. This is the weakest type of link we can assume. In practice, it corresponds to UDP.  

Deliver can be thought of as a reception event on the receiver end. The terminology used here ("deliver") implies that the link delivers to the client, but this can equally be thought of as the client receiving from the link.

For a link to be considered a fair-loss link, we must respect the following three properties:

- **FLL1. Fair loss**: If a correct process $p$ infinitely often sends a message $m$ to a correct process $q$, then $q$ delivers $m$ an infinite number of times.
- **FLL2. Finite duplication**: If a correct process $p$ sends a message $m$ a finite number of times to process $q$, then $m$ cannot be delivered an infinite number of times by $q$.
- **FLL3. No creation**: If some process $q$ delivers a message $m$ with sender $p$, then $m$ was previously sent to $q$ by process $p$.

Let's try to get some intuition for what these properties mean:

- FLL1 does not guarantee that all messages get through, but at least ensures that some messages get through. 
- FLL2 means that message can only be repeated by the link a finite number of times.
- FLL3 means that every delivery must be the result of a send; no message must be created out of the blue.

There's no real algorithm to implement here; we have only placed assumptions on the link itself. Still, let's take a look at the interface.

{% highlight dapseudo linenos %}
Module:
    Name: FairLossLinks (flp2p)

Events:
    Request: <flp2pSend, dest, m>: requests to send message m to process dest
    Indication: <flp2pDeliver, src, m>: delivers messages m sent by src

Properties:
    FLL1, FLL2, FLL3
{% endhighlight %}

#### Stubborn link (SL)
A stubborn link is one that stubbornly delivers messages; that is, it ensures that the message is received. Here, we'll disregard performance, and just keep sending the message.

The properties that we look for in a stubborn link are:

- **SL1. Stubborn delivery**: If a correct process $p$ sends a message $m$ once to a correct process $q$, then $q$ delivers $m$ an infinite number of times.
- **SL2. No creation**: If some process $q$ delivers a message $m$ with sender $p$, then $m$ was previously sent to $q$ by $p$.

A stubborn link can be implemented with a FLL as the following algorithm, which we could call "retransmit forever". We could probably make it more efficient with the use of timeouts, but since we're mainly concerned with correctness for now, we'll just keep it simple.

{% highlight python linenos %}
def send(m):
    """ 
    Keep sending the same message
    over and over again on the FLL 
    """
    while True:
        FLL.send(m)

# When the underlying FLL delivers, deliver to the layer above
FLL.on_delivery(lambda m: deliver(m))
{% endhighlight %}

The above is written in Python, but the syntax we'll use in this course is as follows:

{% highlight dapseudo linenos %}
Implements: 
    StubbornLinks (sp2p)
Uses:
    FairLossLinks (flp2p)
Events:
    Request: <sp2pSend, dest, m>: requests to send message m to dest
    Indication: <sp2pDeliver, src, m>: delivers message m sent by src
Properties:
    SL1, SL2

upon event <sp2pSend, dest, m> do:
    while (true) do:
        trigger <flp2p, dest, m>;

upon event <flp2pDeliver, src, m> do:
    trigger <sp2pDeliver, src, m>;
{% endhighlight %}

Note that this piece of code is meant to sit between two abstraction levels; it is between the channel and the application. As such, it receives sends from the application and forwards them to the link, and receives delivers from the link and forwards them to the application. It must respect the interface of the underlying FLL, and as such, only specifies send and receive hooks.

Note that a stubborn link will deliver the same message infinitely many times, according to SL1. Wanting to only deliver once will lead us to perfect links.

#### Perfect link (PL)
Here again, we respect the send/deliver interface. The properties are:

- **PL1. Reliable delivery**: If a correct process $p$ sends a message $m$ to a correct process $q$, then $q$ eventually delivers $m$
- **PL2. No duplication**: No message is delivered by a process more than once
- **PL3. No creation**: If some process $q$ delivers a message $m$ with sender $p$, then $m$ was previously sent to $q$ by $p$.

This is the type of link that we usually use: TCP is a perfect link, although it also has more guarantees (notably on message ordering, which this definition of a perfect link does not have). TCP keeps retransmitting a message stubbornly, until it gets an acknowledgment, which means that it can stop transmitting. Acknowledgments aren't actually needed *in theory*, it would still work without them, but we would also completely flood the network, so acknowledgments are a practical consideration for performance; just note that the theorists don't care about them.

Compared to the stubborn link, the perfect link algorithm could be called "eliminate duplicates". In addition to what the stubborn links do, it keeps track of messages that 

{% highlight dapseudo linenos %}
Implements: 
    PerfectLinks (pp2p)
Uses:
    StubbornLinks (sp2p)
Events:
    Request: <pp2pSend, dest, m>: requests to send message m to process q
    Indication: <pp2pDeliver, src, m>: delivers message m sent by src
Properties:
    PL1, PL2, PL3

upon event <pp2p, Init> do:
    delivered := ∅;

upon event <pp2pSend, dest, m> do:
    trigger <sp2pSend, dest, m>;

upon event <sp2pDeliver, src, m> do:
    if m ∉ delivered:
        delivered := delivered ∪ {m};
        trigger <pp2pDeliver, src, m>;
{% endhighlight %}

Throughout the course, we'll use perfect links as the underlying link (unless otherwise specified).

### Impossibility of consensus
Suppose we'd like to compute prime numbers on a distributed system. Let *P* be the producer of prime numbers. Whenever it finds one, it notifies two servers, *S1* and *S2* about it. A client *C* may request the full list of known prime numbers from either server.

As in any distributed system, we want the servers to behave as a single (abstract) machine.

#### Solvable atomicity problem
*P* finds 1013 as a new prime number, and sends it to *S1*, which receives it immediately, and *S2*, which receives it after a long delay. In the meantime, before both servers have received the update, we have an atomicity problem: one server has a different list from the other. In this time window, *C* will get different results from *S1* (which has numbers up to 1013) and *S2* (which only has numbers up to 1009, which is the previous prime). 

A simple way to solve this is to have *C* send the new number (1013) to the other servers; if it requested from *S1* it'll send the update to *S2* as a kind of write back, to make sure that *S2* also has it for the next request. We haven't strictly defined the problem or its requirements, but this may need to assume a link that guarantees delivery and order (i.e. TCP, not UDP).

#### Unsolvable atomicity problem
Now assume that we have two prime number producers *P1* and *P2*. This introduces a new atomicity problem: the updates may not reach all servers atomically in order, and the servers cannot agree on the order. 

This is **impossible** to solve; we won't prove it, but universality of Turing is lost (unless we make very strong assumptions). This is known as the [*impossibility of consensus*](https://groups.csail.mit.edu/tds/papers/Lynch/jacm85.pdf).

### Timing assumptions
An important element for describing distributed algorithms is how the system behaves with respect to the passage of time. Often, we need to be able to make assumptions about time bounds.

Measuring time in absolute terms with a physical clock (measuring seconds, minutes and hours) is a bit of a dead end for discussing algorithms. Instead, we'll use the concept of *logical time*, which is defined with respect to communications. This clock is just an abstraction we use to reason about algorithms; it isn't accessible to the processes or algorithms.

The three time-related models are:

- **Synchronous**: assuming a synchronous system comes down to assuming the following properties:
    + **Synchronous computation**: receiving a message can imply a local computation, and this computation can result in sending back a message. This assumption simply states that all the time it takes to do this is bounded and known.
    + **Synchronous communication**: there is a known upper bound limit on message transmission delays; the time between sending and delivering a message on the other end of the link is smaller that the bound
    + **Synchronous clocks**: the drift between a local clock and the global, real-time clock is bounded and known
- **Eventually synchronous**: the above assumptions hold eventually
- **Asynchronous**: no assumptions

We can easily see how a distributed system would be synchronous: placing bounds on computation and message transmission delays should be possible most of the time. But network overload and message loss may lead the system to become partially synchronous, which is why we have the concept of eventually synchronous.

To abstract these timing assumptions, we will introduce failure detectors in the following section.

### Failure detection
A **failure detector** is a distributed oracle that provides processes with suspicions about crashed processes. There are two kinds of failure detectors, with the following properties

- **Perfect failure detector** $\mathcal{P}$
    + **PFD1. Strong completeness**: eventually, every process that crashes is permanently suspected by every correct process
    + **PFD2. Strong accuracy**: if a process $p$ is detected by any process, then $p$ has crashed
- **Eventually perfect failure detector** $\diamond\mathcal{P}$
    + **EPFD1. Strong completeness = PFD1**
    + **EPFD2. Eventual strong accuracy**: eventually, no correct process is ever suspected by any correct process

A perfect failure detector tells us when a process $p$ has crashed by emitting a `<Crash, p>` event. It never makes mistakes, never changes its mind; decisions are permanent and accurate.

An eventually perfect detector may make mistakes, falsely suspecting a correct process to be crashed. If it does so, it will eventually change its mind and tell us the truth. When it suspects a process $p$, it emits a `<Suspect, p>` event; if it changes its mind, it emits a `<Restore, p>` event. In aggregate, eventually perfect failure detectors are accurate.

A failure detector can be implemented by the following algorithm:

1. Processes periodically send heartbeat messages
2. A process sets a timeout based on worst case round trip of a message exchange
3. A process suspects another process has failed if it timeouts that process
4. A process that delivers a message from a suspected process revises its suspicion and doubles the time-out

## Reliable broadcast
Broadcast is useful for applications with pubsub-like mechanisms, where some processes subscribe to events published by others (e.g. stock prices). 

The subscribers might need some reliability guarantees from the publisher (these guarantees are called "quality of service", or QoS). These quality guarantees are typically not offered by the underlying network, so we'll see different broadcasting algorithms with different guarantees.

A broadcast operation is an operation in which a process sends a message to all processes in a system, including itself. We consider broadcasting to be a single operation, but it of course may take time to send all the messages over the network.

### Best-effort broadcast (BEB)
In best-effort broadcast (BEB), the sender is the one ensuring the reliability; the receivers do not have to be concerned with enforcing the reliability. On the other hand, if the sender fails, all guarantees go out the window.

#### Properties
The guarantees of BEB are as follows:

- **BEB1. Validity**: if $p$ and $q$ are correct, then every message broadcast by $p$ is eventually delivered by $q$
- **BEB2. No duplication**: no message is delivered more than once
- **BEB3. No creation**: if a process delivers a message $m$ with sender $p$, then $m$ was previously broadcast by $p$

BEB1 is a liveness property, while no BEB2 and BEB3 are safety properties.

As we said above, the broadcasting machine may still crash in the middle of a broadcast, where it hasn't broadcast the message to everyone yet, and it's important to note that BEB offers no guarantee against that.

#### Algorithm
The algorithm for BEB is fairly straightforward: it just sends the message to all processes in the network using perfect links (remember that perfect links use stubborn links, sending the same message continuously). Perfect links already guarantees no duplication (PL2), so we can just forward delivered messages to the application layer above BEB. 

{% highlight dapseudo linenos %}
Implements: 
    BestEffortBroadcast (beb)
Uses: 
    PerfectLinks (pp2p)
Events:
    Request: <bebBroadcast, m>: broadcasts a message m to all processes
    Indication: <bebDeliver, src, m>: delivers a message m sent by src

upon event <bebBroadcast, m> do:
    forall q ∈ Π do:
        trigger <pp2pSend, q, m>;

upon event <pp2pDeliver, src, m> do:
    trigger <bebDeliver, src, m>;
{% endhighlight %}

#### Correctness
This is not the most efficient algorithm, but we're not concerned about that. We just care about whether it's correct, which we'll sketch out a proof for:

- **Validity**: By PL1 (the validity property of perfect links), and the very facts that:
    + the sender `pp2Send`s the message to all processes in $\Pi$
    + every correct process that `pp2pDeliver`s a message `bebDeliver`s it too
- **No duplication**: by PL2 (the no duplication property of perfect links)
- **No creation**: by PL3 (the no creation property of perfect links)

### Reliable broadcast (RB)
As we said above, BEB offers no guarantees if the sender crashes while sending. If it does fail while sending, we may end up in a situation where some processes deliver the messages, and others don't. In other words, not all processes *agree* on the delivery.

As it turns out, it's even more subtle than that: the sender may already have done a `bebSend` and `pp2pSend`, and so on, placed all messages on the wire, and then crash. Because the underlying perfect link do not guarantee delivery when the sender crashes, we have no guarantee that the messages have been delivered.

#### Properties
To address this, we want an additional property compared to BEB, *agreement*:

- **RB1. Validity = BEB1**
- **RB2. No duplication = BEB2**
- **RB3. No creation = BEB3**
- **RB4. Agreement**: for any message $m$, if a **correct** process delivers $m$, then every correct process delivers $m$

RB4 tells us that even if the broadcaster crashes in the middle of a broadcast and is unable to send to other processes, we'll honor the agreement property. This is done by distinguishing receiving and delivering; the broadcaster may not have sent to everyone, but in that case, reliable broadcast makes sure that no one delivers.

#### Algorithm
For the first time, we'll use a perfect failure detector $\mathcal{P}$ in our implementation of RB. Since we're aiming to do the same as BEB but with the added agreement property, we'll use BEB as the underlying link. 

{% highlight dapseudo linenos %}
Implements:
    ReliableBroadcast (rb)
Uses:
    BestEfforBroadcast (beb)
    PerfectFailureDetector (P)
Events:
    Request: <rbBroadcast, m>: broadcasts a message m to all processes
    Indication: <rbDeliver, src, m>: delivers a message m sent by src
Properties:
    RB1, RB2, RB3, RB4

upon event <rb, Init> do:
    delivered := ∅;
    correct := Π;
    from := [];
    forall p ∈ Π do:
        from[p] := ∅;

upon event <rbBroadcast, m> do:
    delivered := delivered ∪ {m};
    trigger <rbDeliver, self, m>; # deliver to self
    trigger <bebBroadcast, [Data, self, m]>; # broadcast to others using beb

# Here, it's important to distinguish the sender (at the other 
# side of the link) from the src (original broadcaster):
upon event <bebDeliver, sender, [Data, src, m]> do:
    if m ∉ delivered:
        # deliver m from src:
        delivered := delivered ∪ {m};
        trigger <rbDeliver, src, m>;
        # echo to others if src no longer correct:
        if src ∉ correct:
            trigger <bebBroadcast, [Data, src, m]>;
        else:
            from[sender] := from[sender] ∪ {[src, m]};

upon event <crash, p> do:
    correct := correct \ {p};
    # echo all previous messages from crashed p:
    forall [src, m] ∈ from[p] do:
        trigger <bebBroadcast, [Data, src, m]>
{% endhighlight %}

The idea is to echo all messages from a process that has crashed. From the moment we get the crash message from the perfect failure predictor $\mathcal{P}$, we forward all subsequent messages from the crashed sender to all nodes. But we  may also have received messages from the sender before knowing that it was crashed. To solve this, we keep track of all broadcasts, and rebroadcast all old messages when we find out the sender crashed.

#### Correctness
We'll sketch a proof for the properties:

- **Validity**: as for RB
- **No duplication**: as for RB
- **No creation**: as for RB
- **Agreement**: Assume some correct process $p$ `rbDelivers` a message $m$ that was `rbBroadcast` by some process $q$.
  + If $q$ is correct, then by BEB1 (BEB validity), all correct processes will `bebDeliver` $m$, and according to the algorithm (ATTA), deliver $m$ through `rbDeliver`. 
  + If $q$ crashes, then by PFD1 (strong completeness of $\mathcal{P}$), $p$ detects the crash and ATTA echoes $m$ with `bebBroadcast` to all. Since $p$ is correct, then by BEB1 (BEB validity), all correct processes `bebDeliver` and then, ATTA, `rbDeliver` $m$.

Note that the proof only uses the completeness property of the failure detector (PFD1), not the accuracy property (PFD2). Therefore, the predictor can either be perfect $\mathcal{P}$ or eventually perfect $\diamond\mathcal{P}$.

### Uniform reliable broadcast (URB)
In RB, we only required that *correct* processes should agree on the set of messages to deliver. We made no requirements on what messages we allow faulty processes to deliver.

For instance, a scenario possible under RB is that we want to `rbBroadcast` from a process $p$. It could `rbDeliver` it to itself, and then crash before it had time to `bebBroadcast` it to others (see lines 24 and 25 of the RB algorithm). In this scenario, all *correct* nodes still agree not to deliver the message (after all, none of them have received it), but $p$ has already delivered it.

#### Properties
Uniform reliable broadcast solves this problem, by ensuring that *all* processes agree. Its properties are:

- **URB1. Validity = BEB1**
- **URB2. No duplication = BEB2**
- **URB3. No creation = BEB3**
- **URB4. Uniform agreement**: for any message $m$, if a process delivers $m$, then every correct process delivers $m$

We've removed the word "correct" in agreement, and this changes things quite a bit. Uniform agreement is a stronger assertion, which ensures that the set of messages delivered by faulty processes is a *subset* of those delivered by correct processes.

#### Algorithm
The algorithm is given by:

{% highlight dapseudo linenos %}
Implements: 
    uniformBroadcast (urb)
Uses:
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
Events:
    Request: <rbBroadcast, m>: broadcasts a message m to all processes
    Indication: <rbDeliver, src, m>: delivers a message m sent by src
Properties:
    URB1, URB2, URB3, URB4

upon event <urb, Init> do:
    correct := Π;
    delivered := ∅;
    pending := ∅; # set of [src, msg] that we have sent (broadcast or echoed)
    ack[Message] := ∅; # set of nodes that have acknowledged Message

upon event <crash, p> do:
    correct := correct \ {p};

# before broadcasting, save message in pending
upon event <urbBroadcast, m> do:
    pending := pending ∪ {[self, m]};
    trigger <bebBroadcast, [Data, self, m]>;

# If I haven't sent the message, echo it
# If I've already sent it, don't do it again
upon event <bebDeliver, sender, [Data, src, m]> do:
    ack[m] := ack[m] ∪ {sender};
    if [src, m] ∉ pending:
        pending := pending ∪ {[src, m]};
        trigger <bebBroadcast, [Data, src, m]>;

# Deliver the message when we know that all correct processes
# have delivered (and if we haven't delivered already)
upon event (exists [src, m] ∈ pending) 
  such that (can_deliver(m) and m ∉ delivered) do:
    delivered := delivered ∪ {m};
    trigger <urbDeliver, src, m>;

# We can deliver if all correct nodes have acknowledged m:
def can_deliver(m):
    return correct ⊆ ack[m];
{% endhighlight %}

When a process sees a message (that is, `bebDeliver`s it), it relays it once; this relay serves as an acknowledgment, but also as a way to forward the message to other nodes. All processes keep track of who they have received messages from (either acks or the original message). Once all correct nodes have sent it the message (again, either an ack or the original), it can `urbDeliver`.

Because all nodes all echo the message to each other once, the number of messages sent is $N^2$.

Because the algorithm waits for confirmation from all correct nodes, it only `urbDeliver`s messages that it knows that all correct nodes have seen.

#### Correctness
To prove the correctness, we must first have a simple lemma: if a correct process $p$ `bebDeliver`s a message $m$, then $p$ eventually `urbDeliver`s the message $m$. 

This can be proven as follows: ATTA, any process that `bebDeliver`s $m$ `bebBroadcast`s $m$. By the PFD1 (completeness of $\mathcal{P}$), and BEB1 (validity of BEB), there is a time at which $p$ `bebDeliver`s $m$ from every correct process and hence, ATTA, `urbDeliver`s it.

The proof is then:

- **Validity**: If a correct process $p$ `urbBroadcast`s a message $m$, then $p$ eventually `bebBroadcast`s and `bebDeliver`s $m$. Then, by our lemma, $p$ `urbDeliver`s it.
- **No duplication**: as BEB
- **No creation**: as BEB
- **Uniform agreement**: Assume some process $p$ `urbDeliver`s a message $m$. ATTA, and by PFD1 and PFD2 (completeness *and* accuracy of $\mathcal{P}$), every correct process `bebDeliver`s $m$. By our lemma, every correct process will therefore `urbDeliver` $m$.

Unlike previous algorithms, this relies on perfect failure detection. But under the assumption that the majority of processes stay correct, we can do with an eventually perfect failure detector $\diamond\mathcal{P}$. To do so, we remove the crash event above, and replace the `can_deliver` method with the following:

{% highlight python linenos %}
def can_deliver(m):
    return len(ack[m]) > N/2
{% endhighlight %}

## Causal order broadcast (CB)
So far, we didn't consider ordering among messages. In particular, we considered messages to be independent. 

Two messages from the same process might not be delivered in the order they were broadcast. This could be problematic: imagine a message board implemented with (uniform) reliable broadcast. For instance, in a message board application, a broadcaster $p$ could send out a message $m_1$, immediately change its mind and send out a rectification $m_2$. But due to network delays, messages may come out of order, and $m_2$ may be delivered before $m_1$ by the receiving node $q$. This is problematic, because the modification $m_2$ won't make sense to $q$ as long as it hasn't delivered $m_1$.

A nice property to have in these cases is *causal order*, where we don't necessarily impose a total ordering constraint, but do want certain groups of messages to be ordered in a way that makes sense for the applications. 

### Causal order
We say that  $m_1$ *causally precedes* $m_2$, denoted as $m_1 \longrightarrow m_2$, if any of the properties below hold:

- **FIFO Order**: Some process $p$ broadcasts $m_1$ before broadcasting $m_2$
- **Causal Order**: Some process $p$ delivers $m_1$ and then broadcasts $m_2$ 
- **Transitivity**: There is a message $m_3$ such that $m_1 \longrightarrow m_3$ and $m_3 \longrightarrow m_2$.

Note that $m_1 \longrightarrow m_2$ doesn't mean that $m_1$ *caused* $m_2$; it only means that it *may potentially have caused* $m_2$. But without any input from the application layer about what messages are logically dependent on each other, we can still enforce the above causal order.

### Properties
The **causal order property (CO)** guarantees that messages are delivered in a way that respects all causality relations. It is respected when we can guarantee that any process $p$ delivering a message $m_2$ has already delivered every message $m_1$ such that $m_1 \longrightarrow m_2$.

So all in all, the properties we want from CB are:

- **CB1. Validity = RB1 = BEB1**
- **CB2. No duplication = RB2 = BEB2**
- **CB3. No creation = RB3 = BEB3**
- **CB4. Agreement = RB4**
- **CB5. Causal order**: if $m_1 \longrightarrow m_2$ then any process $p$ delivering $m_2$ has already delivered $m_1$.

### No-waiting Algorithm
The following uses reliable broadcast, but we could also use [uniform reliable broadcast](#uniform-reliable-broadcast-urb) to obtain uniform causal broadcast.

{% highlight dapseudo linenos %}
Implements: 
    ReliableCausalOrderBroadcast (rcb)
Uses: 
    ReliableBroadcast (rb)
Events:
    Request: <rcbBroadcast, m>: broadcasts a message m to all processes
    Indication: <rcbDeliver, sender, m>: delivers a message m sent by sender
Properties:
    RB1, RB2, RB3, RB4, CO

upon event <rcb, Init> do:
    delivered := ∅;
    past := ∅; # contains all past [src, m] pairs

upon event <rcbBroadcast, m> do:
    trigger <rbBroadcast, [Data, past, m]>
    past := past ∪ {[self, m]};

upon event <rbDeliver, src_m, [Data, past_m, m]> do:
    if m ∉ delivered:
        # Deliver all undelivered, past messages that caused m:
        forall [src_n, n] ∈ past_m do: # in list order
            if n ∉ delivered:
                trigger <rcbDeliver, src_n, n>;
                delivered := delivered ∪ {n};
                past := past ∪ {[src_n, n]};
        # Then deliver m:
        trigger <rcbDeliver, src_m, m>;
        delivered := delivered ∪ {m};
        past := past ∪ {[src_m, m]};
{% endhighlight %}

This algorithm ensures causal reliable broadcast. The idea is to re-broadcast all past messages every time, making sure we don't deliver twice. This is obviously not efficient, but it works in theory.

An important point to note here is that this algorithm doesn't wait. At no point is the `rcbDeliver`y delayed in order to respect causal order.

### Garbage collection
A problem with this algorithm is that the size of the `past` grows linearly. A simple optimization is to add a kind of distributed garbage collection to clean the `past`.

The idea is that we can delete the `past` when all other processes have delivered. To do this, whenever a process `rcbDelivers`, we also need to send an acknowledgment to all other processes. When we have received an acknowledgment from all correct processes, then we can purge the corresponding message $m$ from the `past`. 

This implies using a perfect failure detector, as the implementation below shows.

{% highlight dapseudo linenos %}
Implements:
    GarbageCollection, ReliableCausalOrderBroadcast (rcb)
Uses:
    ReliableBroadcast (rb)
    PerfectFailureDetector (P)
Events:
    Request: <rcbBroadcast, m>: broadcasts a message m to all processes
    Indication: <rcbBroadcast, sender, m>: delivers a message m sent by sender
Properties:
    RB1, RB2, RB3, RB4, CO

upon event <rcb, Init> do:
    delivered := ∅;
    past := ∅;
    correct := Π;
    ack[m] := ∅; # for all possible messages m

upon event <crash, p> do:
    correct := correct \ {p};

# Broadcast as before:
upon event <rcbBroadcast, m> do:
    trigger <rbBroadcast, [Data, past, m]>
    past := past ∪ {[self, m]};

# Deliver messages as before:
upon event <rbDeliver, src_m, [Data, past_m, m]> do:
    if m ∉ delivered:
        # Deliver all undelivered, past messages that caused m:
        forall [src_n, n] ∈ past_m do: # (in list order)
            if n ∉ delivered:
                trigger <rcbDeliver, src_n, n>;
                delivered := delivered ∪ {n};
                past := past ∪ {[src_n, n]};
        
        # Then deliver m:
        trigger <rcbDeliver, src_m, m>;
        delivered := delivered ∪ {m};
        past := past ∪ {[src_m, m]};

# Ack delivered messages that haven't been acked yet:
upon event (exists m ∈ delivered) such that (self ∉ ack[m]) do:
    ack[m] := ack[m] ∪ {self};
    trigger <rbBroadcast, [ACK, m]>;

# Register delivered acks:
upon event <rbDeliver, sender, [ACK, m]> do:
    ack[m] := ack[m] ∪ {sender};

# Delete past once everybody has acked:
upon event correct ⊆ ack[m] do:
    forall [src_n, n] ∈ past such that n = m:
        past := past \ {[src_n, m]};
{% endhighlight %}

We need the perfect failure detector's strong accuracy property to prove the causal order property. 

However, we don't need the failure detector's completeness property; if we don't know that a process is crashed, it has no impact on correctness, only on performance, since it just means that we won't delete the past.

### Waiting Algorithm
Another algorithm is given below. It uses a ["vector clock" (VC)](https://en.wikipedia.org/wiki/Vector_clock) as an alternative, more efficient encoding of the past.

A VC is simply a vector with one entry for each process in $\Pi$. Each entry is a sequence number (also called *logical clock*) for the corresponding process. Each process $p$ maintains its own VC. Its own VC entry counts the number of times it has `rcbBroadcast`. The entries for other processes $q$ count the number of times $p$ has `rcbDeliver`ed from $q$.

 A VC is updated under the following rules:

- Initially all clocks are empty
- Each time a process sends a message, it increments its own logical clock in the vector by one, and sends a copy of its own vector.
- Each time a process receives a message, it increments its own logical clock in the vector by one and updates each element in its vector by taking the maximum of the value in its own vector clock and the value in the vector in the received message (for every element).


{% highlight dapseudo linenos %}
Implements:
    ReliableCausalOrderBroadcast (rcb)
Uses:
    ReliableBroadcast (rb)

upon event <rcb, Init> do:
    pending := ∅;
    for all p ∈ Π:
        VC[p] := 0;

upon event <rcbBroadcast, m> do:
    trigger <rcbDeliver, self, m>;
    trigger <rbBroadcast, [Data, VC, m]>; 
    VC[self] := VC[self] + 1;

upon event <rbDeliver, src, [Data, VC_m, m]>:
    if src != self:
        pending := pending ∪ {(src, VC_m, m)};
        # Deliver pending:
        while exists (src_n, VC_n, n) ∈ pending
          such that VC_n <= VC do:
            pending := pending \ {(src_n, VC_n, n)};
            trigger <rcbDeliver, self, n>; # self, can this be true?
            VC[src_n] := VC[src_n] + 1
{% endhighlight %}

The $\le$ comparison operation on vector clocks is defined as follows: $VC_a \le VC_b$ iff it is less or equal in all positions, and at least one position is strictly less.

## Total order broadcast (TOB)
In [reliable broadcast](#reliable-broadcast), the processes are free to deliver in any order they wish. In [causal broadcast](#causal-order-broadcast-cb), we restricted this a little: the processes must deliver in causal order. But causal order is only partial: some messages are causally unrelated, and may therefore be delivered in a different order by the processes.

In **total order broadcast** (TOB), the processes must deliver all messages according to the same order. Note that this is orthogonal to causality, or even FIFO ordering. It can be *made* to respect causal or FIFO ordering, but at its core, it is only concerned with all processes delivering in the same order, no matter the actual ordering of messages.

TOB is also sometimes called *atomic broadcast*, as the delivery occurs as if broadcast was an indivisible, atomic action

An application using TOB would be Bitcoin; for the blockchain, we want to make sure that everybody gets messages in the same order, for consistency. More generally though, total ordering is useful for any replicated state machine where replicas need to treat requests in the same order to preserve consistency.

#### Properties
The properties are the same as those of (uniform) reliable broadcast, but with an added total order property.

- **TOB1. Validity = RB1 = BEB1**
- **TOB2. No duplication = RB2 = BEB2**
- **TOB3. No creation = RB3 = BEB3**
- **(U)TOB4. (Uniform) Agreement = (U)RB4**
- **(U)TOB5. (Uniform) Total Order**: Let $m$ and $m'$ be any two messages. Let $p$ be any (correct) process that delivers $m$ without having delivered $m'$ before. Then no (correct) process delivers $m'$ before $m$.

#### Consensus-based Algorithm
The algorithm can be implemented with consensus, which is the next section[^read-both].

[^read-both]: Consensus and TOB are very interdependent, so it can be a good idea to read both twice.

The intuition of the algorithm is that we first disseminate messages using RB. This imposes no particular order, so the processes simply store the messages in `unordered`. At this point, we have no guarantees of dissemination or ordering; it's even possible that no processes have the same sets.

To solve this, we use consensus to decide on a single set; we order the messages in that set, and then deliver.

There are multiple rounds of this consensus, which we count in the `round` variable. The consensus helps us decide on a set of messages to *deliver* in that round. We use the `wait` variable to make sure that we only hold one instance of consensus at once.

Note that while one consensus round is ongoing, we may amass multiple messages in `unordered`. This means that consensus may lead us to decide on multiple messages to deliver at once.

{% highlight dapseudo linenos %}
Implements:
    TotalOrderBroadcast (tob)
Uses:
    ReliableBroadcast (rb)
    Consensus (cons)
Events:
    Request: <tobBroadcast, m>: broadcasts a message m to all processes
    Indication: <tobDeliver, src, m>: delivers a message m broadcast by src
Properties:
    TOB1, TOB2, TOB3, TOB4, TOB5

upon event <tob, Init>:
    unordered := ∅;
    delivered := ∅;
    wait := false;
    round := 1;

upon event <tobBroadcast, m> do:
    trigger <rbBroadcast, m>

# Save received broadcasts for later:
upon event <rbDeliver, src_m, m> and (m ∉ delivered) do:
    unordered := unordered ∪ {(src_m, m)};

# When no consensus is ongoing and we have 
# unordered messages to propose:
upon (unordered != ∅) and (not wait) do:
    wait := true;
    initialize instance of consensus;
    trigger <propose, unordered>;

# When consensus is done:
upon event <decide, decided> do:
    unordered := unordered \ {decided};
    ordered = sort(decided);
    for (src_m, m) in ordered:
        trigger <tobDeliver, src_m, m>;
        delivered := delivered ∪ {m};
    round := round + 1;
    wait = false;
{% endhighlight %}

We assume that the `sort` function is deterministic and that all processes run the exact same sorting routine. We run this function to be sure that all processes traverse and deliver the decided set in the same order (usually, sets do not offer any ordering guarantees, though this is somewhat of an implementation detail).

Our total order broadcast is based on consensus, which we describe below.

## Consensus (CONS)
In the (uniform) consensus problem, the processes all propose values, and need to agree on one of these propositions. This gives rise to two basic events: a proposition (`<propose, v>`), and a decision (`<decide, v>`). Solving consensus is key to solving many problems in distributed computing (total order broadcast, atomic commit, ...).

Blockchain is based on consensus. Bitcoin mining is actually about solving consensus: a leader is chosen to decide on the broadcast order, and this leader gains 50 bitcoin. Seeing that this is a lot of money, many people want to be the leader; but we only want a single leader. Nakamoto's solution is to choose the leader by giving out a hard problem. The computation can only be done with brute-force, there are no smart tricks or anything. So people put [enormous amounts of energy](https://digiconomist.net/bitcoin-energy-consumption) towards solving this. Usually, only a single person will win the mining block; the probability is small, but the [original Bitcoin paper](https://bitcoin.org/bitcoin.pdf) specifies that we should wait a little before rewarding the winner, in case there are two winners.

### Properties

The properties that we would like to see are:

- **C1. Validity**: if a value is decided, it has been proposed
- **(U)C2. (Uniform) Agreement**: no two correct (any) processes decide differently
- **C3. Termination**: every correct process eventually decides
- **C4. Integrity**: every process decides at most once

Termination and integrity together imply that every correct process decides exactly once. Validity ensures that the consensus may not invent a value by itself. Agreement is the main feature of consensus, that every two correct processes decide on the same value. 

When we have uniform agreement (UC2), we want no processes to decide differently, no matter if they are faulty or correct. In this case, we talk about *uniform consensus*.

We can build consensus using total order broadcast, which is described above. But total broadcast can be built with consensus. It turns out that **consensus and total order broadcast are equivalent problems in a system with reliable channels**.

### Algorithm 1: Fail-Stop Consensus
Suppose that there are $N$ processes in $\Pi$, with IDs $1, \dots, N$. At the beginning, every process proposes a value; to decide, the processes go through $N$ rounds incrementally. At each round, the process with the ID corresponding to the round number is the leader of the round.

The leader decides its current proposal and broadcasts it to all. A process that is not the leader waits. This means that in a given round $i$, only the leader process $i$ is broadcasting. Additionally, a process only decides when it is the leader. 

The non-leader processes can either deliver the proposal of the leader to adopt it, or detect that the leader has crashed. In any case, we can move on to the next round at that moment.

Now that we understand the properties of the algorithm, let's take a look at an example run.

Process 1 is the first to be the leader. Once it gets a proposal from the application layer, it decides on it, and broadcasts it to the others. However, let's suppose it crashes before getting to broadcast (BEB fails in this case). Then, the other processes will detect the crash with $\mathcal{P}$, and go to the next round. 

Process 2 is now the leader. Since it doesn't have a proposal from process 1, it will have to get one from the application layer. Once it has it, it can broadcast it to the others. Let's assume this goes smoothly, and all processes receive it. They can all go to the next round; from now on, whatever the application layer proposes, they have to obey the decision from the previous leader.

This should make it clear why the algorithm is also known as "hierarchical consensus": every process must obey the decisions of the process above it (with a smaller index), as long as they don't crash. We can think of this as a sort of line to the throne: we use the proposal of whoever is on the throne. If they die, number 2 in line decides, and so on.

Note that the rounds are not global time; we may make them so in examples for the sake of simplicity, but rounds are simply a local thing, which are somewhat synchronized by message passing from the leader.

{% highlight dapseudo linenos %}
Implements:
    Consensus (cons)
Uses:
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
Events:
    Request: <propose, v>: proposes value v for consensus
    Indication: <decide, v>: outputs a decided value v of consensus
Properties:
    C1, C2, C3, C4

upon event <cons, Init> do:
    suspected := ∅;     # list of suspected processes
    round := 1;         # current round number
    proposal := nil;    # current proposal
    broadcast := false; # whether we've already broadcast
    delivered := [];    # whether we've received a proposal from a process

upon event <crash, p> do:
    suspected := suspected ∪ {p};

# If we don't already have a decision from the leader,
# take our own proposal
upon event <Propose, v> do:
    if proposal = nil:
        proposal := v;

# When we receive a decision from the leader, use that:
upon event <bebDeliver, leader, [Decided, v]> do:
    proposal := v;
    delivered[leader] := true;

# If we've received a proposal from the leader, 
# or if the leader has crashed, go to the next round:
upon event delivered[round] = true or round ∈ suspected do:
    round := round + 1;

# When we are the leader and we have a value to propose
# (which may be ours, or one that we have from the previous leader),
# we broadcast it, and deliver the decision to the application layer
upon event round = self and broadcast = false and proposal != nil do:
    trigger <decide, proposal>;
    trigger <bebBroadcast, [Decided, proposal]>;
    broadcast = true;
{% endhighlight %}

Since this algorithm doesn't aim for *uniform* consensus (but only regular consensus), it can tolerate $f < N$ failures; as long as one process remains correct, it will decide on a value.

Let's formulate a short correctness argument for the algorithm:

- *Validity* follows from the algorithm and BEB1 (validity)
- *Agreement* can be proven as follows. Let $p_i$ with ID $i$ be the correct process with the smallest ID in a run. Suppose it decides on some value $v$.
    + If $i = N$, then $p_i$ is the only correct process
    + Otherwise, in round $i$, ATTA, all correct processes $p_j$ with $j > i$ receive $v$ and will not decide differently from $v$
- *Termination* follows from PFD1 (strong completeness) and BEB1 (validity): no process will remain indefinitely blocked in a round; every correct process $p$ will eventually reach round $p$ and decide in that round
- *Integrity* follows from the algorithm and BEB1 (validity)

### Algorithm 2: Fail-Stop Uniform Consensus
The previous algorithm does not guarantee *uniform* agreement. The problem is that that some of the processes decide too early, without making sure that their decision has been seen by enough processes (remember that if the broadcaster fails in BEB, then we have no guarantee that all processes receive the broadcast). It could therefore decide on a value, and then crash before anybody receives it, which would violate uniform agreement (UC2). The other processes might then have no choice but to decide on a different value.

To fix this, the idea is to do the same thing as before, but instead of $p_i$ deciding at round $i$, we wait until the last round $N$. The resulting algorithm is simply called "hierarchical uniform consensus".

{% highlight dapseudo linenos %}
Implements:
    UniformConsensus (ucons)
Uses:
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
Events:
    Request: <propose, v>: proposes value v for consensus
    Indication: <decide, v>: outputs a decided value v of consensus
Properties:
    C1, UC2, C3, C4

upon event <ucons, Init> do:
    suspected := ∅;     # list of suspected processes
    round := 1;         # current round number
    proposal := nil;    # current proposal
    broadcast := false; # whether we've already broadcast
    decided := false;   # whether we've already decided
    delivered := [];    # whether we've received a proposal from a process

upon event <crash, p> do:
    suspected := suspected ∪ {p};

# If we don't already have a decision from the leader,
# take our own proposal
upon event <Propose, v> do:
    if proposal = nil:
        proposal := v;

# When we receive a decision from the leader, use that:
upon event <bebDeliver, leader, [Decided, v]> do:
    proposal := v;
    delivered[leader] := true;

# If we've received a proposal from the leader,  
# or if the leader has crashed, go to the next round.
# If it's the last round, we can deliver the decision 
# to the application layer.
upon event delivered[round] = true or round ∈ suspected do:
    if round = N and not decided:
        trigger <decide, proposal>;
        decided := true;
    else:
        round := round + 1;

# When we are the leader and we have a value to propose
# (which may be ours, or one that we have from the previous leader),
# we broadcast it
upon event round = self and broadcast = false and proposal != nil do:
    trigger <bebBroadcast, [Decided, proposal]>;
    broadcast = true;
{% endhighlight %}

For the correctness argument, we'll need to introduce a short lemma: if $p_j$ completes round $i$ without receiving any message from $p_i$, and $j > i$, then $p_i$ crashes by the end of round $j$.

{% details Proof of the lemma %}
We'll do a proof by contradiction: suppose $p_j$ completes round $i$ without receiving a message from $p_i$, $j>i$ and $p_i$ completes round $j$.

Since $p_j$ completed round $i$ without hearing from $p_i$, ATTA, it must be because $p_j$ suspects $p_i$ in round $i$. We're using a perfect failure detector $\mathcal{P}$. So in round $j$, we either have:

- $p_i$ suspects $p_j$, which is impossible because $p_i$ crashes before $p_j$
- $p_i$ receives the round $j$ message from $p_j$, which is also impossible because $p_i$ crashed before $p_j$ completes round $i < j$

We have proved the contradiction in the inverse, and thus the lemma.
{% enddetails %}

- *Validity* follows from the algorithm and BEB1 (validity)
- *Termination* follows from PFD1 (strong completeness) and BEB1 (validity): no process will remain indefinitely blocked in a round; every correct process $p$ will eventually reach round $p$ and decide in that round
- *Uniform Agreement* can be proven as follows. 
  
  Let $p_i$ with ID $i$ be the process with the smallest ID which decides on some value. This implies that it completes round $N$.

  By the above lemma, in round $i$, every $p_j$ with $j > i$ receives and adopts the proposal of $p_i$. Thus, every process which sends a message after round $i$, or which decides, has the same proposal at the end of round $i$.

- *Integrity* follows from the algorithm and BEB1 (validity)

### Algorithm 3: Uniform Consensus with Eventually Perfect Failure Detector
The two previous algorithms relied on perfect failure detectors. What happens if we use an eventually perfect failure detector $\diamond\mathcal{P}$ instead?

The problem is that that $\diamond\mathcal{P}$ only has *eventual* strong accuracy (EPFD2). This means that correct processes may be *falsely* suspected a finite number of time, which breaks the two previous algorithms: if a process is falsely suspected by everyone, and it falsely suspects everyone, then all the others would do consensus without it, and decide differently from it.

This algorithm relies on a majority of processes being correct (i.e. it can handle $f < \frac{N}{2}$ failures). The solution is a little involved, so we won't give pseudo-code for it. Instead, we'll just try to get an overarching idea of what goes on.

The algorithm is also round-based: processes still move incrementally from one round to the next. Process $p_i$ is the leader at round $k$, where $i = k \mod n$. In such a round, $p_i$ *tries* to decide:

- It succeeds if it is not suspected. 
- It fails if it is suspected. Processes that suspect $p_i$ inform it (with a negative acknowledgment, NACK, message), and everybody moves on to the next round (including $p_i$).

If it succeeds, it uses RB to send the decision to all. It's important to use RB at this step (not BEB) to preclude the case where $p_i$ crashes while broadcasting. This would allow for a situation where some nodes have delivered, and others haven't.

Within a round $k$, $p_i$ decides on a value in three steps:

1. It collects propositions from the other processes, and chooses a value proposed by the majority.
2. It broadcasts the chosen value back, and processes change their proposal to the value broadcast by $p_i$. The processes send an acknowledgment.
3. If everyone acks, it decides, and broadcasts the decision. When others receive the decision, they decide on the given value.

If a process suspects it at any point, it sends a NACK and everyone moves on. But the decided value may still have disseminated among the processes, since $p_i$ broadcasts the value before deciding. Thus, we have progress (because we went with the majority value, so we're advancing towards consensus, or at worst, not moving).

Let's take a look at a correctness argument:

- *Validity* is trivial
- *Uniform agreement*: Let $k$ be the first round in which some leader process $p_i$ decides on a value $v$. This means that, in round $k$, a majority of processes have adopted $v$. ATTA, no value other than $v$ will be proposed, and therefore decided, henceforth.
- *Termination* states that every correct process eventually decides. If a correct process decides, it uses RB to send the decision to all, so every correct process decides. 
- *Integrity* is trivial

## Atomic commit
The unit of data processing in a distributed system is the *transaction*. A transaction describes the actions to be taken, and can be terminated either by **committing** or **aborting**.

### Non-Blocking Atomic Commit (NBAC)
The **nonblocking atomic commit (NBAC)** abstraction is used to solve this problem in a reliable way. As in consensus, every process proposes an initial value of 0 or 1 (no or yes), and must decide on a final value 0 or 1 (abort or commit). Unlike consensus, the processes here seek to decide 1, but every process has a veto right.

The properties of NBAC are:

- **NBAC1. Uniform Agreement**: no two processes decide differently
- **NBAC2. Termination**: every correct process eventually decides
- **NBAC3. Commit-validity**: 1 can only be decided if all processes propose 1
- **NBAC4. Abort-validity**: 0 can only be decided if some process crashes or votes 0

Note that here, NBAC must decide to abort if some process crashes, even though all processes have proposed 1 (commit).

We can implement NBAC using three underlying abstractions:

- A perfect failure detector $\mathcal{P}$
- Uniform consensus
- Best-effort broadcast BEB

It works as follows: every process $p$ broadcasts its initial vote (0 or 1, abort or commit) to all other processes using BEB. It waits to hear something from every process $q$ in the system; this is either done through *beb*-delivery from $q$, or by detecting the crash of $q$. At this point, two situations are possible:

- If $p$ gets 0 (abort) from any other process, or if it detects a crash, it invokes consensus with a proposal to abort (0). 
- Otherwise, if it receives the vote to commit (1) from all processes, then it invokes consensus with a proposal to commit (1).

Once the consensus is over, every process NBAC-decides according to the outcome of the consensus.

We can write this more formally:

{% highlight dapseudo linenos %}
Implements:
    nonBlockingAtomicCommit (nbac)
Uses:
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
    UniformConsensus (ucons)
Events:
    Request: <nbacPropose, v>
    Indication: <nbacDecide, v>
Properties:
    NBAC1, NBAC2, NBAC3, NBAC4


upon event <nbac, Init> do:
    prop := 1;
    delivered := ∅;
    correct := Π;

upon event <crash, p> do:
    correct := correct \ {p};

# Broadcast proposals to others:
upon event <propose, v> do:
    trigger <bebBroadcast, v>;

# Register proposal broadcasts from others:
upon event <bebDeliver, src, v> do:
    delivered := delivered ∪ {src};
    prop := prop * v;

# When all correct processes have delivered,
# initialize consensus by proposing prop
upon event correct ⊆ delivered do:
    if correct != Π:
        prop := 0;
    trigger <uconsPropose, prop>;

upon event <uconsDecide, decision> do:
    trigger <nbacDecide, decision>;
{% endhighlight %}

We use multiplication to factor in the decisions we get from other processes; if we get a single 0, the final proposition will be 0 too. If we only get ones, the final proposition will be 1 too. Otherwise, this should be a fairly straight-forward implementation of the description we gave. 

We need a perfect failure detector $\mathcal{P}$. An eventually perfect failure detector $\diamond\mathcal{P}$ is not enough, because we may suspect a process: this leads us to run uniform consensus with a proposal to abort, and consequently decide to abort. After this whole ordeal, we may find out that it wasn't crashed after all, and the previously suspected process would never decide, which violates termination. 

### 2-Phase Commit (2PC)
This is a *blocking* algorithm, meaning that a crash will result in the algorithm being stuck. Unlike NBAC, this algorithm does not use consensus. It operates under a relaxed set of constraints; the termination property has been replaced with weak termination, which just says that if a process $p$ doesn't crash, then all correct processes eventually decide.

In 2PC, we have a leading coordinator process $p$ which takes the decision. It asks everyone to vote, makes a decision, and notifies everyone of the decision.

As the name indicates, there are two phases in this algorithm:

1. **Voting phase:** As before, proposals are sent with best-effort broadcast. A process collects all these proposals. 
2. **Commit phase**: Again, just as before, it decides to abort if it receives any abort proposals, or if it detects any crashes with its perfect failure detector. Otherwise, if it receives proposals to commit from everyone, it will decide to commit. It then sends this decision to all processes with BEB.

If $p$ crashes, all processes are blocked, waiting for its response. 

## Terminating reliable broadcast (TRB)
Like reliable broadcast, terminating reliable broadcast (TRB) is a communication primitive used to disseminate a message among a set of processes in a reliable way. However, TRB is stricter than URB.

In TRB, there is a specific broadcaster process $p_{\text{src}}$, known by all processes. It is supposed to broadcast a message $m$. We'll also define a distinct message $\phi \ne m$. The other processes need to deliver $m$ if $p_{\text{src}}$ is correct, but may deliver $\phi$ if $p_{\text{src}}$ crashes.

The idea is that if $p_{\text{src}}$ crashes, the other processes may detect that it's crashed, without having ever received $m$. But this doesn't mean that $m$ wasn't sent; $p_{\text{src}}$ may have crashed while it was in the process of sending $m$, so some processes may have delivered it while others might never do so.

For a process $p$, the following cases cannot be distinguished:

- Some other process $q$ has delivered $m$; this means that $p$ should keep waiting for it
- No process will ever deliver $m$; this means that $p$ should **not** keep waiting for it

TRB solves this by adding this missing piece of information to (uniform) reliable broadcast. It ensures that every process either delivers the message $m$ or sends a failure indicator $\phi$. 

### Properties
The properties of TRB are:

- **TRB1. Integrity**: If a process delivers a message $msg$, then either $msg=\phi$, or $msg=m$ that was broadcast by $p_{\text{src}}$
- **TRB2. Validity**: If the sender $p_{\text{src}}$ is correct and broadcasts a message $m$, then $p_{\text{src}}$ eventually delivers $m$
- **(U)TRB3. (Uniform) Agreement**: For any message $m$, if a correct process (any process) delivers $m$, then every correct process delivers $m$
- **TRB4. Termination**: Every correct process eventually delivers exactly one message

Unlike reliable broadcast, every correct process delivers a message, even if the broadcaster crashes. Indeed, with (uniform) reliable broadcast, when the broadcaster crashes, the other processes may deliver *nothing*.

### Algorithm
The following algorithm implements consensus-based uniform terminating reliable broadcast. To implement regular (non-uniform) TRB, we can just use regular (non-uniform) consensus.

All processes wait until they receive a message from the source $p_{\text{src}}$, or until they detect that it has crashed. By the validity property of BEB, and the properties of a perfect failure detector, no process is ever left waiting forever. 

They then invoke uniform consensus to know whether to deliver $m$ or $\phi$.

{% highlight dapseudo linenos %}
Implements:
    trbBroadcast (trb)
Uses:
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
    Consensus (ucons)
Events:
    Request: <trbBroadcast, m>:  broadcasts a message m to all processes
    Indication: <trbDeliver, m>: delivers a message m, or the failure ϕ
Properties:
    TRB1, TRB2, TRB3, TRB4

upon event <trb, Init>:
    proposal := nil;
    correct := Π;

# When application broadcasts:
upon event <trbBroadcast, m> do:
    trigger <bebBroadcast, m>;

# When the perfect failure detector detects that
# the broadcaster p_src has crashed:
upon event <crash, p> and (proposal = nil) do:
    if p = p_src:
        proposal := ϕ;

# Otherwise, if we successfully receive from p_src:
upon event <bebDeliver, p, m> and (proposal = nil) do:
    if p = p_src:
        proposal := m;

# Start consensus as soon as we have a proposal:
upon event (proposal != nil) do:
    trigger <propose, proposal>;

# Deliver results of consensus:
upon event <decide, decision> do:
    trigger <trbDeliver, p_src, decision>;
{% endhighlight %}

Let's take a look at the scenario where $p_{\text{src}}$ broadcasts $m$ to processes $q$, $r$ and $s$. It broadcasts using BEB, so it can crash while broadcasting, and some processes wouldn't receive the message. Suppose $q$ and $r$ got the message, but $s$ did not; instead it detects that $p_{\text{src}}$ has crashed. In the consensus round, $s$ will propose $\phi$, while the two other processes propose $m$. Since they are in the majority, the result of the consensus will be a decision to deliver $m$ (remember [algorithm 3 for uniform consensus](#algorithm-3-uniform-consensus-with-eventually-perfect-failure-detector), which picks the majority value). But in this scenario, $\phi$ would also have been a valid result.

### Failure detector
The TRB algorithm uses the perfect failure detector $\mathcal{P}$, which means that is is sufficient. Is it also sufficient? We'll argue that it is, because we can implement $\mathcal{P}$ with TRB (meaning that it's necessary):

Assume that every process $p_i$ is the broadcaster $p_{\text{src}}$, and can use an infinite number of instances of TRB. The algorithm is as follows:

1. Every process keeps broadcasting messages with TRB
2. If a process $p_k$ delivers $\phi_i$, it suspects $p_i$ 

This algorithm uses non-uniform TRB, i.e. just respecting agreement (not uniform agreement).

## Group membership (GM)
Many of the algorithms we've seen so far require some knowledge of the state of other processes in the network $\Pi$. In other words, we need to know which processes are *participating* in the computation and which are not. So far, we've used failure detectors to get this information.

The problem with failure detectors is that they are not coordinated, even when the failure detector is perfect. The outputs of failure detectors in different processes are not always the same: we may get notifications about crashes in different orders and at different times (because of delays in the network), and thus obtain different perspectives of the system's evolution.

The group membership abstraction solves this problem, giving us consistent, accurate and better coordinated information about the state of processes. 

In this course, we'll only use group membership to give coordinated information about crashes, but it's useful to know that it can also be used to coordinate processes *joining* or *leaving* the set $\Pi$ explicitly (i.e. without crashing, but instead leaving voluntarily). This  enables dynamic changes in the set of processes $\Pi$. So far, we've assumed that $\Pi$ is a static set of $N$ processes, but group membership allows us to handle dynamic sets.

### Properties
A group is the set of processes participating in the computation. The current membership is called a *view*. A view $V$ is a pair $V = (i, M)$, where $i$ is the numbering of the view, and $M$ is a set of processes.

The views are numbered by the number of changes the set of processes has gone through previously. As such, the first view is identified by $i=0$, and $M = \Pi$ (so $V_0 = (0, \Pi)$).

When the view changes, we get an indication event `<membView, V>`; we say that processes *install* this new view.

The properties for the group membership abstraction in this course are:

- **Memb1. Local Monotonicity**: If a process installs view $(j, M)$ after $(k, N)$, then $j > k$ and $M \subset N$ (the only reason to change a view is to remove a process from the set when it crashes).
- **Memb2. Uniform Agreement**: No two processes install views $(j, M)$ and $(j, M')$ such that $M \ne M'$.
- **Memb3. Completeness**: If a process $p$ crashes, then there is an integer $j$ such that every correct process installs view $(j, M)$ in which $p\notin M$
- **Memb4. Accuracy**: If some process installs a view $(i, M)$ and $p\notin M$ then $p$ has crashed.

### Algorithm
The implementation uses uniform consensus and a perfect failure detector.

{% highlight dapseudo linenos %}
Implements:
    GroupMembership (memb)
Uses:
    UniformConsensus (ucons)
    PerfectFailureDetector (P)
Events:
    Indication: <membView, V>
Properties:
    Memb1, Memb2, Memb3, Memb4

upon event <memb, Init> do:
    view := (0, Π);
    correct := Π;
    wait := true;

upon event <crash, p> do:
    correct := correct \ {p};

# When we've detected a crash and we aren't waiting for
# consensus, trigger new consensus for view.
upon event (correct ⊂ view.memb) and (not wait) do:
    wait := true;
    trigger <uconsPropose, (view.id + 1, correct)>;

# When consensus is done, install the new view:
upon event <uconsDecide, (id, memb)> do:
    view := (id, memb);
    wait := false;
    trigger <membView, view>;
{% endhighlight %}

We use a `wait` variable: this allows to prevent a process from triggering a new view installation before the previous one has been done.

## View-Synchronous broadcast (VS)
View-synchronous broadcast is the abstraction resulting from the combination of group membership and reliable broadcast. It ensures that the delivery of messages is coordinated by the installation of views.

### Properties
We aim to ensure all the properties of group membership (Memb1, Memb2, Memb3, Memb4) and of reliable broadcast (RB1, RB2, RB3, RB4). On top of this, we also aim to ensure the following property:

- **VS1. View inclusion**: A message is `vsDeliver`ed in the view where it is `vsBroadcast`.

Unfortunately, this property doesn't come for free. Combining VS and GM introduces a subtle problem that we'll have to solve, justifying the introduction of a solution as a new abstraction. Indeed, if a message is broadcast right as we're installing a view, we're breaking things. 

Consider that a group of processes are exchanging messages, and process $q$ crashes. This failure is detected, and the other processes install a new view $V = (i, M)$, with $q \notin M$. After that, suppose that process $p$ delivers a message $m$ that was originally broadcast by $q$ (this can happen because of delays in the network). But it doesn't make sense to deliver messages from processes that aren't in the view to the application layer.

At this point, the solution may seem straightforward: allow $p$ to discard messages from $q$. Unfortunately, it's possible that a third process $r$ has delivered $m$ before the view $V$ was installed. At this point, process $p$ must essentially chose between two conflicting goals: either deliver $m$ to ensure agreement (RB4), or discard it and guarantee view inclusion (VS1).

To solve this, we must introduce some notion of phases in which messages can or cannot be sent. 

### Algorithm 1: TRB-based VS
VS broadcast extends both RB and GM, so its interface must have events of both primitives. In addition to that, we need to add two more events for blocking communications when we're about to install a view.

Note that these events for blocking communications aren't between processes: they're a contract between the VS algorithm and the layer above (i.e. the application layer). If the application layer keeps broadcasting messages, installing a view may be postponed indefinitely. Therefore, when we need to install a view, we ask the application layer to stop broadcasting in the current view by indicating a `<vsBlock>` event. When the higher level module agrees, it replies by the requests of `<vsBlockOk>`.

We assume that the application layer indeed is well-behaved, and does not broadcast any further in the current view after the `<vsBlockOk>`. It can start broadcasting again once a new view is installed (`<vsView, V>`).

The key element of this algorithm is a flush procedure, which the processes execute when the GM changes the view. This procedure uses uniform TRB to rebroadcast messages that it has `vsDeliver`ed in the current view.

For normal data transfer within a view, we attach the view id to each message, and use BEB to broadcast. On the opposite side, when messages are BEB delivered (with a view id matching the current view), it can immediately `vsDeliver`. It's also important the receiver saves the message to `delivered`, so that it can replay it during the flush procedure.

We start the flush procedure when GM installs a view. We first ask the application to stop broadcasting; when we receive the OK, we stop `vsDeliver`ing, and discard all BEB messages. We can then resend all messages we `vsDeliver`ed previously (which are saved in `delivered`) using an instance of TRB for each destination process.

We then receive all flush messages from the other processes. When we have received all flushes, we can move on to the next view.

{% highlight dapseudo linenos %}
Implements:
    ViewSynchrony (vs)
Uses:
    GroupMembership (memb)
    UniformTerminatingReliableBroadcast (utrb)
    BestEffortBroadcast (beb)
Events:
    Request: <vsBroadcast, m>: broadcasts m to all processes
    Indication: <vsDeliver, src, m>: delivers message m broadcast by src
    Indication: <vsView, V>: Installs a view V = (id, M)
    Indication: <vsBlock>: requests that no new messages are 
                           broadcast temporarily, until next view is installed
    Request: <vsBlockOk>: confirms that no new messages will be
                          broadcast until next view is installed
Properties:
    RB1, RB2, RB3, RB4
    Memb1, Memb2, Memb3, Memb4
    VS1

upon event <vs, Init> do:
    view := (0, Π);    # currently installed view
    nextView := nil;   # next view to install after flushing
    pending := [];     # FIFO queue of pending views
    delivered := ∅;    # set of delivered messages in current view
    trbDone := ∅;      # set of processes done flushing with uTRB
    flushing := false; # whether we're currently flushing
                       # messages in order to install a view
    blocked := false;  # whether the application layer is blocked

#############################
# Part 1: Data transmission #
#############################

# Attach view ID to all messages we will broadcast:
upon event <vsBroadcast, m> and (not blocked) do:
    delivered := delivered ∪ {m};
    trigger <vsDeliver, self, m>;
    trigger <bebBroadcast, [Data, view.id, m]>;

# Deliver new messages from same view:
upon event <bebDeliver, src, [Data, view_id, m]> do:
    if (view.id = view_id) and (m ∉ delivered) and (not blocked):
        delivered := delivered ∪ {m};
        trigger <vsDeliver, src, m>;

#######################
# Part 2: View change #
#######################

# Append new view to pending:
upon event <membView, V> do:
    pending.append(V);

# When we need to switch view, initiate flushing by
# requesting vsBlock from application layer:
upon event (pending != ∅) and (not flushing) do:
    nextView := pending.pop(); # get head of queue
    flushing := true;
    trigger <vsBlock>;

# When application layer replies OK, block and flush:
upon event <vsBlockOk> do:
    blocked := true;
    trbDone := ∅;
    trigger <trbBroadcast, self, (view.id, delivered)>;

# Get flushes and deliver missing messages:
upon event <trbDeliver, src, (view_id, view_delivered)> do:
    trbDone := trbDone ∪ {src};
    forall m ∈ view_delivered and m ∉ delivered do:
        delivered := delivered ∪ {m};
        trigger <vsDeliver, src, m>;

# If we get ϕ, we can consider the process to be done flushing:
upon event <trbDeliver, src, ϕ> do:
    trbDone := trbDone ∪ {src};

# Once we have all flushes, we can go to the next view:
upon event (trbDone = view.memb) and (blocked = true) do:
    view := nextView;
    flushing := false;
    blocked := false;
    delivered := ∅;
    trigger <vsView, view>;
{% endhighlight %}

### Algorithm 2: Consensus-based VS
The previous algorithm is uniform in the sense that no two processes install different views. But it isn't uniform in terms of message delivery, as one process may `vsDeliver` a message and crash, while no other processes deliver that message.

So we need to revise the previous algorithm to get uniform VS. Instead of launching parallel instances of TRB, plus a group membership, we can use a consensus instance and parallel broadcasts for every view change.

The idea is that when $\mathcal{P}$ detects a failure, the processes exchange the messages they have delivered, and use consensus to agree on the membership and message set.

The data transmission works as previously. However, for the view change, we use consensus to agree on the message set (stored in `dset`).

{% highlight dapseudo linenos %}
Implements:
    ViewSynchrony (vs)
Uses:
    UniformConsensus (ucons)
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
Events:
    Request: <vsBroadcast, m>: broadcasts m to all processes
    Indication: <vsDeliver, src, m>: delivers message m broadcast by src
    Indication: <vsView, V>: Installs a view V = (id, M)
    Indication: <vsBlock>: requests that no new messages are 
                           broadcast temporarily, until next view is installed
    Request: <vsBlockOk>: confirms that no new messages will be
                          broadcast until next view is installed
Properties:
    RB1, RB2, RB3, RB4
    Memb1, Memb2, Memb3, Memb4
    VS1

upon event <vs, Init> do:
    view := (0, Π);
    correct := Π;
    flushing := false;
    blocked := false;
    delivered := ∅;
    dset := ∅;

#############################
# Part 1: Data transmission #
#############################

# Same as before

upon event <vsBroadcast, m> and (not blocked) do:
    delivered := delivered ∪ {m};
    trigger <vsDeliver, self, m>;
    trigger <bebBroadcast, [Data, view.id, m]>;

upon event <bebDeliver, src, [Data, view_id, m]> do:
    if (view.id = view_id) and (m ∉ delivered) and (not blocked):
        delivered := delivered ∪ {m};
        trigger <vsDeliver, src, m>;

#######################
# Part 2: View change #
#######################

upon event <crash, p> do:
    correct := correct \ {p};
    if not flushing:
        flushing := true;
        trigger <vsBlock>;

upon event <vsBlockOk> do:
    blocked := true;
    trigger <bebBroadcast, [DSET, view.id, delivered]>;

upon event <bebDeliver, src, [DSET, view_id, m_set]> do:
    dset := dset ∪ (src, m_set);
    if forall p ∈ correct, (p, _) ∈ dset:
        trigger <uconsPropose, view.id + 1, correct, dset>;

upon event <uconsDecide, view_id, view_members, view_dset> do:
    forall (p, mset) ∈ view_dset such that p ∈ view_members do:
        forall (src, m) ∈ mset such that m ∉ delivered do:
            delivered := delivered ∪ {m};
            trigger <vsDeliver, src, m>;
    view := (view_id, view_members);
    flushing := false;
    blocked := false;
    dset := ∅;
    delivered := ∅;
    trigger <vsView, view>;
{% endhighlight %}

### Algorithm 3: Consensus-based Uniform VS
Using URB instead of BEB does not ensure uniformity. Therefore, a few changes are necessary.

As in algorithm 1 and 2, to `vsBroadcast`, we simply `bebBroadcast` and attach the view ID in a `Data` message. But now, when receiving these `bebBroadcast`, we mark the source as having acknowledged, and we acknowledge ourselves by re-broadcasting the message. We also add the message $m$ to the set of messages that have been broadcast in `pending`. This variable contains all messages that have been received in the current view. The set of processes that have acknowledged a message $m$ is stored in `ack[m]`.

We also maintain a variable `delivered` containing all messages ever `vsDeliver`ed. We can `vsDeliver` and add to `delivered` when all processes in the current view are contained in `ack[m]` (this is similar to what we did for URB).

When $\mathcal{P}$ detects a crash, we initiate a flush. This process first `bebBroadcast`s the contents of `pending` (which contains all messages from the current view). It's possible that not all messages in this set have been `vsDeliver`ed, so as soon as we've collected all other uncrashed processes' `pending`, we can initiate a consensus about the new view, and about the union of all the `pending` sets it has received.

When consensus decides, we `vsDeliver` all the `pending` messages in the consensus decision, and install the new view.

{% highlight dapseudo linenos %}
Implements:
    UniformViewSynchrony (uvs)
Uses:
    UniformConsensus (ucons)
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
Events:
    Request: <uvsBroadcast, m>: broadcasts m to all processes
    Indication: <uvsDeliver, src, m>: delivers message m broadcast by src
    Indication: <uvsView, V>: Installs a view V = (id, M)
    Indication: <uvsBlock>: requests that no new messages are 
                            broadcast temporarily, until next view is installed
    Request: <uvsBlockOk>: confirms that no new messages will be
                           broadcast until next view is installed
Properties:
    URB1, URB2, URB3, URB4
    Memb1, Memb2, Memb3, Memb4
    VS1

upon event <uvs, Init> do:
    view := (0, Π);
    correct := Π;
    flushing := false;
    blocked := false;
    pending := ∅;
    delivered := ∅;
    dset := ∅;
    ack[m] := ∅; # set of processes having ack'ed m

#############################
# Part 1: Data transmission #
#############################

upon event <uvsBroadcast, m> and (not blocked) do:
    pending := pending ∪ {(self, m)};
    # do not vsDeliver to self yet!
    trigger <bebBroadcast, [Data, view.id, self, m]>;

upon event <bebDeliver, sender, [Data, view_id, src, m]> and (not blocked) do:
    if view.id = view_id:
        ack[m] := ack[m] ∪ {sender};
        if m ∉ pending:
            pending := pending ∪ {(src, m)};
            trigger <bebBroadcast, [Data, view.id, src, m]>; # ack! 

# When all processes have acked a pending, undelivered message:
upon exists (src, m) ∈ pending 
  such that (view.members ⊆ ack[m]) and (m ∉ delivered) do:
    delivered := delivered ∪ {m};
    trigger <uvsDeliver, src, m>;

#######################
# Part 2: View change #
#######################

upon event <crash, p> do:
    correct := correct \ {p};
    if not flushing:
        flushing := true;
        trigger <uvsBlock>;

upon event <uvsBlockOk> do:
    blocked := true;
    trigger <bebBroadcast, [DSET, view.id, pending]>;

upon event <bebDeliver, src, [DSET, view_id, m_set]> do:
    dset := dset ∪ (src, m_set);
    if forall p ∈ correct, (p, _) ∈ dset:
        trigger <uconsPropose, view.id + 1, correct, dset>;

upon event <uconsDecide, view_id, view_members, view_dset> do:
    forall (p, mset) ∈ view_dset such that p ∈ view_members do:
        forall (src, m) ∈ mset such that m ∉ delivered do:
            delivered := delivered ∪ {m};
            trigger <uvsDeliver, src, m>;
    view := (view_id, view_members);
    flushing := false;
    blocked := false;
    dset := ∅;
    pending := ∅;
    delivered := ∅;
    trigger <uvsView, view>;
{% endhighlight %}

## Shared Memory (SM)
In this section, we'll take a look at shared memory through a series of distributed algorithms that enable distributed data storage through read and write operations. These shared memory abstractions are called *registers*, since they resemble one.

The variations we'll look at vary in the number of processes that can read or write. Specifically, we'll look at:

- $(1, N)$ regular register
- $(1, 1)$ atomic register
- $(1, N)$ atomic register

The tuple notation above represents the supported number of writers and readers, respectively, so $(1, N)$ means one process can write, and $N$ can read. As we'll see, the difference between regular and atomic registers lies in the concurrency guarantees that they offer.

### (1, N) Regular register
This register assumes only one writer, but an arbitrary number of readers. This means that one specific process $p$ can write, but any process (including $p$) can read.

#### Properties
A (1, N) regular register provides the following properties:

- **ONRR1 Termination**: if a correct process invokes an operation, then the operation eventually completes
- **ONRR2 Validity**:
    + Any read not concurrent with a write returns the last value written
    + Reads concurrent with a write return the last value written *or* the value concurrently being written

A note about ONRR2: if the writer crashes, the failed write is considered to be concurrent with all concurrent and future reads

Therefore, a read after a failed write can return the value that was supposed to be written, or the last value written before that.

In any case, reads always return values that have been, are being, or have been attempted to be written. In other words, read values can't be created out of thin air, they must come from somewhere.

#### Algorithm 1: fail-stop with perfect failure detection
Let's take a look at how we can implement this with a message passing model. The following fail-stop algorithm is fairly simple. It uses a perfect failure detector (eventually perfect would not be enough).

To read, the algorithm simply returns the locally stored value. To write, it `bebBroadcast`s a `Write` message with the new value. Other processes can acknowledge this with a PL, and update the value (including the process that is being written to, as it also broadcasts the `Write` to itself). Once every process has ack'ed, we can complete the write operation by triggering `<onrrWriteReturn>`.

{% highlight dapseudo linenos %}
Implements:
    (1, N)-RegularRegister (onrr)
Uses:
    BestEffortBroadcast (beb)
    PerfectLinks (pp2p)
    PerfectFailureDetector (P)
Events:
    Request: <onrrRead>: invokes a read on the register
    Request: <onrrWrite, v>: invokes a write with value v on the register
    Indication: <onrrReadReturn, v>: completes a read, returns v
    Indication: <onrrWriteReturn>: completes a write on the register
Properties:
    ONRR1, ONRR2

upon event <onrr, Init> do:
    val := nil;    # register value
    correct := Π;  # set of correct processes 
    acked := ∅;    # set of processes that have ACK'ed the write

upon event <crash, p> do:
    correct := correct \ {p};

upon event <onrrRead> do:
    trigger <onrrReadReturn, val>;

upon event <onrrWrite, v> do:
    trigger <bebBroadcast [Write, v]>;

upon event <bebDeliver, src, [Write, v]> do:
    val := v;
    trigger <plSend, src, ACK>;

upon event <plDeliver, src, ACK> do:
    acked := acked ∪ {src};

upon correct ⊆ acked do:
    acked := ∅;
    trigger <onrrWriteReturn>;
{% endhighlight %}

The above algorithm is correct, as:

- **ONRR1 Termination**
    + ATTA, all reads are local and eventually return, so termination for reads is trivial.
    + ATTA, writes eventually return, because and any process that doesn't send back an ack crashes, and any process that crashes is detected. ATTA, both cases are handled, so we will eventually return. This is proven by:
        * PFD1, the strong completeness property of $\mathcal{P}$
        * PL1, the reliable delivery of the perfect link channels
- **ONRR2 Validity**:
    + In the absence of concurrent or failed operation, a read returns the last value written. To prove this, assume that a `write(x)` terminates, and no other `write` is invoked.
    
    By PFD2 (strong accuracy of $\mathcal{P}$), the value of the register at all processes that didn't crash is `x`. Any subsequent `read()` at process $p$ returns the value at $p$, which is the last written value. 

    + A read returns the value concurrently written or last value written. This should be fairly clear ATTA, but the book has a more detailed proof.

Since we used PFD2 of $\mathcal{P}$ in the above proof, we need a perfect failure detector. Without that, we may violate the ONRR2 validity property of the register. 

#### Algorithm 2: Fail-silent without failure detectors
Under the assumption that a majority of the processes are correct, we can actually implement (1, N) regular registers without failure detectors. This majority assumption is needed for this algorithm, even if we were to add an eventually perfect failure detector.

The key idea is that the writer process $p$ and all reader processes should use a set of *witnesses* that keep track of the most recent value of the register. Each set of witnesses must overlap: this forms *quorums* (defined as a collection of sets so that no two sets' intersection is empty). In our case, we consider a very simple form of quorum, namely a majority.

Like the previous algorithm, we store the register value in `val`; in addition to it, we also store a timestamp `ts`, counting the number of write operations. 

When the writer process $p$ writes, it increments the timestamp, and `bebBroadcast`s a `Write` message to all processes. The processes can adopt the value by storing it locally if the timestamp is larger than the current one, and acknowledging through a PL. Once $p$ has such an acknowledgment from a majority of processes, it completes the write.

To read a value, the reader `bebBroadcast`s a `Read` message to all processes. Every process replies through a PL with its current value and timestamp. Once the reader has replies from a majority of processes, it selects the one with the highest timestamp, which ensures that the last value written is returned.

{% highlight dapseudo linenos %}
Implements:
    (1, N)-RegularRegister (onrr)
Uses:
    BestEffortBroadcast (beb)
    PerfectLinks (pp2p)
Events:
    Request: <onrrRead>: invokes a read on the register
    Request: <onrrWrite, v>: invokes a write with value v on the register
    Indication: <onrrReadReturn, v>: completes a read, returns v
    Indication: <onrrWriteReturn>: completes a write on the register
Properties:
    ONRR1, ONRR2

upon event <onrr, Init> do:
    val := nil;    # register value
    ts := 0;       # register timestamp (counts number of writes)
    write_ts := 0; # timestamp of the pending write
    acks := 0;     # number of processes having ack'ed pending write
    read_id := 0;  # id of the currently pending read operation
    readlist := [nil] * N; # replies from the Read message

##################
# Part 1: Writes #
##################

upon event <onrrWrite, v> do:
    write_ts := write_ts + 1;
    acks := 0;
    trigger <bebBroadcast, [Write, write_ts, v]>;

upon event <bebDeliver, src, [Write, value_ts, value]> do:
    if value_ts > ts:
        ts := value_ts;
        val := value;
    trigger <pp2pSend, src, [ACK, value_ts]>;

upon event <pp2pDeliver, q, [ACK, value_ts]> such that value_ts = write_ts do:
    acks := acks + 1;
    if acks > N/2:
        acks := 0;
        trigger <onrrWriteReturn>

#################
# Part 2: Reads #
#################

upon event <onrrRead> do:
    read_id := read_id + 1;
    readlist := [nil] * N;
    trigger <bebBroadcast, [Read, rid]>;

upon event <bebDeliver, src, [Read, read_id]> do:
    trigger <pp2pSend, src, [Value, read_id, ts, val]>;

upon event <pp2pDeliver, q, [Value, read_id, read_ts, read_val]> do:
    readlist[q] := (read_ts, read_val);
    if size(readlist) > N/2:
        v := highest_timestamp_val(readlist);
        readlist := [nil] * N;
        trigger <onrrReadReturn, v>;
{% endhighlight %}

### (1, N) Atomic register
#### Properties
With regular registers, the guarantees we gave about reads that are concurrent to writes are a little weak. For instance, suppose that a writer $p$ invokes `write(v)`. The specification allows for concurrent reads to return `nil` then `v` then `nil` again, and so on, until the write is done or if the writer crashes while writing, this can go on forever. An **atomic register** prevents such behavior.

An atomic register provides an additional guarantee compared to a regular register: *ordering*. The guarantee is that even when there is concurrency and failures, the execution is *linearizable*, i.e. it is equivalent to a sequential and failure-free execution. This means that we can now think of the write happening at a single atomic point in time, sometime during the execution of the write.

This means that both of the following are true:

- Every failed write operation appears to be either complete or not to have been invoked at all
- Every complete operation appears to have been executed at some instant between its invocation and the reply event.

Roughly speaking, atomic registers prevent "old" values from being read by a process $q$ once a newer value has been read by $s$. The properties are:

- **ONAR1. Termination = ONRR1**
- **ONAR2. Validity = ONRR2**
- **ONAR3. Ordering**: If a read returns a value $v$ and a subsequent read returns a value $w$, then the write of $w$ does not precede the write of $v$

#### From (1, N) regular to (1, 1) atomic
First, let's convert (1, N) regular into (1, 1) atomic. As before, we'll keep a timestamp for writes, which we increment every time we write. But this time, we'll also introduce a timestamp for reads, which contains the highest write-timestamp it has read so far. This allows the reader to avoid returning old values once it has read a new one.

{% highlight dapseudo linenos %}
Implements:
    (1, 1)-AtomicRegister (ooar)
Uses:
    (1, N)-RegularRegister (onrr)

upon event <ooar, Init> do:
    val := nil;      # register value
    ts := 0;         # reader timestamp
    write_ts := nil; # writer timestamp

upon event <ooarWrite, v> do:
    write_ts := write_ts + 1;
    trigger <onrrWrite, (write_ts, v)>;

upon event <onrrWriteReturn> do:
    trigger <ooarWriteReturn>;

upon event <ooarRead> do:
    trigger <onrrRead>;

upon event <onrrReadReturn, (value_ts, value)> do:
    if value_ts > ts:
        val := value;
        ts := value_ts;
    trigger <ooarReadReturn, val>;
{% endhighlight %}

#### Algorithm 1: From (1, 1) atomic to (1, N) atomic
We can construct a (1, N) atomic register from $N^2$ underlying (1, 1) atomic registers. These are organized in a $N \times N$ matrix, with instances called 
$\text{ooar}[q][r]$ for $q \in \Pi$ and $r \in \Pi$.

Register instance $\text{ooar}[q][r]$ is used to inform process $q$ about the last value read by reader $r$. This establishes a sort of one-way communication channel, where $r$ writes to the register, and $q$ reads from it.

The writer $p$ places written values into registers $\text{ooar}[q][p]$, so that all readers $q\in\Pi$ can read. This means that every read and write requires $N$ registers to be updated.

{% highlight dapseudo linenos %}
Implements:
    (1, N)-AtomicRegister (onar)
Uses:
    (1, 1)-AtomicRegister (multiple instances ooar[][])
Events:
    Request: <onarRead>: invokes a read on the register
    Request: <onarWrite, v>: invokes a write with value v on the register
    Indication: <onarReadReturn, v>: completes a read, returns v
    Indication: <onarWriteReturn>: completes a write on the register
Properties:
    ONAR1, ONAR2, ONAR3

upon event <onar, Init> do:
    ts := 0;          # timestamp
    acks := 0;        # number of updated registers in write and read
    writing := false; # whether we are currently reading or writing
    readval := nil;   # last read value
    readlist := [nil] * N; # reads from all other processes
    forall q ∈ Π, r ∈ Π:
        ooar[q][r] = new ooar with writer r, reader q;

# To write, write to all q processes through (1, 1)-atomic registers
upon event <onarWrite, v> do:
    ts := ts + 1;
    writing := true;
    forall q ∈ Π:
        trigger <ooar[q][self]Write, (ts, v)>;

# When all (1, 1)-atomic writes are done, WriteReturn or ReadReturn
upon event <ooar[q][self]WriteReturn> do:
    acks := acks + 1;
    if acks = N:
        acks := 0;
        if writing:
            trigger <onarWriteReturn>;
            writing := false;
        else:
            trigger <onarReadReturn, readval>;

# To read, read from all r processes through (1, 1)-atomic registers
upon event <onarRead> do:
    forall r ∈ Π do:
        trigger <ooar[self][r]Read>;

# When all reads are done, select the highest timestamp value,
# and write to all q processes
upon event <ooar[self][r]ReadReturn, (value_ts, value)> do:
    readlist[r] := (value_ts, value);
    if size(readlist) = N:
        (maxts, readval) := highest_timestamp_pair(readlist);
        readlist := [nil] * N;
        forall q ∈ Π do:
            trigger <ooar[q][self]Write, (maxts, readval)>;
{% endhighlight %}

#### Algorithm 2: Read-impose Write-all (1, N) atomic
We assume a fail-stop model, where any number of processes can crash, channels are reliable, and failure detection is perfect. We won't go into the algorithm in detail, but its signature is:

{% highlight dapseudo linenos %}
Implements:
    (1, N)-AtomicRegister (onar)
Uses:
    BestEffortBroadcast (beb)
    PerfectLinks (pp2p)
    PerfectFailureDetector (P)
Events:
    Request: <onarRead>: invokes a read on the register
    Request: <onarWrite, v>: invokes a write with value v on the register
    Indication: <onarReadReturn, v>: completes a read, returns v
    Indication: <onarWriteReturn>: completes a write on the register
Properties:
    ONAR1, ONAR2, ONAR3
{% endhighlight %}




{% details Guest Lectures %}

## Guest Lecture 1: Mathematically robust distributed systems
Some bugs in distributed systems can be very difficult to catch (it could involve long and costly simulation; with $n$ computers, it takes time $2^n$ to simulate all possible cases), and can be very costly when it happens.

The only way to be sure that there are no bugs is to *prove* it formally and mathematically.

### Definition of the distributed system graph

Let $G(V, E)$ be a graph, where $V$ is the set of process nodes, and $E$ is the set of channel edges connecting the processes. 

Two nodes $p$ and $q$ are **neighbors** if and only if there is an edge $\left\\{ p, q \right\\} \in E$.

Let $X \subseteq V$ be the set of **crashed nodes**. The other nodes are **correct nodes**.

We'll define the **path** as the sequence of nodes $(p_1, p_2, \dots, p_n)$ such that $\forall i \in \left\\{i, \dots, n-1\right\\}$, $p_i$ and $p_{i+1}$ are neighbors.

Two nodes $p$ and $q$ are **connected** if we have a path $(p_1, p_2, \dots, p_n)$ such that $p_1 = p$ and $p_2 = q$. 

They are **n-connected** if there are $n$ disjoint paths connecting them; two paths $A = \left\\{ p_1, \dots, p_n \right\\}$ and $B = \left\\{ p_1, \dots, p_n \right\\}$ are disjoint if $A \cap B = \left\\{ p, q \right\\}$ (i.e. $p$ and $q$ are the two only nodes in common in the path).

The graph is **k-connected** if, $\forall \left\\{ p, q \right\\} \subseteq V$ there are $k$ disjoint paths between $p$ and $q$.

### Example on a simple algorithm

Each node $p$ holds a message $m_p$ and a set $p.R$. The goal is for two nodes $p$ and $q$ to have $(p, m_p) \in q.R$ and $(q, m_q) \in p.R$; that is, they want to exchange messages, to *communicate reliably*. The algorithm is as follows:

{% highlight python linenos %}
for each node p:
  initially:
    send (p, m(p)) to all neighbors

  upon reception of of (v, m):
    add (v, m) to p.R
    send (v, m) to all neighbors
{% endhighlight %}

#### Reliable communication

Now, let's prove that if two nodes $p$ and $q$ are connected, then they communicate reliably. We'll do this by induction; formally, we'd like to prove that the proposition $\mathcal{P}_k$, defined as "$p_k \text{ receives } (p, m_p)$", is true for $k\in \left\\{ 1, \dots, n \right\\}$. 

- **Base case**
  
  According to the algorithm, $p=p_1$ initially sends $(p, m_p)$ to $p_2$. So $p_2$ receives $(p, m_p)$ from $p_1$, and $\mathcal{P}_2$ is true.

- **Induction step**
  
  Suppose that the induction hypothesis $\mathcal{P}$ is true for $k \in \left\\{2, \dots, n-1 \right\\}$.

  Then, according to the algorithm, $p_k$ sends $(p, m_p)$ to $p_{k+1}$, meaning that $p_{k+1}$ receives $(p, m_p)$ from $p_k$, which means that $\mathcal{P}_{k+1}$ is true.

Thus $\mathcal{P}_k$ is true.

### Robustness property
If at most $k$ nodes are crashed, and the graph is $(k+1)$-connected, then all correct nodes **communicate reliably**.

We prove this by contradiction. We want to prove $\mathcal{P}$, so let's suppose that the opposite, $\bar{\mathcal{P}}$ is true; to prove this, we must be able to conclude that the graph is $(k+1)$-connected, but there are 2 correct nodes $p$ and $q$ that *do not* communicate reliably. Hopefully, doing so will lead us to a paradoxical conclusion that allows us to assert $\mathcal{P}$.

As we are $(k+1)$-connected, there exists $k+1$ paths $(P_1, P_2, \dots, P_{k+1})$ paths connecting any two nodes $p$ and $q$. We want to prove that $p$ and $q$ do not communicate reliably, meaning that all paths between them are "cut" by at least one crashed node. As the paths are disjoint, this requires at least $k+1$ crashed nodes to cut them all.

This is a contradiction: we were working under the assumption that $k$ nodse were crashed, and proved that $k+1$ nodes were crashed. This disproves $\bar{\mathcal{P}}$ and proves $\mathcal{P}$.

### Random failures
Let's assume that $p$ and $q$ are connected by a single path of length 1, only separated by a node $n$. If each node has a probability $f$ of crashing, then the probability of communicating reliably is $1-f$.

Now, suppose that the path is of length $n$; the probability of communicating reliably is the probability that none of the nodes crashing; individually, that is $1-f$, so for the whole chain, the probability is $(1-f)^n$.

However, if we have $n$ paths of length 1 (that is, instead of setting them up serially like previously, we set them up in parallel), the probability of not communicating reliably is that of all intermediary nodes crashing, which is $f^n$; thus, the probability of actually communicating reliably is $1-f^n$.

If our nodes are connecting by $n$ paths of length $m$, the probability of not communicating reliably is that of all lines being cut. The probability of a single line being cut is $1 - (1 - f)^m$. The probability of any line being cut is one minus the probability of no line being cut, so the final probability is $1 - (1 - (1 - f)^m)^n$.


### Example proof
Assume an infinite 2D grid of nodes. Nodes $p$ and $q$ are connected, with the distance in the shortest path being $D$. What is the probability of communicating reliably when this distance tends to infinity?

$$
\lim_{D \rightarrow \infty} = \dots
$$

First, let's define a sequence of grids $G_k$. $G_0$ is a single node, $G_{k+1}$ is built from 9 grids $G_k$.

$G_{k+1}$ is **correct** if at least 8 of its 9 grids are correct.

We'll introduce the concept of a "meta-correct" node; this is not really anything official, just something we're making up for the purpose of this proof. Consider a grid $G_n$. A node $p$ is "meta-correct" if:

- It is in a correct grid $G_n$, and
- It is in a correct grid $G_{n-1}$, and
- It is in a correct grid $G_{n-2}$, ...

For the sake of this proof, let's just admit that all meta-correct nodes are connected; if you take two nodes $p$ and $q$ that are both meta-correct, there will be a path of nodes connecting them.

#### Step 1
If $x$ is the probability that $G_k$ is correct, what is the probability $P(x)$ that $G_{k+1}$ is correct?

$G_{k+1}$ is built up of 9 subgrids $G_k$. Let $P_i$ be the probability of $i$ nodes failing; the probability of $G_k$ being correct is the probability at most one subgrid being incorrect.

$$
\begin{align}
P_0 & = x^9 \\
P_1 & = 9(1-x)x^8 \\
P(x) & = P_0 + P_1 = x^9 + 9(1-x)x^8 \\
\end{align}
$$

#### Step 2
Let $\alpha = 0.9$, and $z(x) = 1 + \alpha (x-1)$. 

We will admit the following: if $x \in [0.99, 1]$ then $z(x) \le P(x)$.

Let $P_k$ be the result of applying $P$ (as defined in step 1) to $1-f$, $k$ times: $P_k = P(P(P(\dots P(1-f))))$. We will prove that $P_k \ge 1 - \alpha^k, \forall k > 0$, by induction:

- **Base case**: $P_0 = 1-f = 0.99$ and $1-\alpha^0 = 1-1 = 0$, so $P_0 \ge 1-\alpha^0$.
- **Induction step**:
  
  Let's suppose that $P_k \ge 1-\alpha^k$. We want to prove this for $k+1$, namely $P_{k+1} \ge 1 - \alpha^{k+1}$.

  $$
  P_{k+1} \ge P(P_k) \ge z(P_k) \ge z(1 - \alpha^k) \\
  P_{k+1} \ge 1 + \alpha(1 - \alpha^k - 1) \\
  P_{k+1} \ge 1 - \alpha^{k+1}
  $$

This proves the result that $\forall k, P_k \ge 1 - \alpha^k$.

#### Step 3
Todo.


## Guest lecture 2: Byzantine failures
So far, we've only considered situations in which nodes crash. In this section, we'll consider a new case: the one where nodes go "evil", a situation we call **byzantine failures**.

Suppose that our nodes are arranged in a grid. $S$ sends a message $m$ to $R$ by broadcasting $(S, m)$. With a simple broadcast algorithm, we just broadcast the message to the neighbor, which may be a byzantine node $B$ that alters the message before rebroadcasting it. Because $B$ can simply do that, we see that this simple algorithm is not enough to deal with byzantine failures. 

To deal with this problem, we'll consider some other algorithms. 

First, consider the case where there are $n$ intermediary nodes between $S$ and $R$ (this is not a daisy chain of nodes, but instead just $m$ paths of length 2 between $S$ and $R$). We assume that $S$ and $R$ are both correct (non-Byzantine) nodes, but the intermediary nodes may be.

For this algorithm, we define $k = \frac{n}{2} - 1$ if $n$ is even, and $k = \frac{n - 1}{2}$ if it is odd. The idea is to have $k+1$ be the smallest number of nodes to have a majority among the $n$ intermediary nodes. Let's also assume that $R$ has a set $\Omega$ that acts as its memory, and a variable $x$, initially set to $x = 0$. Our goal is to have $x = m$.

$S$ simply sends out the message $m$ to its neighbors. The intermediary nodes forward messages that they receive to $R$. Finally, when $R$ receives a message $m$ from $p$, it adds it to the set $\Omega$. When there are $k+1$ nodes in the set, it can set $x = m$ (essentially, deliver the message).

We'll prove properties on this. The main point to note is that these proofs make no assumption on the potentially Byzantine nodes.

- **Safety**: if the number of Byzantine nodes $f$ is $f \le k$, then $x = 0$ or $x = m$.
  
  The proof is by contradiction. Let's suppose that the opposite is true, i.e. that $x = m'$, where $m' \ne m$. Then, according to the algorithm, this means that there must be $k+1$ nodes such that $\forall i \in \left\\{ 1, \dots, k+1 \right\\}$, we have $(p_i, m) \in \Omega$. But according to the algorithm, there are only two reasons for such a message being in the set; that is, either $p_i$ operates in good faith, receiving $m'$ from $S$, or it operates in bad faith, being a Byzantine node. The first case is impossible, as $S$ is correct. The alternative case can only happen if there are $k+1$ byzantine nodes, which is also impossible (since by assumption $f \le k$. This contradiction proves the safety property. 
  
- **Liveness**: if $f \le k$, we eventually have $x = m$.
  
  To prove this, we first define a set of $k+1$ correct (non-Byzantine) intermediary nodes. These nodes all receive $m$ from $S$, send it to $R$, which places it in $\Omega$. Eventually, we'll have $k+1$ nodes in the set, and then $x=m$.
  
  By the liveness and safety property, we know that initially $x=0$, eventually $x=m$, and we never have $x=m'$.
  
- **Optimality**: if $f \ge k + 1$, it is impossible to ensure the safety property.
  
  Assume we have $k+1$ Byzantine nodes sending $m'$ to $R$. According to the algorithm, we get $x = m'$, so no safety.
  
  We can conclude that we can tolerate at most $k$ Byzantine nodes.

But here we only considered the specific case of length 2 paths. Let's now consider the general case, which is the $(2k+1)$ connected graph. In this case, we consider any graph, and each node needs to broadcast a message $m_p$. Every node has a set $p_R$ to send messages, and a set $p_X$ of received messages.

The algorithm is as follows. Initially, the nodes send $(p, \emptyset, m_p)$ to their neighbors. When a node $p$ receives $(u, \Omega, m)$ from a neighbor $q$, with $p\notin\Omega$ and $q\notin\Omega$, the node sends $(u, \Omega\cup u, m)$ to its neighbors, and add that to $p_X$. When there exists a node $q$, a message $m$ and $k+1$ sets $\Omega_1, \dots, \Omega_{k+1}$ such that $\bigcup_{i=1}^{k+1} \Omega_i = \left\\{ q \right\\}$, and we have $k+1$ message in $p_X$, we can add $(q, m)$ to $p_R$.

We'll prove the following properties under the hypotheses that we have at most $k$ Byzantine nodes (a minority), and that the graph is connected (otherwise we couldn't broadcast messages between the nodes)

- **Safety**: If $p$ and $q$ are two correct nodes, we never have $(p, m_p')\in q_R$ (where $m_p' \ne m_p$). In other words, no fake messages are accepted.
  
  The proof is by contradiction, in which we use induction to arrive to a contradictory conclusion. We'll try to prove the opposite of our claim, namely that there are two correct nodes $p$ and $q$ such that $(p, m_p') \in q_R$.
  
  According to our algorithm, we have $k+1$ disjoint sets whose intersection is $p$, and $k+1$ elements $(p, \Omega_i, m) \in q_X$.
  
  To prove this, we'll need to prove a sub-property: that each set $\Omega_i$ contains at least one byzantine node. We prove this by contradiction. We'll suppose the opposite, namely that $\Omega_i$ contains no byzantine node (i.e. that they are all correct). I won't write down the proof of this, but it's in the lecture notes if ever (it's by induction).

{% enddetails %}
