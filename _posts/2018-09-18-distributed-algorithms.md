---
title: CS-451 Distributed Algorithms
description: "My notes from the CS-451 Distributed Algorithms course given at EPFL, in the 2018 autumn semester (MA1)"
edited: true
note: true
---

* TOC
{:toc}

⚠ *Work in progress*

<!-- More -->

## Introduction
- [Website](http://dcl.epfl.ch/site/education/da)
- Course follows the book *Introduction to Reliable (and Secure) Distributed Programming*
- Final exam is 60%
- Projects in teams of 2-3 are 40%
  - The project is the implementation of a blockchain
  - Send team members to matej.pavlovic@epfl.ch
- No midterm

Distributed algorithms are between the application and the channel. 

We have a few commonly used abstractions:

- **Processes** abstract computers
- **Channels** abstract networks
- **Failure detectors** abstract time

When defining a problem, there are two important properties that we care about:

- **Safety** states that nothing bad should happen
- **Liveness** states that something good should happen

Safety is trivially implemented by doing nothing, so we also need liveness to make sure that the correct things actually happen.

### Links
Two nodes can communicate through a link by passing messages. However, this message passing can be faulty: it can drop messages or repeat them. How can we ensure correct and reliable message passing under such conditions?

A link has two basic types of events:

- Send
- Deliver

#### Fair loss link (FLL)
A fair loss link is a link that may lose or repeat some packets. This is the weakest type of link we can assume. In practice, it corresponds to UDP.  

Deliver can be thought of as a reception event on the receiver end. The terminology used here ("deliver") implies that the link delivers to the client, but this can equally be thought of as the client receiving from the link.

For a link to be considered a fair-loss link, we must respect the following three properties:

- **Fair loss**: if the sender sends infinitely many times, the receiver must deliver infinitely many times. This does not guarantee that all messages get through, but at least ensures that some messages get through.
- **No creation**: every delivery must be the result of a send; no message must be created out of the blue. 
- **Finite duplication**: a message can only be repeated by the link a finite number of times.

#### Stubborn link
A stubborn link is one that stubbornly delivers messages; that is, it ensures that the message is received, with no regard to performance.

A stubborn link can be implemented with a FLL as follows:

{% highlight python linenos %}
upon send(m):
  while True:
    FLL.send(m)

upon FLL.deliver(m):
  trigger deliver(m)
{% endhighlight %}

The above uses generic pseudocode, but the syntax we'll use in this course is as follows:

{% highlight python linenos %}
Implements: SubbornLinks (sp2p)
Uses: FairLossLinks (flp2p)

upon event <sp2pSend, dest, m> do
  while True do:
    trigger <flp2p, dest, m>;

upon event <flp2pDeliver, src, m> do
  trigger <sp2pDeliver, src, m>;
{% endhighlight %}

Note that this piece of code is meant to sit between two abstraction levels; it is between the channel and the application. As such, it receives sends from the application and forwards them to the link, and receives delivers from the link and forwards them to the application. 

It must respect the interface of the underlying FLL, and as such, only specifies send and receive hooks.

#### Perfect link 
Here again, we respect the send/deliver interface. The properties are:

- **Validity** or reliable delivery: if both peers are correct, then every message sent is eventually delivered 
- **No duplication**
- **No creation**

This is the type of link that we usually use: TCP is a perfect link, although it also has more guarantees (notably on message ordering, which this definition of a perfect link does not have). TCP keeps retransmitting a message stubbornly, until it gets an acknowledgement, which means that it can stop transmitting. Acknowledgements aren't actually needed *in theory*, it would still work without them, but we would also completely flood the network, so acknowledgements are a practical consideration for performance; just note that the theorists don't care about them.

{% highlight python linenos %}
Implements: PerfectLinks (pp2p)
Uses: StubbornLinks (sp2p)

upon event <Init> do delivered := Ø;

upon event <pp2pSend, dest, m> do
  trigger <sp2pSend, dest, m>;

upon event <sp2pDeliver, src, m> do
  if m not in delivered then
    trigger <pp2pDeliver, src, m>;
    add m to delivered;
{% endhighlight %}



### Impossibility of consensus
Suppose we'd like to compute prime numbers on a distributed system. Let *P* be the producer of prime numbers. Whenever it finds one, it notifies two servers, *S1* and *S2* about it. A client *C* may request the full list of known prime numbers from either server.

As in any distributed system, we want the servers to behave as a single (abstract) machine.

#### Solvable atomicity problem
*P* finds 1013 as a new prime number, and sends it to *S1*, which receives it immediately, and *S2*, which receives it after a long delay. In the meantime, before both servers have received the update, we have an atomicity problem: one server has a different list from the other. In this time window, *C* will get different results from *S1* (which has numbers up to 1013) and *S2* (which only has numbers up to 1009, which is the previous prime). 

A simple way to solve this is to have *C* send the new number (1013) to the other servers; if it requested from *S1* it'll send the update to *S2* as a kind of write back, to make sure that *S2* also has it for the next request. We haven't strictly defined the problem or its requirements, but this may need to assume a link that guarantees delivery and order (i.e. TCP, not UDP).

#### Unsolvable atomicity problem
Now assume that we have two prime number producers *P1* and *P2*. This introduces a new atomicity problem: the updates may not reach all servers atomically in order, and the servers cannot agree on the order. 

This is **impossible** to solve; we won't prove it, but universality of Turing is lost (unless we make very strong assumptions). This is known as the [*impossibility of consensus*](https://groups.csail.mit.edu/tds/papers/Lynch/jacm85.pdf).

### Failure detection
A **failure detector** is a distributed oracle that provides processes with suspicions about crashed processes. There are two kinds of failure detectors, with the following properties

- **Perfect**
    + **Strong completeness**: eventually, every process that crashed is permanently suspected by every correct process
    + **Strong accuracy**: no process is suspected before it crashes
- **Eventually perfect**
    + **Strong completeness**
    + **Eventual strong accuracy**: eventually, no correct process is ever suspsected

An eventually perfect detector may make mistakes and may operate under a delay. But eventually, it will tell us the truth.

A failure detector can be implemented by the following algorithm:

1. Processes periodically send heartbeat messages
2. A process sets a timeout based on worst case round trip of a message exchange
3. A process suspects another process has failed if it timeouts that process
4. A process that delivers a message from a suspected process revises its suspicion and doubles the time-out

Failure detection algorithms are all designed under certain **timing assumptions**. The following timing assumptions are possible:

- **Synchronous**
    + **Processing**: the time it takes for a process to execute is bounded and known.
    + **Delays**: there is a known upper bound limit on the time it takes for a message to be received
    + **Clocks**: the drift between a local clock and the global, real-time clock is bounded and known
- **Eventually synchronous**: the timing assumptions hold eventually
- **Asynchronous**: no assumptions

These 3 possible assumption levels mean that the world is divised into 3 kinds of failure algorithms. The algorithm above is based on the eventually synchronous assumption (I think?).

{% details Not exam material %}
## Mathematically robust distributed systems
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
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}

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

