---
title: CS-451 Distributed Algorithms
description: "My notes from the CS-451 Distributed Algorithms course given at EPFL, in the 2018 autumn semester (MA1)"
edited: true
unlisted: true
---

⚠ *Work in progress*

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

## Links
Two nodes can communicate through a link by passing messages. However, this message passing can be faulty: it can drop messages or repeat them. How can we ensure correct and reliable message passing under such conditions?

A link has two basic types of events:

- Send
- Deliver

### Fair loss link (FLL)
A fair loss link is a link that may lose or repeat some packets. This is the weakest type of link we can assume. In practice, it corresponds to UDP.  

Deliver can be thought of as a reception event on the receiver end. The terminology used here ("deliver") implies that the link delivers to the client, but this can equally be thought of as the client receiving from the link.

For a link to be considered a fair-loss link, we must respect the following three properties:

- **Fair loss**: if the sender sends infinitely many times, the receiver must deliver infinitely many times. This does not guarantee that all messages get through, but at least ensures that some messages get through.
- **No creation**: every delivery must be the result of a send; no message must be created out of the blue. 
- **Finite duplication**: a message can only be repeated by the link a finite number of times.

### Stubborn link
A stubborn link is one that stubbornly delivers messages; that is, it ensures that the message is received, with no regard to performance.

A stubborn link can be implemented with a FLL as follows:

```pseudocode
upon send(m):
	while true:
		FLL.send(m)

upon FLL.deliver(m):
	trigger deliver(m)
```

The above uses generic pseudocode, but the syntax we'll use in this course is as follows:

```
Implements: SubbornLinks (sp2p)
Uses: FairLossLinks (flp2p)

upon event <sp2pSend, dest, m> do
	while (true) do
		trigger <flp2p, dest, m>;

upon event <flp2pDeliver, src, m> do
	trigger <sp2pDeliver, src, m>;
```

Note that this piece of code is meant to sit between two abstraction levels; it is between the channel and the application. As such, it receives sends from the application and forwards them to the link, and receives delivers from the link and forwards them to the application. 

It must respect the interface of the underlying FLL, and as such, only specifies send and receive hooks.

### Perfect link 
Here again, we respect the send/deliver interface. The properties are:

- **Validity** or reliable delivery: if both peers are correct, then every message sent is eventually delivered 
- **No duplication**
- **No creation**

This is the type of link that we usually use: TCP is a perfect link, although it also has more guarantees (notably on message ordering, which this definition of a perfect link does not have). TCP keeps retransmitting a message stubbornly, until it gets an acknowledgement, which means that it can stop transmitting. Acknowledgements aren't actually needed *in theory*, it would still work without them, but we would also completely flood the network, so acknowledgements are a practical consideration for performance; just note that the theorists don't care about them.

```
Implements: PerfectLinks (pp2p)
Uses: StubbornLinks (sp2p)

upon event <Init> do delivered := Ø;

upon event <pp2pSend, dest, m> do
	trigger <sp2pSend, dest, m>;

upon event <sp2pDeliver, src, m> do
	if m not in delivered then
		trigger <pp2pDeliver, src, m>;
		add m to delivered;
```



## Impossibility of consensus
Suppose we'd like to compute prime numbers on a distributed system. Let *P* be the producer of prime numbers. Whenever it finds one, it notifies two servers, *S1* and *S2* about it. A client *C* may request the full list of known prime numbers from either server.

As in any distributed system, we want the servers to behave as a single (abstract) machine.

### Solvable atomicity problem
*P* finds 1013 as a new prime number, and sends it to *S1*, which receives it immediately, and *S2*, which receives it after a long delay. In the meantime, before both servers have received the update, we have an atomicity problem: one server has a different list from the other. In this time window, *C* will get different results from *S1* (which has numbers up to 1013) and *S2* (which only has numbers up to 1009, which is the previous prime). 

A simple way to solve this is to have *C* send the new number (1013) to the other servers; if it requested from *S1* it'll send the update to *S2* as a kind of write back, to make sure that *S2* also has it for the next request. We haven't strictly defined the problem or its requirements, but this may need to assume a link that guarantees delivery and order (i.e. TCP, not UDP).

### Unsolvable atomicity problem
Now assume that we have two prime number producers *P1* and *P2*. This introduces a new atomicity problem: the updates may not reach all servers atomically in order, and the servers cannot agree on the order. 

This is **impossible** to solve; we won't prove it, but universality of Turing is lost (unless we make very strong assumptions). This is known as the [*impossibility of consensus*](https://groups.csail.mit.edu/tds/papers/Lynch/jacm85.pdf).


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

```
for each node p:
	initially:
		send (p, m(p)) to all neighbors

	upon reception of of (v, m):
		add (v, m) to p.R
		send (v, m) to all neighbors
```

#### Reliable communication

Now, let's prove that if two nodes $p$ and $q$ are connected, then they communicate reliably. We'll do this by induction; formally, we'd like to prove that the proposition $\mathcal{P}_k$, defined as "$p_k \text{ receives } (p, m_p)$", is true for $k\in \left\\{ 1, \dots, n \right\\}$. 

- **Base case**
  
  According to the algorithm, $p=p_1$ initially sends $(p, m_p)$ to $$p_2$$. So $p_2$ receives $(p, m_p)$ from $p_1$, and $\mathcal{P}_2$ is true.

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

## Reliable broadcast

## Causal order broadcast
## Shared memory
## Consensus
## Total order broadcast
## Atomic commit
## Leader election
## Terminating reliable broadcast
## Blockchain
