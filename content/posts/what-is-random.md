---
title: What is Randomness?
date: 2023-12-12
---

Short Answer: You call something is random because the best thing you can tell about it is just a guess.


## Long Answer

An intesting example that enligntened me was the famous coin toss problem.
We believe that the coin toss is a 50/50 experiment.
That's because we toss coin for deciding which side will take the turn first in a game. We believe it is fair.
But recent findings suggest that our belief could be wrong: the experiment is not 50/50.
In fact, a coin tends to land on the same side they started for a probability of 50.8%.

But how? To answer this, we have to go back to the first place and ask ourselves:
"Why, in the first place, did we believe that a coin toss is fair?"
I want to put it this way: because we were not able to ponder all the statistical and physical intricacies.
But now we are. Therefore, we have better ways to understand the probability of coin tosses.

This framework that claims if we can see more we can guess better works for various cases.
The best examples are from cryptography, which uses this notion extensively.

1. MD5 hash used to be considered secure, because the best way to predict the outcome of the hash was just randomly guessing. But now we have more powerful computers and better algorithms to guess the output, it is not random anymore.
2. Cryptographic primitives and schemes (one-way functions, RSA, Elliptic Curves) are considered to be secure at the time of writing, because we can't find solutions for such problems in a reasonable amount of time. The best way to try to solve such problems is just guessing. Any ciphertext constructed using such problems are seemingly random (computationally indistinguishable).


## True Randomness

Therefore, a notion of randomness seems like it all made up:
if we hide information that somebody only can do is just guess, we can claim it is random.

But it seems like, in this physical world, a true randomness exists.
Some physical phenomena, widely studied by quantom physics, are truly random,
because it is physically infeasible to predict a result of such phenomena.