{% enddetails %}

## Reliable broadcast
Broadcast is useful for some applications with pubsub-like mechanisms, where the subscribers might need some reliability guarantees from the publisher (we sometimes say quality of service QoS). 

### Best-effort broadcast
Best-effort broadcast (beb) has the following properties:

- **BEB1 Validity**: if $p_i$ and $p_j$ are correct then every message broadcast by $p_i$ is eventually delivered by $p_j$
- **BEB2 No duplication**: no message is delivered more than once
- **BEB3 No creation**: no message is delivered unless it was broadcast

The broadcasting machine may still crash in the middle of a broadcast, where it hasn't broadcast the message to everyone yet. It offers no guarantee against that.

{% highlight python linenos %}
Implements: BestEffortBroadcast (beb)
Uses: PerfectLinks (pp2p)

Upon event <bebBroadcast, m> do:
    forall pi in S, the set of all nodes in the system, do:
        trigger <pp2pSend, pi, m>

Upon event <pp2pDeliver, pi, m> do:
    trigger <bebDeliver, pi, m>
{% endhighlight %}

This is not the most efficient algorithm, but we're not concerned about that. We just care about whether it's correct, which we'll sketch out a proof for:

- **Validity**: By the validity property of perfect links and the very facts that:
    + the sender sends the message to all
    + every correct process that `pp2pDelivers` delivers a message to, `bebDelivers` it too
