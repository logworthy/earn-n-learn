# earn-n-learn - simulations of the multi-armed bandit problem

http://en.wikipedia.org/wiki/Multi-armed_bandit

We have a choice of several options, n={1,...,20}, each outcome yielding a success or failure according to some unknown function.

Further, reward on success or failure is a function of both the likelihood of success but also the option that is chosen.

Our objective is to learn about the underlying function whilst also exploiting it to achieve reward.

This simulation compares two approaches:

  1.  Epsilon-greedy strategy:  from our current perspective, we always take the greedy option (the choice expected to yield greatest reward).  However, in epsilon % of cases (here 10%), we will choose randomly from all possible options.
  2.  Beta strategy:  we take historical successes and failures at each point as inputs to a beta distribution.  We take a greedy strategy, except that our beliefs (and hence expectations of reward) at each point are drawn randomly from the beta distribution.

For this simulation, we start with an initial somewhat-supported belief that the underlying function is linear.  However, the actual underlying function is a generalised logistic function.

The reward function used is 20-(p-1)*n, where p is the chance of success and n is the option chosen.

##Epsilon-greedy strategy:
![current vs true belief](/k1.png?raw=true "current vs true belief")

Uniform random sampling at 10% has done little to improve our knowledge of the underlying function.

![current vs true reward](/k2.png?raw=true "current vs true reward")

The reward function is similarly scattered, though our estimation of n=11 has become quite accurate.

![distribution of picks](/k3.png?raw=true "distribution of picks")

You can see that most of the time we chose n=11, with a random uniform sampling of the other possibilities.

![cumulative penalty](/k4.png?raw=true "cumulative penalty")

Cumulative penalty is increasing at a linear rate.  Given the similar payoff for n=10 and n=11, the algorithm may be trapped into always choosing n=11, thus continuing this trend indefinitely.

##Beta strategy:
![current vs true belief](/beta1.png?raw=true "current vs true belief")

We have a much better belief about the shape of the curve, especially the upper end.

![current vs true reward](/beta2.png?raw=true "current vs true reward")

After 1000 trials, the optimal point has been identified.

![distribution of picks](/beta3.png?raw=true "distribution of picks")

Although we chose n=11 a lot initially, belief has now shifted to n=10 as the optimal point.  Some points have been chosen more frequently than the epsilon-gamma strategy, but others (n<=8) haven't been chosen at all.

![cumulative penalty](/beta4.png?raw=true "cumulative penalty")

Increased diversity in the initial picks has led to greater cumulative error after 1000 trials.  However, the rate of error is decreasing and can be expected to converge to 0 as trials approach infinity.

##Conclusion:
In this example epsilon-gamma yields a lower total penalty over the first 1000 trials, however it is less informative about the overall shape of the function.  The beta strategy provides more information about the shape of the function, an in the long run is likely to have the lowest total penalty.

It is important to be aware of all the key parameters - initial beliefs, the actual demand function, the reward function, epsilon and the number of trials.  Changing any of these could meaningfully alter the results, so it is recommended that you conduct more simulations tailored to your specific situation before choosing either approach.

##References / Further Reading:
* http://stevehanov.ca/blog/index.php?id=132
* http://blog.locut.us/2011/09/22/proportionate-ab-testing/
* http://en.wikipedia.org/wiki/Multi-armed_bandit