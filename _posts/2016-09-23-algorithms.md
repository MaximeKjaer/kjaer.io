---
title: CS-250 Algorithms
description: "My notes from the CS-250 Algorithms course given at EPFL, in the 2016 spring semester (BA3)"
image: /images/hero/algorithms.jpg
fallback-color: "#7c6850"
unlisted: true
math: true
---

* TOC
{:toc}

## Links and books
- [Course homepage](http://theory.epfl.ch/courses/algorithms/)
- Introduction to Algorithms, Third edition (2009), T. Cormen, C. Lerserson, R. Rivest, C. Stein (*important for this course*)
- The Art of Computer Programming, Donald Knuth (*a classic*)

## Analyzing algorithms
We'll work under a model that assumes that:

- Instructions are executed one after another
- Basic instructions (arithmetic, data movement, control) take constant O(1) time
- We don’t worry about precision, although it is crucial in certain
numerical applications

We usually concentrate on finding the worst-case running time. This gives a guaranteed upper bound on the running time. Besides, the worst case often occurs in some algorithms, and the average is often as bad as the worst-case.

## Sorting
The sorting problem's definition is the following:

- **Input**: A sequence of $$n$$ numbers $$(a_1, a_2, \dots, a_n)$$
- **Output**: A permutation (reordering) $$(a_1', a_2', \dots, a_n')$$ of the input sequence in increasing order


### Insertion sort
Works in the same way as sorting a deck of cards.

{% highlight python linenos %}
def insertion_sort(A, n):
    for j=2 to n: # We start at 2 because 1 is already sorted.
        key = A[j]
        # Insert A[j] in to the sorted sequence A[1..j-1]
        i = j-1
        while i > 0 and A[i] > key:
            A[i+1] = A[i]
            i = i-1
        A[i+1] = key
{% endhighlight %}
<figure>
    <figcaption>Note that pseudocode arrays start at index 1</figcaption>
</figure>

#### Correctness
Using induction-like logic.

**Loop invariant**: At the start of each iteration of the "outer" `for` loop &mdash; the loop indexed by `j` &mdash; the subarray `A[1, ..., j-1]` consists of the elements originally in `A[1, ..., j-1]` but in sorted order.

We need to verify:

- **Initialization**: We start at `j=2` so we start with one element. One number is trivially sorted compared to itself.
- **Maintenance**: We'll assume that the invariant holds at the beginning of the iteration when `j=k`. The body of the `for` loop works by moving `A[k-1]`, `A[k-2]` ansd so on one step to the right until it finds the proper position for `A[k]` at which points it inserts the value of `A[k]`. The subarray `A[1..k]` then consists of the elements in a sorted order. Incrementing `j` to `k+1` preserves the loop invariant.
- **Termination**: The condition of the `for` loop to terminate is that `j>n`; hence, `j=n+1` when the loop terminates, and `A[1..n]` contains the original elements in sorted order.

#### Analysis

![Cost of each line of the insertion sort algorithm](/images/algorithms/insertion-analysis.png)

- **Best case**: The array is already sorted, and we can do $$\Theta(n)$$
- **Worst case**: The array is sorted in reverse, so $$j=t_j$$ and the algorithm runs in $$\Theta(n^2)$$:


<figure>
    $$ c_5 \sum_{j=2}^{n} t_j = c_5 \frac{n(n-1)}{2}=\mathcal{O}(n^2) $$
    <figcaption>The first equality is achieved using Gauss' summation formula</figcaption>
</figure>

### Merge Sort
Merge sort is a divide-and-conquer algorithm:

- **Divide** the problem into a number of subproblems that are
smaller instances of the same problem
- **Conquer** the subproblems by solving them recursively. *Base case: If the subproblems are small enough, just solve them by brute force*
- **Combine** the subproblem solutions to give a solution to the original problem

![Dividing and merging a list to sort the numbers](/images/algorithms/merge-chart.png)

Merge sort can be implemented recursively as such:

{% highlight python linenos %}
def merge_sort(A, p, r):
    if p < r: # Check for base case
        q = math.floor((p + r) / 2) # Divide
                                    # q is the index at which we split the list
        merge_sort(A, p, q) # Conquer
        merge_sort(a, q+1, r) # Conquer
        merge(A, p, q, r) # Combine

def merge(A, p, q, r):
    n1 = q - p + 1 # Size of the first half
    n2 = r - q # Size of the second half
    let L[1 .. n1 + 1] and R[1 .. n2 + 1] be new arrays
    for i = 1 to n1:
        L[i] = A[p + i - 1]
    for j = 1 to n2:
        R[j] = A[q + j]
    L[n1 + 1] = infinity # in practice you could use sys.maxint
    R[n2 + 1] = infinity
    i = 1
    j = 1
    for k = p to r:
        if L[i] <= R[j]:
            A[k] = L[i]
            i = i + 1
        else:
            A[k] = R[j]
            j = j + 1

{% endhighlight %}

In the `merge` function, instead of checking whether either of the two lists that we're merging is empty, we can just add a **sentinel** to the bottom of the list, with value &infin;. This works because we're just picking the minimum value of the two. 

This algorithm works well in parallel, because we can split the lists on separate computers.

#### Correctness
Assuming `merge` is correct, we can do a proof by strong induction on $$n = r - p$$.

- **Base case**, $$n = 0$$: In this case $$r = p$$ so `A[p..r]` is trivially sorted.
- **Inductive case**: By  induction hypothesis `merge_sort(A, p, q)` and `merge_sort(A, q+1, r)` successfully sort the two subarrays. Therefore a correct merge procedure will successfully sort `A[p..q]` as required.

#### Analysis
- **Divide**: Takes contant time, i.e., $$D(n) = \Theta(1)$$
- **Conquer**: Recursively solve two subproblems, each of size $$n/2$$, so we have $$2T(n/2)$$, where:

$$ T(n) = 
\begin{cases}
\Theta(1) & \text{if } n = 1 \\
2T(n/2) + \Theta(n) & \text{otherwise} \\
\end{cases}
$$

Trying to substitue $$T(n/2)$$ multiple times yields $$T(n) = 2^k T(n/2^k) + kcn$$. By now, a qualified guess would be that $$T(n) = \Theta(n \log{n})$$

We'll prove this the [following way](http://moodle.epfl.ch/pluginfile.php/1735456/mod_resource/content/1/Lecture3.pdf):

<figure>
    <img src="/images/algorithms/merge-upper-bound.png" alt="Proof by induction of the upper bound">
    <img src="/images/algorithms/merge-lower-bound.png" alt="Proof by induction of the lower bound">
    <figcaption>When proving this, be careful: you're not allowed to change a. Ending with (a+1) is invalid.</figcaption>
</figure>


- **Combine**: Merge on an *n*-element subarray takes $$\Theta(n)$$ time, so $$C(n) = \Theta(n)$$

All-in-all, merge sort runs in $$\Theta(n \log{n})$$, both in worst and best case.

For small instances, [insertion sort](#insertion-sort) can still be faster despite its quadratic runtime; but for bigger instances, merge sort is definitely faster.

However, merge sort is not *in-place*, meaning that it does not operate directly on the list that needs to be sorted, unlike insertion sort.

<!-- Lecture 4 -->

### Master Theorem

Generally, we can solve recurrences in a black-box manner thanks to the Master Theorem:

***

Let $$a \geq 1$$ and $$b > 1$$ be constants, let $$T(n)$$ be defined on the nonnegative integers by the recurrence:

$$ T(n) = aT(n/b) + f(n) $$

Then, $$T(n)$$ has the following asymptotic bounds

- If $$f(n) = \mathcal{O}(n^{\log_b{a}-\epsilon})$$ for some constant $$\epsilon > 0 $$, then $$T(n)=\Theta(n^{\log_b{a}}) $$
- If $$ f(n) = \Theta(n^{\log_b{a}}) $$, then $$ T(n) = \Theta(n^{\log_b{a}} \log{n}) $$
- If $$ f(n) = \Omega(n^{\log_b{a}+\epsilon}) $$ for some constant $$ \epsilon > 0 $$, and if $$a \cdot f(n/b) \leq c\cdot f(n)$$ for some constant $$c < 1$$ and all sufficiently large $$n$$, then $$T(n) = \Theta(f(n))$$

***

The 3 cases correspond to the following cases in a recursion tree:

- Leaves dominate
- Each level has the same cost
- Roots dominate



## Maximum-Subarray Problem

### Description
You have the prices that a stock traded at over a period of *n* consecutive days. When should you have bought the stock? When should you have sold the stock?

![An example of stock prices over a few days](/images/algorithms/stock-chart.png)

We don't want to just buy at the lowest and sell at the highest, as the lowest price might occur *after* the highest.

- **Input**: An array `A[1..n]` of numbers
- **Output**: Indices `i` and `j` such that `A[i..j]` has the greatest sum of any nonempty, contiguous subarray of `A`, along with the sum of the values in `A[i..j]`

### Divide and Conquer
- **Divide** the subarray into two subarrays of as equal size as possible. Find the midpoint mid of the subarrays, and consider the subarrays `A[low..mid]` and `A[mid+1..high]`
    + This can run in $$\Theta(1)$$
- **Conquer** by finding maximum subarrays of `A[low..mid]` and `A[mid+1..high]`
    + Recursively solve two subproblems, each of size $$n/2$$, so $$2T(n/2)$$
- **Combine** find a maximum subarray that crosses the midpoint, and use the best solution out of the three (that is, left, midpoint and right).
    + The merge is dominated by `find_max_crossing_subarray` so $$\Theta(n)$$

The overall recursion is $$T(n) = 2T(n/2) + \Theta(n)$$, so the algorithm runs in $$\Theta(\log{n})$$

In pseudo-code the algorithm is:

{% highlight python linenos %}
def find_maximum_subarray(A, low, high):
    if high == low: # base case: only one element
        return (low, high, A[low])
    else:
        mid = math.floor((low + high)/2)
        (l_low, l_high, l_sum) = find_maximum_subarray(A, low, mid)
        (r_low, r_high, r_sum) = find_maximum_subarray(A, mid+1, high)
        (x_low, x_high, x_sum) = find_max_crossing_subarray(A, low, mid, high)

        # Find the best solution of the three:
        if l_sum >= r_sum and l_sum >= x_sum:
            return (l_low, l_high, l_sum)
        elsif r_sum >= l_sum and r_sum >= x_sum:
            return (r_low, r_high, r_sum)
        else:
            return (x_low, x_high, x_sum)

def find_max_crossing_subarray(A, low, mid, high):
    # Find a maximum subarray of the form A[i..mid]
    l_sum = - infinity # Lower-bound sentinel
    sum = 0
    for (i = mid) downto low:
        sum += A[i]
        if sum > l_sum:
            l_sum = sum
            l_max = i

    # Find a maximum subarray of the form A[mid+1..j]
    r_sum = - infinity # Lower-bound sentinel
    sum = 0
    for j = mid to high:
        sum += A[j]
        if sum > r_sum:
            r_sum = sum
            r_max = j

    # Return the indices and the sum of the two subarrays
    return (l_max, r_max, l_sum + r_sum)
{% endhighlight %}

## Matrix multiplication

- **Input**: Two $$n\times n$$ (square) matrices, $$A = (a_{ij})$$ and $$B = (b_{ij})$$
- **Output**: $$n\times n$$ matrix $$C = (c_{ij})$$ where $$C=A\cdot B$$.

### Naive Algorithm
The naive algorithm simply calculates $$c_{ij}=\sum_{k=1}^n a_{ik}b_{kj}$$. It runs in $$\Theta(n^3)$$ and uses $$\Theta(n^2)$$ space.

We can do better.

### Divide-and-Conquer algorithm
- **Divide** each of A, B and C into four $$n/2\times n/2$$ matrices so that:

![Matrix blocks](/images/algorithms/matrices.png)

- **Conquer**: We can recursively solve 8 *matrix multiplications* that each multiply two $$n/2 \times n/2$$ matrices, since:
    + $$ C_{11}=A_{11}B_{11} + A_{12}B_{21}, \qquad C_{12}=A_{11}B_{12} + A_{12}B_{22} $$.
    + $$ C_{21}=A_{21}B_{11} + A_{22}B_{21}, \qquad C_{22}=A_{21}B_{12} + A_{22}B_{22} $$.

- **Combine**: Make the additions to get to C.
    + $$ C_{11}=A_{11}B_{11} + A_{12}B_{21} $$ is $$\Theta(n^2)$$.


#### Pseudocode and analysis
{% highlight python linenos %}
def rec_mat_mult(A, B, n):
    let C be a new n*n matrix
    if n == 1:
        c11 = a11 * b11
    else partition A, B, and C into n/2 * n/2 submatrices:
        C11 = rec_mat_mult(A[1][1], B[1][1], n/2) + rec_mat_mult(A[1][2], B[2][1], n/2)
        C12 = rec_mat_mult(A[1][1], B[1][2], n/2) + rec_mat_mult(A[1][2], B[2][2], n/2)
        C21 = rec_mat_mult(A[2][1], B[1][1], n/2) + rec_mat_mult(A[2][2], B[2][1], n/2)
        C22 = rec_mat_mult(A[2][1], B[1][2], n/2) + rec_mat_mult(A[2][2], B[2][2], n/2)
    return C
{% endhighlight %}

The whole recursion formula is $$T(n) = 8\cdot T(n/2) + \Theta(n^2) = \Theta(n^3)$$. So we did all of this for something that doesn't even beat the naive implementation!!

### Strassen's Algorithm for Matrix Multiplication
What really broke the Divide-and-Conquer approach is the fact that we had to do 8 matrix multiplications. Could we do fewer matrix multiplications by increasing the number of additions?


*Spoiler Alert*: Yes.

There is a way to do only 7 recursive multiplications of $$n/2\times n/2$$ matrices, rather than 8. Our recurrence relation is now:

$$ T(n) = 7\cdot T(n/2) + \Theta(n^{log_2(7)}) = \Theta(n^{2.807...}) $$

Strassen's method is the following:

![Strassen's method](/images/algorithms/strassen.png)

Note that when our matrix's size isn't a power of two, we can just pad our operands with zeros until we do have a power of two size. This still runs in $$\Theta(n^{log_2{(7)}})$$.

#### Notes about Strassen
- First to beat $$\Theta(n^3)$$ time
- Faster methods are known today: Coppersmith and Winograd's method runs in
time $$\mathcal{O}(n^{2.376})$$, which has recently been improved by Vassilevska Williams to $$\mathcal{O}(n^{2.3727})$$.
- How to multiply matrices in best way is still a big open problem 
- The naive method is better for small instances because of hidden constants in Strassen's method's runtime.


<!--

#### Karatsuba's algorithm
Before we leave Divide-and-Conquer algorithms, we'll take a last look at an interesting one.

**Problem**: Given two n-digit long integers x and y, base b, find $$x\cdot y$$

The "grade school algorithm", the naive one, runs in:

$$ T(n) = 4T(n/2) + \Theta(n) = \Theta(n^2) $$

Karatsuba's algorithm runs in:

$$ T(n) = 3T(n/2)+\Theta(n)=\Theta(n^{\log_2{3}})\approx\Theta(n^{1.58}) $$

-->

## Heaps and Heapsort

### Heaps
A heap is a *nearly complete binary tree* (meaning that the last level may not be complete). The main property of a heap is:

- **Max-heap**: the key of `i`'s children is smaller or equal to `i`'s key.
- **Min-heap**: the key of `i`'s children is greater or equal to `i`'s key.

In a max-heap, the maximum element is at the root, while the minimum element takes that place in a min-heap.

![Max-heats and min-heats' ordering](/images/algorithms/heats.png)

The height of a node is the number of edges on a longest simple path from the node down to a leaf. The height of the heap is therefore simply the height of the root, $$\Theta(\log{n})$$.

We can store the heap in a list, where:

- `Root` is `A[1]`
- `Left(i)` is `2i`
- `Right(i)` is `2i + 1`
- `Parent(i)` is `floor(i/2)`

#### Max-Heapify
It's a very important algorithm for manipulating heaps. Given an *i* such that the subtrees of *i* are heaps, it ensures that the subtree rooted at *i* is a heap satisfying the heap property.

- Compare `A[i]`, `A[Left(i)]`, `A[Right(i)]`
- If necessary, swap `A[i]` with the largest of the two children to preserve heap property.
- Continue this process of comparing and swapping down the heap, until the subtree rooted at *i* is a max-heap.

{% highlight python linenos %}
# A is the array in which the heap is implemented
# i is the index where we want to heapify
# n is the size of A
def max_heapify(A, i, n):
    l = Left(i)
    r = Right(i)
    if l <= n and A[l] > A[i]: # if left is larger than parent
        largest = l
    else largest = i
    if r <= n and A[r] > A[largest]: # if right is larger than both left and parent
        largest = r
    if largest != i: # If we have to make a swap
        exchange A[i] with A[largest]
        max_heapify(A, largest, n)
{% endhighlight %}

This runs in $$\Theta(\text{height of } i) = \mathcal{O}(\log{n})$$ and uses $$\Theta(n)$$ space.

#### Building a heap
Given an unordered array `A` of length `n`, `build_max_heap` outputs a heap.

{% highlight python linenos %}
def build_max_heap(A, n):
    for i = floor(n/2) downto 1:
        max_heapify(A, i, n)
{% endhighlight %}

This procedure operates in place. We can start at $$\lfloor{\frac{n}{2}}\rfloor$$ since all elements after that threshold are leaves, so we're not going to heapify those anyway.

We have $$\mathcal{O}(n)$$ calls to `max_heapify`, each of which takes $$\mathcal{O}(\log{n})$$ time, so we have $$\mathcal{O}(n\log{n})$$ in total.

However, we can give a tighter bound: the time to run `max_heapify` is linear in the height of the node it's run on. Hence, the time is bounded by:

$$ \sum_{h=0}^{\log{n}} \text{# of nodes of height h}\cdot\mathcal{O}(h) = \mathcal{O}\left( n \sum_{h=0}^{\log{n}} \frac{h}{2^h}\right) $$

Which is $$\mathcal{O}(n)$$, since:

$$ \sum_{h=0}^\infty{\frac{h}{2^h}} = \frac{1/2}{(1-1/2)^2} = 2 $$

*See the slides for a proof by induction.*

### Heapsort
Heapsort is the best of both worlds: it's $$O(n\log{n})$$ like merge sort, and sorts in place like insertion sort.

- Starting with the root (the maximum element), the algorithm
places the maximum element into the correct place in the array by
swapping it with the element in the last position in the array.
- “Discard” this last node (knowing that it is in its correct place) by
*decreasing the heap size*, and calling `max_heapify` on the new
(possibly incorrectly-placed) root.
- Repeat this “discarding” process until only one node (the smallest
element) remains, and therefore is in the correct place in the array

{% highlight python linenos %}
def heapsort(A, n):
    build_max_heap(A, n)
    for i = n downto 2:
        exchange A[1] with A[i]
        max_heapify(A, 1, i-1)
{% endhighlight %}

- `build_max_heap`: $$\mathcal{O}(n)$$
- `for` loop: $$n-1$$ times
- Exchange elements: $$\mathcal{O}(1)$$
- `max_heapify`: $$\mathcal{O}(\log{n})$$

Total time is therefore $$\mathcal{O}(n\log{n})$$.

### Priority queues
In a priority queue, we want to be able to:

- Insert elements
- Find the maximum
- Remove and return the largest element
- Increase a key

A heap efficiently implements priority queues.

#### Finding maximum element
This can be done in $$\Theta(1)$$ by simply returning the root element.

{% highlight python linenos %}
def heap_maximum(A):
    return A[1]
{% endhighlight %}


#### Extracting maximum element
We can use [max heapify](#max-heapify) to rebuild our heap after removing the root. This runs in $$\mathcal{O}(\log{n})$$, as every other operation than `max-heapify` runs in $$\mathcal{O}(1)$$.

{% highlight python linenos %}
def heap_extract_max(A, n):
    if n < 1: # Check that the heap is non-empty
        error "Heap underflow"
    max = A[1]
    A[1] = A[n] # Make the last node in the tree the new root
    n = n - 1 # Remove the last node of the tree
    max_heapify(A, 1, n) # Re-heapify the heap
    return max
{% endhighlight %}

#### Increasing a value

{% highlight python linenos %}
def heap_increase_key(A, i, key):
    if key < A[i]:
        error "new key is smaller than current key"
    A[i] = key
    # Traverse the tree upward comparing new key to parent and swapping keys 
    # if necessary, until the new key is smaller than the parent's key:
    while i > 1 and A[Parent(i)] < A[i]:
        exchange A[i] with A[Parent(i)]
        i = Parent(i)
{% endhighlight %}

This traverses the tree upward, and runs in $$\mathcal{O}(\log{n})$$.

#### Inserting into the heap
{% highlight python linenos %}
def max_heap_insert(A, key, n):
    n = n + 1 # Increment the size of the heap
    A[n] = - infinity # Insert a sentinel node in the last pos
    heap_increase_key(A, n, key) # Increase the value to key
{% endhighlight %}

We know that this runs in the time for `heap_increase_key`, which is $$\mathcal{O}(\log{n})$$.

### Summary
- Heapsort runs in $$\mathcal{O}(n\log{n})$$ and is in-place. However, a well implemented quicksort usually beats it in practice.
- Heaps efficiently implement priority queues:
    + `insert(S, x)`: $$\mathcal{O}(\log{n})$$
    + `maximum(S)`: $$\mathcal{O}(1)$$
    + `extract_max(S)`: $$\mathcal{O}(\log{n})$$
    + `increase_key(S, x, k)`: $$\mathcal{O}(\log{n})$$

## More data structures

### Stacks
Stacks are LIFO (last-in, first out). It has two basic operations:

- Insertion with `push(S, x)`
- Delete operation with `pop(S)`

We can implement a stack using an array where `S[1]` is the bottom element, and `S[S.top]` is the element at the top.

{% highlight python linenos %}
def stack_empty(S):
    if S.top = 0:
        return true
    else return false

def push(S, x):
    S.top = S.top + 1 # Increment the pointer to the top
    S[S.top] = x # Store element

def pop(S):
    if stack_empty(S):
        error "underflow"
    else
        S.top = S.top - 1 # Decrement the pointer to the top
        return S[S.top + 1] # Return what we've removed
{% endhighlight %}

These operations are all $$\mathcal{O}(1)$$.

### Queues
Queues are FIFO (first-in, first-out). They have two basic operations:

- Insertion with `enqueue(Q, x)`
- Deletion with `dequeue(Q)`

Again, queues can be implemented using arrays with two pointers: `Q[Q.head]`  is the first element, `Q[Q.tail]` is the next location where a newly arrived element will be placed.

{% highlight python linenos %}
def enqueue(Q, x):
    Q[Q.tail = x]
    # Now, update the tail pointer:
    if Q.tail = Q.length: # Q.length is the length of the array
        Q.tail = 1 # Wrap it around
    else Q.tail = Q.tail + 1

def dequeue(Q):
    x = Q[Q.head]
    # Now, update the head pointer
    if Q.head = Q.length:
        Q.head = 1
    else Q.head = Q.head + 1
{% endhighlight %}

Notice that we're not deleting anything *per se*. We're just moving the boundaries of the queue and sometimes replacing elements.

Positives:

- Very efficient 
- Natural operations 

Negatives:

- Limited support: for example, no search
- Implementations using arrays have *fixed* capacity

### Linked Lists
<figure>
    <img src="/images/algorithms/linked-list.png" alt="Linked list">
    <figcaption>This linked list is doubly linked and unsorted. The <code>/</code> symbol represents Nil.</figcaption>
</figure>

Let's take a look at the operations in linked lists.

#### Search
{% highlight python linenos %}
def list_search(L, k):
    x = L.head
    while x != nil and x.key != k:
        x = x.next
    return x
{% endhighlight %}

This runs in $$\mathcal{O}(n)$$. If no element with key `k` exists, it will return `nil`.

#### Insertion
{% highlight python linenos %}
def list_insert(L, x):
    x.next = L.head
    if L.head != nil:
        L.head.prev = x
    L.head = x # Rewrite the head pointer
    x.prev = nil
{% endhighlight %}

This runs in $$\mathcal{O}(1)$$. It's important to add the element to the start of the list and not the end, as this linked list doesn't implement a tail pointer, which would mean traversing the list before adding the element.

#### Deletion
{% highlight python linenos %}
def list_delete(L, x):
    if x.prev != nil:
        x.prev.next = x.next
    else L.head = x.next
    if x.next != nil:
        x.next.prev = x.prev
{% endhighlight %}

This is $$\mathcal{O}(1)$$.

#### Summary
- Insertion: $$\mathcal{O}(1)$$
- Deletion: $$\mathcal{O}(1)$$
- Search: $$\mathcal{O}(n)$$

Search in linear time is no fun! Let's see how else we can do this.

### Binary search trees
The key property of binary search trees is:

- If `y` is in the left subtree of `x`, then `y.key < x.key`
- If `y` is in the right subtree of `x`, then `y.key >= x.key`

The tree `T` has a root `T.root`, and a height `h` (not necessarily the log of n, it can vary depending on the organization of the tree).

#### Querying a binary search tree
All of the following algorithms can be implemented in $$\mathcal{O}(h)$$.

##### Searching
{% highlight python linenos %}
def tree_search(x, k):
    if x == Nil or k == key[x]:
        return x
    if k < x.key:
        return tree_search(x.left, k)
    else:
        return tree_search(x.right, k)
{% endhighlight %}

##### Maximum and minimum
By the key property, the minimum is in the leftmost node, and the maximum in rightmost.

{% highlight python linenos %}
def tree_minimum(x):
    while x.left != Nil:
        x = x.left
    return x

def tree_maximum(x):
    while x.right != Nil:
        x = x.right
    return x
{% endhighlight %}

##### Successor
The successor or a node `x` is the node `y` such that `y.key` is the smallest key that is strictly larger than `x.key`.

There are 2 cases when finding the successor of `x`:

1. **`x` has a non-empty right subtree**: `x`'s successor is the minimum in the right subtree
2. **`x` has an empty right subtree**: We go left up the tree as long as we can (until node `y`), and and `x`'s successor is the parent of `y` (or `y` if it is the root)

{% highlight python linenos %}
def tree_successor(x):
    if x.right != Nil:
        return tree_minimum(x.right)
    y = x.parent
    while y != Nil and x == y.right:
        x = y
        y = y.parent
    return y
{% endhighlight %}

In the worst-case, this will have to traverse the tree upward, so it indeed runs in $$\mathcal{O}(h)$$.

#### Printing a binary search tree
![A sample binary search tree](/images/algorithms/binary_tree.png)

##### Inorder
- Print left subtree recursively
- Print root
- Print right subtree recursively

{% highlight python linenos %}
def inorder_tree_walk(x):
    if x != Nil:
        inorder_tree_walk(x.left)
        print x.key
        inorder_tree_walk(x.right)
{% endhighlight %}

This would print:

{% highlight text %}
1, 2, 3, 4, 5, 6, 7, 8, 9 10, 11, 12
{% endhighlight %}

This runs in $$\Theta(n)$$. Let's prove it.

$$T(n) = $$ runtime of `inorder_tree_walk` on a tree with $$n$$ nodes.

$$T(n)\leq (c+d)n + c, \qquad c, d > 0$$

**Base**: $$n = 0, \quad T(0) = c$$

**Induction**: Suppose that the tree rooted at $$x$$ has $$k$$ nodes in its left subtree, and $$n-k-1$$ nodes in the right.

$$ T(n) \leq T(k) + T(n-k-1) + c $$

$$ T(k) \leq (c+d)k + c $$

$$ T(n-k-1) \leq (c+d)(n-k-1) + c $$

Therefore:

$$ T(n) \leq (c+d)k + c + (c+d)(n-k-1) + c + d $$

$$ = (c+d)n + c - (c+d) + 2c $$

$$ \leq (c+d)n + c + (c -d) \leq (c+d)n + c $$

Therefore, we do indeed have $$\Theta(n)$$.

Preorder and postorder follow a very similar idea.

##### Preorder
- Print root
- Print left subtree recursively
- Print right subtree recursively

{% highlight python linenos %}
def inorder_tree_walk(x):
    if x != Nil:
        print x.key
        inorder_tree_walk(x.left)
        inorder_tree_walk(x.right)
{% endhighlight %}

This would print:

{% highlight text %}
8, 4, 2, 1, 3, 6, 5, 12, 10, 9, 11
{% endhighlight %}

##### Postorder
- Print left subtree recursively
- Print right subtree recursively
- Print root

{% highlight python linenos %}
def inorder_tree_walk(x):
    if x != Nil:
        inorder_tree_walk(x.left)
        inorder_tree_walk(x.right)
        print x.key
{% endhighlight %}

This would print:

{% highlight text %}
1, 3, 2, 5, 6, 4, 9, 11, 10, 12, 8
{% endhighlight %}

#### Modifying a binary seach tree
The data structure must be modified to reflect the change, but in such a way that the binary-search-tree property continues to hold.

##### Insertion
- Search for `z.key`
- When arrived at `Nil` insert `z` at that position

{% highlight python linenos %}
def tree_insert(T, z):
    # Search phase:
    y = Nil
    x = T.root
    while x != Nil:
        y = x
        if z.key < x.key:
            x = x.left
        else:
            x = x.right
    z.parent = y

    # Insert phase
    if y == Nil:
        T.root = z # Tree T was empty
    elsif z.key < y.key:
        y.left = z
    else:
        y.right = z
{% endhighlight %}

This runs in $$\mathcal{O}(h)$$.

##### Deletion
Conceptually, there are 3 cases:

1. If `z` has no children, remove it
2. If `z` has one child, then make that child take `z`'s position in the tree
3. If `z` has two children, then find its successor `y` and replace `z` by `y`

{% highlight python linenos %}
# Replaces subtree rooted at u with that rooted at v
def transplant(T, u, v):
    if u.parent == Nil: # If u is the root
        T.root = v
    elsif u == u.parent.left: # If u is to the left
        u.parent.left = v
    else: # If u is to the right
        u.parent.right = v 
    if v != Nil: # If v isn't the root
        v.parent = u.parent

# Deletes the subtree rooted at z
def tree_delete(T, z):
    if z.left == Nil: # z has no left child
        transplant(T, z, z.right) # move up the right child
    if z.right == Nil: # z has just a left child
        transplant(T, z, z.left) # move up the left child
    else: # z has two children
        y = tree_minimum(z.right) # y is z's successor
        if y.parent != z:
            # y lies within z's right subtree but not at the root of it
            # We must therefore extract y from its position
            transplant(T, y, y.right)
            y.right = z.right
            y.right.parent = y
        # Replace z by y:
        transplant(T, z, y)
        y.left = z.left
        y.left.parent = y
{% endhighlight %}

#### Summary
- **Query operations**: Search, max, min, predecessor, successor: $$\mathcal{O}(h)$$
- **Modifying operations**: Insertion, deletion: $$\mathcal{O}(h)$$

There are efficient procedures to keep the tree balanced (AVL trees, red-black trees, etc.).

### Summary
- **Stacks**: LIFO, insertion and deletion in $$\mathcal{O}(1)$$, with an array implementation with fixed capacity
- **Queues**: FIFO, insertion and deletion in $$\mathcal{O}(1)$$, with an array implementation with fixed capacity
- **Linked Lists**: No fixed capcity, insertion and deletion in $$\mathcal{O}(1)$$, supports search but $$\mathcal{O}(n)$$ time.
- **Binary Search Trees**: No fixed capacity, supports most operations (insertion, deletion, search, max, min) in time $$\mathcal{O}(h)$$.

## Dynamic Programming
The main idea is to remember calculations already made. This saves enormous amounts of computation, as we don't have to do the same calculations again and again.

There are two different ways to implement this:

### Top-down with memoization
Solve recursively but store each result in a table. *Memoizing* is remembering what we have computed previously.

As an example, let's calculate Fibonacci numbers with this technique:

{% highlight python linenos %}
def memoized_fib(n):
    let r = [0...n] be a new array
    for i = 0 to n:
        r[i] = - infinity # Initialize memory to -inf
    return memoized_fib_aux(n, r)

def memoized_fib_aux(n, r):
    if r[n] >= 0:
        return r[n]
    if n == 0 or n == 1:
        ans = 1
    else ans = memoized_fib_aux(n-1, r) + memoized_fib_aux(n-2, r)
    r[n] = ans
    return r[n]
{% endhighlight %}

This runs in $$\Theta(n)$$.

### Bottom-up
Sort the subproblems and solve the smaller ones first. That way, when solving a subproblem, we have already solved the smaller subproblems we need.

As an example, let's calculate Fibonacci numbers with this technique:

{% highlight python linenos %}
def bottom_up_fib(n):
    let r = [0 ... n] be a new array
    r[0] = 1
    r[1] = 1
    for i = 2 to n:
        r[i] = r[i-1] + r[i-2]
    return r[n]
{% endhighlight %}

This is also $$\Theta(n)$$.

### Rod cutting problem
The instance of the problem is:

- A length $$n$$ of a metal rods
- A table of prices $$p_i$$ for rods of lengths $$i = 1, ..., n$$

![List of prices for different rod lengths](/images/algorithms/rod_prices.png)

The objective is to decide how to cut the rod into pieces and maximize the price.

There are $$2^{n-1}$$ possible solutions (not considering symmetry), so we can't just try them all. Let's introduce the following theorem in an attempt at finding a better way:

***

#### Structural Theorem
If:

- The leftmost cut in an optimal solution is after $$i$$ units
- An optimal way to cut a solution of size $$n-i$$ is into rods of sizes $$s_1, s_2, ..., s_k$$

Then, an optimal way to cut our rod is into rods of size $$i, s_1, s_2, ..., s_k$$.

***

Essentially, the theorem say that to obtain an optimal solution, we need to cut the remaining pieces in an optimal way. This is the [optimal substructure property](https://en.wikipedia.org/wiki/Optimal_substructure). Hence, if we let $$r(n)$$ be the optimal revenue from a rod of length $$n$$, we can express $$r(n)$$ *recursively* as follows:

$$
r(n) = \begin{cases}
0 & \text{if } n = 0\\
max_{1\leq i \leq n}\{p_i + r(n-i)\} & \text{otherwise if } n \geq 1\\
\end{cases}
$$

#### Algorithm
Let's try to implement a first algorithm. This is a direct implementation of the recurrence relation above:

{% highlight python linenos %}
def cut_rod(p, n):
    id n == 0:
        return 0
    q = -inf
    for i = 1 to n:
        q = max(q, p[i] + cut_rod(p, n-i))
    return q
{% endhighlight %}

But implementing this, we see that it isn't terribly efficient &mdash; in fact, it's exponential. Let's try to do this with dynamic programming. Here, we'll do it in a memoized top-down approach.

{% highlight python linenos %}
def memoized_cut_rod(p, n):
    let r[0..n] be a new array
    Initialize all entries to -infinity
    return memoized_cut_rod_aux(p, n, r)

def memoized_cut_rod_aux(p, n, r):
    if r[n] >= 0: # if it has been calculated
        return r[n]
    if n == 0:
        q = 0
    else:
        q = - infinity
        for i = 1 to r:
            q = max(q, p[i] + memoized_cut_rod_aux(p, n-1, r))
    r[n] = q
    return q
{% endhighlight %}

Every problem needs to check all the subproblems. Thanks to dynamic programming, we can just sum them instead of multiplying them, as every subproblem is computed once at most. As we've seen earlier on with [insertion sort](#analysis), this is:

$$\sum_{i=1}^n {\Theta(i)} = \Theta(n^2)$$

The total time complexity is $$\mathcal{O}(n^2)$$. This is even clearer with the bottom up approach:

{% highlight python linenos %}
def bottom_up_cut_rod(p, n):
    let r[0..n] be a new array
    r[0] = 0
    for j = 1 to n:
        q = - infinity
        for i = 1 to j:
            q = max(q, p[i]+ r[j -1])
        r[j] = q
    return r[n]
{% endhighlight %}

There's a for-loop in a for-loop, so we clearly have $$\Theta(n^2)$$.

Top-down only solves the subproblems actually needed, but recursive calls introduce overhead.

#### Extended algorithm
{% highlight python linenos %}
def extended_bottom_up_cut_rod(p, n):
    let r[0..n] and s[0..n] be new arrays
    # r[n] will be the price you can get for a rod of length n
    # s[n] the cuts of optimum location for a rod of length n
    r[0] = 0
    for j = 1 to n:
        q = -infinity
        for i to j:
            if q < p[i] + r[j-i]: # best cut so far?
                q = p[i] + r[j-i] # save its price
                s[j] = i # and save the index!
    r[j] = q
    return (r, s)

def print_cut_rod_solution(p, n):
    (r, s) = extended_bottom_up_cut_rod(p, n)
    while n > 0:
        print s[n]
        n = n - s[n]
{% endhighlight %}

### When can dynamic programming be used?
- Optimal substructure
    + An optimal solution can be built by combining optimal solutions for the subproblems
    + Implies that the optimal value can be given by a recursive formula
- Overlapping subproblems


### Matrix-chain multiplication
- **Input**: A chain $$(A_1, A_2, ..., A_n)$$ of $$n$$ matrices, where for $$i=1, 2, ..., n$$, matrix $$A_i$$ has dimension $$p_{i-1}\times p_i$$.
- **Output**: A full parenthesization of the product $$A_1 A_2 ... A_n$$ in a way that minimizes the number of scalar multiplications.

We are not asked to calculate the product, only find the best parenthesization. Multiplying a matrix of size $$p\times q$$ with one of $$q\times r$$ takes $$pqr$$ scalar multiplications.

We'll have to use the following theorem:

***

#### Optimal substructure theorem
If:

- The outermost parenthesization in an optimal solution is $$(A_1 A_2 ... A_i)(A_{i+1}A_{i+2}...A_n)$$
- $$P_L$$ and $$P_R$$ are optimal pernthesizations for $$A_1 A_2 ... A_i$$ and $$A_{i+1}A_{i+2}...A_n$$ respectively

Then $$((P_L)\cdot (P_R))$$ is an optimal parenthesization for $$A_1 A_2 ... A_n$$

***

See [the slides](http://moodle.epfl.ch/pluginfile.php/1745790/mod_resource/content/1/Lecture11.pdf) for proof.

Essentially, to obtain an optimal solution, we need to parenthesize the two remaining expressions in an optimal way. 

Hence, if we let $$m[i, j]$$ be the optimal value for chain multiplication of matrices $$A_i, ..., A_j$$ (meaning, how many multiplications we can do at best), we can express $$m[i, j]$$ *recursively* as follows:

$$
\begin{cases}
0 & \text{if } i=j \\
\min_{i \leq k < j} \{m[i, k] + m[k+1, j] + p_{i-1} p_k p_j\} & \text{otherwise if } i < j \\
\end{cases}
$$

That is the minimum of the left, the right, and the number of operations to combine them.




{% highlight python linenos %}
def matrix_chain_order(p):
    n = p.length - 1
    let m[1..n, 1..n] and s[1..n, 1..n] be new tables
    for i = 1 to n: # Initialize all to 0
        m[i, i] = 0
    for l = 2 to n: # l is the chain length
        for i = 1 to n - l + 1:
            j = i + l - 1
            m[i, j] = infinity
            for k = i to j - 1:
                q = m[i, k] + m[k+1, j] + p[i-1]p[k]p[j]
                if q < m[i, j]:
                    m[i, j] = q # store the number of multiplications
                    s[i, j] = k # store the optimal choice
    return m and s
{% endhighlight %}

The runtime of this is $$\Theta(n^3)$$.

![Matrix multiplication tables, flipped by 45 degrees](/images/algorithms/matrix-mult-tables.png)

To know how to split up $$A_i A_{i+1} ... A_j$$ we look in `s[i, j]`. This split corresponds to `m[i, j]` operations. To print it, we can do:

{% highlight python linenos %}
def print_optimal_parens(s, i, j):
    if i == j:
        print "A_" + i
    else:
        print "("
        print_optimal_parens(s, i, s[i, j])
        print_optimal_parens(s, s[i, j]+1, j)
        print ")"
{% endhighlight %}

### Longest common subsequence
- **Input**: 2 sequences, $$X = (x_1, ..., x_m)$$ and $$Y = (y_1, ..., y_n)$$
- **Output**: A subsequence common to both whose length is longest. A subsequence doesn't have to be consecutive, but it has to be in order.

***

#### Theorem
Let $$Z = (z_1, z_2, ..., z_k)$$ be any LCS of $$X_i$$ and $$Y_j$$

1. If $$x_i = y_j$$ then $$z_k = x_i = y_j$$ and $$Z_{k-1}$$ is an LCS of $$X_{i-1}$$ and $$Y_{j-1}$$
2. If $$x_i \neq y_j$$ then $$z_k \neq x_i$$ and $$Z$$ is an LCS of $$X_{i-1}$$ and $$Y_j$$
3. If $$x_i \neq y_j$$ then $$z_k \neq y_i$$ and $$Z$$ is an LCS of $$X_i$$ and $$Y_{j-1}$$

##### Proof
1. If $$z_k \neq x_i$$ then we can just append $$x_i = y_j$$ to $$Z$$ to obtain a common subsequence of $$X$$ and $$Y$$ of length $$k+1$$, which would contradict the supposition that $$Z$$ is the *longest* common subsequence. Therefore, $$z_k = x_i = y_j$$

Now onto the second part: $$Z_{k-1}$$ is an LCS of $$X_{i-1}$$ and $$Y_{j-1}$$ of length $$(k-1)$$. Let's prove this by contradiction; suppose that there exists a common subsequence $$W$$ with length greater than $$k-1$$. Then, appending $$x_i = y_j$$ to W produces a common subsequence of X and Y whose length is greater than $$k$$, which is a contradiction.

2. If there were a common subsequence $$W$$ of $$X_{i-1}$$ and $$Y$$ with length greater than $$k$$, then $$W$$ would also be a common subsequence of $$X$$ and $$Y$$ length greater than $$k$$, which contradicts the supposition that $$Z$$ is the LCS.

3. This proof is symmetric to 2.

***

If $$c[i, j]$$ is the length of a LCS of $$X_i$$ and $$Y_i$$, then:

$$
c[i, j] =
\begin{cases}
0 & \text{if } i = 0 \text{ or } j = 0 \\
c[i-1, j-1] + 1 & \text{if } i,j>0 \text{ and } x_i = y_j \\
\max{(c[i-1, j], c[i, j-1])} & \text{if } i,j>0 \text{ and } x_i \neq y_j \\
\end{cases}
$$


Using this recurrence, we can fill out a table of dimensions $$i \times j$$. The first row and the first colum will obviously be filled with `0`s. Then we traverse the table row by row to fill out the values according to the following rules.

1. If the characters at indices `i` and `j` are equal, then we take the diagonal value (above and left) and add 1.
2. If the characters at indices `i` and `j` are different, then we take the max of the value above and that to the left.

Along with the values in the table, we'll also store where the information of each cell was taken from: left, above or diagonally (the max defaults to the value above if left and above are equal). This produces a table of of numbers and arrows that we can follow from bottom right to top left:

<figure>
    <img src="/images/algorithms/lcs-table.png" alt="An i*j table of values and arrows, as generated by the LCS algorithm below">
    <figcaption>$$X = (B, A, B, D, B, A), \quad Y = (D, A, C,B, C, B, A)$$</figcaption>
</figure>

The diagonal arrows in the path correspond to the characters in the LCS. In our case, the LCS has length 4 and it is `ABBA`.


{% highlight python linenos %}
def lcs-length(X, Y, m, n):
    let b[1..m, 1..n] and c[0..m, 0..n] be new tables
    # Initialize 1st row and column to 0
    for i = 1 to m:
        c[i, 0] = 0
    for j = 0 to n:
        c[0, j] = 0
    for i = 1 to m:
        for j = 1 to n:
            if X[i] = Y[j]:
                c[i, j] = c[i-1, j-1] + 1
                b[i, j] = "↖" # up left
            elsif c[i-1, j] >= c[i, j-1]:
                c[i, j] = c[i-1, j]
                b[i, j] = "↑" # up
            else:
                c[i, j] = c[i, j-1]
                b[i, j] = "←" # left
    return b, c


def print-lcs(b, X, i, j):
    if i == 0 or j == 0:
        return
    if b[i, j] == "↖": # up left
        print-lcs(b, X, i-1, j-1)
        print X[i]
    elsif b[i, j] == "↑": # up
        print-lcs(b, X, i-1, j)
    elsif b[i, j] == "←": # left
        print-lcs(b, X, i, j-1)
{% endhighlight %}

The runtime of `lcs-length` is dominated by the two nested loops; runtime is $$\Theta(m\cdot n)$$.

The runtime of `print-lcs` is $$\mathcal(O)(n)$$, where $$n=i+j$$.

### Optimal binary search trees
Given a sequence of keys $$K=(k_1, k_2, \dots, k_n)$$ of distinct keys, sorted so that $$k_1 < k_2 < \dots < k_n$$. We want to build a BST. Some keys are more popular than others: key $$K_i$$ has probability $$p_i$$ of being searched for. Our BST should have a minimum expected search cost.

The cost of searching for a key $$k_i$$ is $$\text{depth}_T (k_i) + 1$$ (we add one because the root is at height 0 but has a cost of 1). The expected search cost would then be:

$$\mathbb{E}[\text{seach cost in } T] = \sum_{i=1}^n {(\text{depth}_T(k_i) + 1)}p_i = 1 + \sum_{i=1}^n {\text{depth}_T(k_i)}\cdot p_i$$

Optimal BSTs might not have the smallest height, and optimal BSTs might not have highest-probability key at root.

Let $$e[i, j]$$ denote the expected search cost of an optimal BST of $$k_i \dots k_j$$.

$$
e[i, j] = \begin{cases}
0 & \text{if } i = j + 1 \\
min_{i\leq r \leq j}{(e[i, r-1] + e[r+1, j]) + \sum_{\ell =i}^j {p_\ell}}& \text{if } i \leq j\\
\end{cases}
$$

With the following inputs:

![An example set of inputs](/images/algorithms/optimal-bst-input.png)

We can fill out the table as follows:

![The optimal BST table filled out according to the recurrence relationship](/images/algorithms/optimal-bst-table.png)

To compute something in this table, we should have already computed everything to the left, and everything below. We can start out by filling out the diagonal, and then filling out the diagonals to its right.

{% highlight python linenos %}
def optimal-bst(p, q, n):
    # Copy the code here
{% endhighlight %}

The runtime is $$\Theta(n^3)$$: there are $$\Theta(n^2) cells to fill in, most of which take $$\Theta(n)$$ to fill in.

## Review of the course

### Growth of functions
1. The logs: $$\log{N}, \log^2{N}, \dots$$
2. The polynomials: $$\sqrt{N}, 20N, N^2, \dots$$
3. The exponentials: $$\sqrt{4^N}=2^N, 3^N, ...$$

### Sorting
- **Insertion sort**: Put the numers in their correct order one at a time. $$\Theta(n^2)$$, worst case occurs when the input is in reverse sorted order
- **Merge sort**: A divide and conquer algorithm. The merge works by having two stacks of cards, adding a sentinel at the bottom, and then repeatedly  just taking the smallest of the two.
    + *Time to divide*: $$\Theta(1)$$
    + *Time to combine* $$\Theta(n), \text{ where } n=r-p$$
    + *Number of subproblems and their size*: 2 subproblems of size $$n/2$$.
    + *Recurrence*:

$$T(n) = \begin{cases}
\Theta(1) & \text{if } n \leq 1 \\
2T(n/2)+\Theta(n) & \text{otherwise} \\
\end{cases}
$$