- **No duplication**: by the no duplication property of perfect links
- **No creation**: by the no creation property of perfect links

### Reliable broadcast
Reliable broadcast has the following properties:

- **RB1 Validity**: if $p_i$ and $p_j$ are correct then every message broadcast by $p_i$ is eventually delivered by $p_j$
- **RB2 No duplication**: no message is delivered more than once
- **RB3 No creation**: no message is delivered unless it was broadcast
- **RB4 Agreement**: for any message $m$, if a **correct** process delivers $m$, then every correct process delivers $m$

Notice that RB has the same properties as best-effort, but also adds a guarantee RB4: even if the broadcaster crashes in the middle of a broadcast and is unable to send to other processes, we'll honor the agreement property. This is done by distinguishing receiving and delivering; the broadcaster may not have sent to everyone, but in that case, reliable broadcast makes sure that no one delivers.

Note that a process may still deliver and crash before others deliver; it is then incorrect, and we have no guarantees that the message will be delivered to others.

{% highlight python linenos %}
Implements: ReliableBroadcast (rb)
Uses:
    BestEfforBroadcast (beb)
    PerfectFailureDetector (P)

Upon event <Init> do:
    delivered := Ø
    correct := S
    forall pi in S do:
        from[pi] := Ø

Upon event <rbBroadcast, m> do:   # application tells us to broadcast
    delivered := delivered U {m}
    trigger <rbDeliver, self, m>            # deliver to itself
    trigger <bebBroadcast, [Data, self, m]> # broadcast to others using beb

Upon event <bebDeliver, pi, [Data, pj, m]> do:
    if m not in delivered:
        delivered := delivered U {m}
        trigger <rbDeliver, pj, m>
        if pi not in correct: # echo if sender not in correct
            trigger <bebBroadcast, [Data, pj, m]> 
        else:
            from[pi] := from[pi] U {[pj, m]}

Upon event <crash, pi> do:
    correct := correct \ {pi}
    forall [pj, m] in from[pi] do: # echo all previous messages from crashed pi
        trigger <bebBroadcast, [Data, pj, m]>
{% endhighlight %}

The idea is to echo all messages from a node that has crashed. From the moment we get the crash message from the oracle, we may have received messages from an actually crashed node, even though we didn't know it was crashed yet. This is because our failure detector is eventually correct, which means that the crash notification may eventually come. To solve this, we also send all the old messages.

We'll sketch a proof for the properties:

- **Validity**: as above
- **No duplication**: as above
- **No creation**: as above
- **Agreement**: Assume some correct process $p_i$ `rbDelivers` a message $m$ that was broadcast through `rbBroadcast` by some process $p_k$. If $p_k$ is correct, then by the validity property of best-effort broadcast, all correct processes will get the message through `bebDeliver`, and then deliver $m$ through `rebDeliver`. If $p_k$ crashes, then by the completeness property of the failure detector $P$, $p_i$ detects the crash and broadcasts $m$ with `bebBroadcast` to all. Since $p_i$ is correct, then by the validity property of best effort, all correct processes `bebDeliver` and then `rebDeliver` $m$. 

Note that the proof only uses the completeness property of the failure detector, not the accuracy. Therefore, the predictor can either be perfect or eventually perfect.

### Uniform reliable broadcast
Uniform broadcast satisfies the following properties:

- **URB1 Validity**: if $p_i$ and $p_j$ are correct then every message broadcast by $p_i$ is eventually delivered by $p_j$
- **URB2 No duplication**: no message is delivered more than once
- **URB3 No creation**: no message is delivered unless it was broadcast
- **URB4 Uniform agreement**: for any message $m$, if a process delivers $m$, then every correct process delivers $m$

We've removed the word "correct" in the agreement, and this changes everything. This is the strongest assumption, which guarantees that all messages are delivered to everyone, no matter their future correctness status.

The algorithm is given by:

{% highlight python linenos %}
Implements: uniformBroadcast (urb).
Uses:
    BestEffortBroadcast (beb).
    PerfectFailureDetector (P).

Upon event <Init> do:
    correct := S # set of correct nodes, initiated to all nodes
    delivered := forward := Ø # set of delivered and already forwarded messages
    ack[Message] := Ø   # set of nodes that have acknowledged Message

upon event <crash, pi> do:
    correct := correct \ {pi}

# before broadcasting, save message in forward
upon event <urbBroadcast, m> do:
    forward := forward U {[self,m]}
    trigger <bebBroadcast, [Data,self,m]>

# if I haven't sent the message, echo it
# if I've already sent it, don't do it again
upon event <bebDeliver, pi, [Data,pj,m]>:
    ack[m] := ack[m] U {pi}
    if [pj,m] not in forward:
        forward := forward U {[pj,m]};
        trigger <bebBroadcast, [Data,pj,m]>

# deliver the message when we know that all correct processes have delivered
# (and if we haven't delivered already)
upon event (for any [pj,m] in forward) can_deliver(m) and m not in delivered:
    delivered := delivered U {m}
    trigger <urbDeliver, pj, m>

def can_deliver(m):
    return correct ⊆ ack[m]
{% endhighlight %}

To prove the correctness, we must first have a simple lemma: if a correct process $p_i$ `bebDeliver`s a message $m$, then $p_i$ eventually `urbDeliver`s the message $m$.

This can be proven as follows: any process that `bebDeliver`s $m$ `bebBroadcast`s $m$. By the completeness property of the failure detector $P$, and the validity property of best-effort broadcasting, there is a time at which $p_i$ `bebDeliver`s $m$ from every correct process and hence `urbDeliver`s it.

The proof is then:

- **Validity**: If a correct process $p_i$ `urbBroadcast`s a message $m$, then $p_i$ eventually `bebBroadcast`s and `bebDeliver`s $m$. By our lemma, $p_i$ `urbDeliver`s it.
- **No duplication**: as best-effort
- **No creation**: as best-effort
- **Uniform agreement**: Assume some process $p_i$ `urbDeliver`s a message $m$. By the algorithm and the completeness *and* accuracy properties of the failure detector, every correct process `bebDeliver`s $m$. By our lemma, every correct process will `urbDeliver` $m$.

Unlike previous algorithms, this relies on perfect failure detection. But under the assumption that the majority of processes stay correct, we can do with an eventually perfect failure detector. To do so, we remove the crash event above, and replace the `can_deliver` method with the following:

{% highlight python linenos %}
def can_deliver(m):
    return len(ack[m]) > N/2
{% endhighlight %}

## Causal order broadcast

### Motivation
So far, we didn't consider ordering among messages. In particular, we considered messages to be independent. Two messages from the same process might not be delivered in the order they were broadcast. 

### Causality
The above means that **causality** is broken: a message $m_1$ that causes $m_2$ might be delivered by some process after $m_1$.

Let $m_1$ and $m_2$ be any two messages. $m_1\longrightarrow m_2$ ($m_1$ **causally precedes** $m_2$) if and only if:

- **C1 (FIFO Order)**: Some process $p_i$ broadcasts $m_1$ before broadcasting $m_2$
- **C2 (Causal Order)**: Some process $p_i$ delivers $m_1$ and then broadcasts $m_2$ 
- **C3 (Transitivity)**: There is a message $m_3$ such that $m_1 \longrightarrow m_3$ and $m_3 \longrightarrow m_2$.

The **causal order property (CO)** is given by the following: if any process $p_i$ delivers a message $m_2$, then $p_i$ must have delivered every message $m_1$ such that $m_1 \longrightarrow m_2$.

### Algorithm
We get reliable causal broadcast by using reliable broadcast, uniform causal broadcast using uniform reliable broadcast.

{% highlight python linenos %}
Implements: ReliableCausalOrderBroadcast (rco)
Uses: ReliableBroadcast (rb)

upon event <Init> do:
    delivered := past := Ø

upon event <rcoBroadcast, m> do:
    trigger <rbBroadcast, [Data, past, m]>
    past := past U {[self, m]}

upon event <rbDeliver, pi, [Data, pastm, m]> do:
    if m not in delivered:
        for [sn, n] in pastm:
            if n not in delivered:
                trigger <rcoDeliver, sn, n>
                delivered := delivered U {n}
                past := past U {[sn, n]}
        trigger <rcoDeliver, pi, m>
        delivered := delivered U {m}
        past := past U {[pi, m]}
{% endhighlight %}

This algorithm ensures causal reliable broadcast. The idea is to re-broadcast all past messages every time, making sure we don't deliver twice. This is obviously not efficient, but it works in theory.

To improve this, we can implement a form of garbage collection. We can delete the `past` only when all others have delivered. To do this, we need a perfect failure detector. 

{% highlight python linenos %}
Implements GarbageCollection + previous algorithm
Uses:
    ReliableBroadcast (rb)
    PerfectFailureDetector (P)

upon event <Init>:
    delivered := past := Ø
    correct := S # set of all nodes
    ack[m] := Ø # forall m

upon event <crash, pi>:
    correct := correct \ {pi}

upon for some m in delivered, self not in ack[m]:
    ack[m] = ack[m] U {self}
    trigger <rbBroadcast, [ACK, m]>

upon event <rbDeliver, [ACK, m]>:
    ack[m] := ack[m] U {pi}
    if correct.forall(lambda pj: pj in ack[m]): # if all correct in ack
        past := past \ {[sm, m]} # remove message from past
{% endhighlight %}

We need the perfect failure detector's strong accuracy property to prove the causal order property. We don't need the failure detector's completeness property; if we don't know that a process is crashed, it has no impact on correctness, only on performance, since it just means that we won't delete the past.


Another algorithm is given below. It uses a ["vector clock" VC](https://en.wikipedia.org/wiki/Vector_clock) as an alternative, more efficient encoding of the past. A VC is updated under the following rules:

- Initially all clocks are empty
- Each time a process sends a message, it increments its own logical clock in the vector by one and then sends a copy of its own vecto.
- Each time a process receives a message, it increments its own logical clock in the vector by one and updates each element in its vector by taking the maximum of the value in its own vector clock and the value in the vector in the received message (for every element).


{% highlight python linenos %}
Implements: ReliableCausalOrderBroadcast (rco)
Uses: ReliableBroadcast (rb)

upon event <Init>:
    for all pi in S:
        VC[pi] := 0
    pending := Ø

upon event<rcoBroadcast, m>:
    trigger <rcoDeliver, self, m>
    trigger <rbBroadcast, [Data,VC,m]>
    VC[self] := VC[self] + 1; # we have seen the message, so increment VC

upon event <rbDeliver, pj, [Data,VCm,m]>:
    if pj != self:
        pending := pending U (pj, [Data,VCm,m])
        deliver-pending()

def deliver-pending():
    while (s, [Data,VCm,m]) in pending:
        forall pk such that (VC[pk] <= VCm[pk]):
            pending := pending U (s, [Data,VCm,m])
            trigger <rcoDeliver, self, m>
            VC[s] := VC[s] + 1
{% endhighlight %}


## Total order broadcast
In [reliable broadcast](#reliable-broadcast), the processes are free to deliver in any order they wish. In [causal broadcast](#causal-broadcast), the processes must deliver in causal order. But causal order is only partial: some message may be delivered in a different order by the processes.

In **total order** broadcast, the processes must deliver all messages according to the same order. Note that this is orthogonal to causality, or even FIFO ordering. It can be *made* to respect causal or FIFO ordering, but at its core, it is only concerned with all processes delivering in the same order. 

An application using total order broadcast would be Bitcoin; for the blockchain, we want to make sure that everybody gets messages in the same order, for consistency.

The properties are:

- **RB1 Validity**: if $p_i$ and $p_j$ are correct then every message broadcast by $p_i$ is eventually delivered by $p_j$
- **RB2 No duplication**: no message is delivered more than once
- **RB3 No creation**: no message is delivered unless it was broadcast
- **RB4 Agreement**: for any message $m$, if a **correct** process delivers $m$, then every correct process delivers $m$
- **TO1 (Uniform) Total Order**: Let $m$ and $m'$ be any two messages. Let $p_i$ be any (correct) process that delivers $m$ without having delivered $m'$ before. Then no (correct) process delivers $m'$ before $m$

The algorithm can be implemented as:

{% highlight python linenos %}
Implements: TotalOrder (to)
Uses:
    ReliableBroadcast (rb)
    Consensus (cons)

upon event <init>:
    unordered := delivered := Ø # two sets
    wait := False
    sn := 1 # sequence number

upon event <toBroadcast, m>:
    trigger <rbBroadcast, m>

upon event <rbDeliver, sm, m> and m not in delivered:
    unordered.add((sm, m)) 

upon unordered not empty and not wait:
    wait := True
    trigger <propose, unordered> with sn

upon event <decide, decided> with sn:
    unordered.remove(decided)
    ordered = sort(decided)
    for sm, m in ordered:
        trigger <toDeliver, sm, m>
        delivered.add(m)
    sn += 1
    wait = False
{% endhighlight %}

Our total order broadcast is based on consensus, which we describe below.

## Consensus
In the (uniform) consensus problem, the processes all propose values, and need to agree on one of these. This gives rise to two basic events: a proposition, and a decision. Solving consensus is key to solving many problems in distributed computing (total order broadcast, atomic commit, ...).

The properties that we would like to see are:

- **C1 Validity**: if a value is decided, it has been proposed
- **C2 (Uniform) Agreement**: no two correct (any) processes decide differently
- **C3 Termination**: every correct process eventually decides
- **C4 Integrity**: Every process decides at most once

If C2 is Uniform Agreement, then we talk about uniform consensus.

Todo: write about consensus and fairness, does it violate validity?

We can build consensus using total order broadcast, which is described above. But total broadcast can be built with consensus. It turns out that **consensus and total order broadcast are equivalent problems in a system with reliable channels**.

Blockchain is based on consensus. Bitcoin mining is actually about solving consensus: a leader is chosen to decide on the broadcast order, and this leader gains 50 bitcoin. Seeing that this is a lot of money, many people want to be the leader; but we only want a single leader. Nakamoto's solution is to choose the leader by giving out a hard problem. The computation can only be done with brute-force, there are no smart tricks or anything. So people put [enormous amounts of energy](https://digiconomist.net/bitcoin-energy-consumption) towards solving this. Usually, only a single person will win the mining block; the probability is small, but the [original Bitcoin paper](https://bitcoin.org/bitcoin.pdf) specifies that we should wait a little before rewarding the winner, in case there are two winners.

### Consensus algorithm
Suppose that there are $n$ processes. At the beginning, every process proposes a value; to decide, the processes go through $n$ rounds incrementally. At each round, the process with the id corresponding to the round number is the leader of the round. Note that the rounds are not global time; we may make them so in examples for the sake of simplicity, but rounds are simply a local thing, which are somewhat synchronized by message passing from the leader.

The leader decides its current proposal and broadcasts it to all. A process that is not the leader waits. It can either deliver the proposal of the leader to adopt it, or suspect the leader. In any case, we can move on to the next round at that moment. Note that processes don't need to move on at the same time, they can do so at different moments.

{% highlight python linenos %}
todo
{% endhighlight %}

correctness argument todo

### Uniform consensus algorithm
The idea is here is to do the same thing, but instead of deciding at the beginning of the round, we wait until round n.

not taking notes today, don't feel like it.

### Uniform consensus algorithm with eventually perfect failure detector
This assumes a correct majority, and an eventually perfect failure detector.

When you suspect a process, you send them a message. When a new leader arrives, he asks what the previous value was, and at least one process will respond.


## Atomic commit
The unit of data processing in a distributed system is the *transaction*. A transaction describes the actions to be taken, and can be terminated either by **committing** or **aborting**.

### Non-Blocking Atomic Commit (NBAC)
The **nonblocking atomic commit (NBAC)** abstraction is used to solve this problem in a reliable way. As in consensus, every process proposes an initial value of 0 or 1 (no or yes), and must decide on a final value 0 or 1 (abort or commit). Unlike consensus, the processes here seek to decide 1, but every process has a veto right.

The properties of NBAC are:

- **NBAC1. Agreement**: no two processes decide differently
- **NBAC2. Termination**: every correct process eventually decides
- **NBAC3. Commit-validity**: 1 can only be decided if all processes propose 1
- **NBAC4. Abort-validity**: 0 can only be decided if some process crashes or votes 0

Note that here, NBAC must decide to abort if some process crashes, even though all processes have proposed 1 (commit).

We can implement NBAC using three underlying abstractions:

- A perfect failure detector P
- Uniform consensus
- Best-effort broadcast BEB

It works as follows: every process $p$ broadcasts its initial vote (0 or 1, abort or commit) to all other processes using BEB. It waits to hear something from every process $q$ in the system; this is either done through *beb*-delivery from $q$, or by detecting the crash of $q$. At this point, two situations are possible:

- If $p$ gets 0 (abort) from any other process, or if it detects a crash, it invokes consensus with a proposal to abort (0). 
- Otherwise, if it receives the vote to commit (1) from all processes, then it invokes consensus with a proposal to commit (1).

Once the consensus is over, every process nbac decides according to the outcome of the consensus.

We can write this more formally:

{% highlight python linenos %}
Events:
    Request: <Propose, v1>
    Indication: <Decide, v2>

Properties:
    NBAC1, NBAC2, NBAC3, NBAC4

Implements: nonBlockingAtomicCommit (nbac)
Uses:
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
    UniformConsensus (uc)

upon event <Init>:
    prop := 1
    delivered := Ø
    correct := all_processes

upon event <Crash, pi>:
    correct := correct \ {pi}

upon event <Propose, v>:
    trigger <bebBroadcast, pi>

upon event <bebDeliver, pi, v>:
    delivered := delivered U {pi}
    prop := prop * v

upon event correct \ delivered = Ø:
    if correct != all_processes:
        prop := 0
    trigger <ucPropose, prop>

upon event <ucDecide, decision>:
    trigger <Decide, decision>
{% endhighlight %}

We use multiplication to factor in the decisions we get from other processes; if we get a single 0, the final proposition will be 0 too. If we get only 1s, the final proposition will be 1 too. Otherwise, this should be a fairly straight-forward implementation of the description we gave. 

We need a perfect failure detector $P$. An eventually perfect failure detector $\diamond P$ is not enough (todo why?).

### 2-Phase Commit
This is a *blocking* algorithm. Unlike NBAC, this algorithm does not use consensus. It operates under a relaxed set of constraints; the termination property has been replaced with weak termination, which just says that if a process $p$ doesn't crash, then all correct processes eventually decide.

In 2PC, we have a leading coordinator process $p$ which takes the decision. It asks everyone to vote, makes a decision, and notifies everyone of the decision.

As the name indicates, there are two phases in this algorithm:

1. **Voting phase:** As before, proposals are sent with best-effort broadcast. A process collects all these proposals. 
2. **Commit phase**: Again, just as before, it decides to abort if it receives any abort proposals, or if it detects any crashes with its perfect failure detector. Otherwise, if it receives proposals to commit from everyone, it will decide to commit. It then sends this decision to all processes with BEB.

If $p$ crashes, all processes are blocked, waiting for its response. 


## Terminating reliable broadcast (TRB)
Like reliable broadcast, terminating reliable broadcast (TRB) is a communication primitive used to disseminate a message among a set of processes in a reliable way. However, TRB is stricter than URB.

In TRB, there si a specific broadcaster process $p_{\text{src}}$, known by all processes. It is supposed to broadcast a message $m$. We'll also define a distinct message $\phi \ne m$. The other processes need to deliver $m$ if $p_{\text{src}}$ is correct, but may deliver $\phi$ if $p_{\text{src}}$ crashes.

The idea is that if $p_{\text{src}}$ crashes, the other processes may detect that it's crashed, without having ever received $m$. But this doesn't mean that $m$ wasn't sent; $p_{\text{src}}$ may have crashed while it was in the process of sending $m$, so some processes may have delivered it while others might never do so.

For a process $p$, the following cases cannot be distinguished:

- Some other process $q$ has delivered $m$; this means that $p$ should keep waiting for it
- No process will ever deliver $m$; this means that $p$ should **not** keep waiting for it

TRB solves this by adding this missing piece of information to (uniform) reliable broadcast. It ensures that every process either delivers the messaeg $m$ or sends a failure indicator $\phi$. 


The properties of TRB are:

- **TRB1. Integrity**: If a process delivers a message $m$, then either $m$ is $\phi$ or $m$ was broadcast by $p_{\text{src}}$
- **TRB2. Validity**: If the sender $p_{\text{src}}$ is correct and broadcasts a message $m$, then $p_{\text{src}}$ eventually delivers $m$
- **TRB3. (Uniform) Agreement**: For any message $m$, if a correct process (any process) delivers $m$, then every correct process delivers $m$
- **TRB4. Termination**: Every correct process eventually delivers exactly one message

Unlike reliable broadcast, every correct process delivers a message, even if the broadcaster crashes. Indeed, with (uniform) reliable broadcast, when the broadcaster crashes, the other processes may deliver *nothing*. 

{% highlight python linenos %}
Events:
    Request: <trbBroadcast, m>  # broadcasts a message m to all processes
    Indication: <trbDeliver, m> # delivers a message m, or the failure ϕ

Properties:
    TRB1, TRB2, TRB3, TRB4

Implements:
    trbBroadcast (trb)

Uses:
    BestEffortBroadcast (beb)
    PerfectFailureDetector (P)
    Consensus (cons)

upon event <Init>:
    proposal := null
    correct := S

# When application broadcasts:
upon event <trbBroadcast, m>:
    trigger <bebBroadcast, m>

# When the perfect failure detector detects a crash
upon event <Crash, pi> and (proposal = null):
    if pi == p_src:
        proposal := ϕ

upon event <bebDeliver, src, m> and (proposal = null):
    proposal := m

upon event (proposal != null):
    trigger <Propose, proposal>

upon event <Decide, decision>:
    trigger <trbDeliver, src, decision>
{% endhighlight %}

todo explain how we use consensus, and why P is necessary.


## Group membership
Every view is a pair $(i, M)$, where $i$ is the numbering of the view, and $M$ is a set of processes.

Properties:

- **Memb1. Local Monotonicity**: If a process installs view $(j, M)$ after $(k, N)$, then $j > k$ and $\abs{M} < \abs{N}$ (the only reason to change a view is to remove a process from the set when it crashes).
- **Memb2. Agreement**: No two processes install views $(j, M)$ and $(j, M')$ such that $M \ne M'$.
- **Memb3. Completeness**: If a process $p$ crashes, then there is an integer $j$ such that every correct process installs view $(j, M)$ in which $p\notin M$
- **Memb4. Accuracy**: If some process installs a view $(i, M)$ and $p\notin M$ then $p$ has crashed.

The implementation uses consensus and a perfect failure detector.

{% highlight python linenos %}
todo
{% endhighlight %}

We use a `wait` variable, just like in total order. This allows to prevent a process from triggering a new view installation before the previous one has been done.

## View-Synchronous (VS) communication
This abstraction brings together reliable broadcast and group membership. However, this introduces a subtle problem, justifying the introduction of a solution as a new abstraction. Indeed, if a message is broadcast right as we're installing a view, we're breaking things. To solve this, we must introduce some notion of phases in which messages can or cannot be sent.


## From message passing to Shared memory
The Cloud is an example of shared memory, with which we interact by message passing.

A register contains integers....



## Byzantine failures
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
  
  By the liveness and safety property, we know that initially $x=0, eventually $x=m$, and we never have $x=m'$.
  
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