### inspiration:
# http://blog.locut.us/2011/09/22/proportionate-ab-testing/
# http://stevehanov.ca/blog/index.php?id=132

# Earn & Learn
# - start with a current belief
# - draw based on that belief
# - apply a reward function to each draw
# - execute based on the reward function
# - update current belief based on result of execution

install.packages(c('data.table', 'plyr', 'ggplot2'))
library(data.table)
library(plyr)
library(ggplot2)

########## FUNCTIONS ##########

# Range to explore functions
numeric_variable <- 1:20

logistic_function <- function(x) {
  0.25+0.5/(1+exp(-(1*(x-12)+0.1)))
}

linear_function <- function(x) {
  0.25+x*0.025
}

# Draw from the beta dist
draw_belief <- Vectorize(function(s, f) {
  rbeta(1,s,f)
})

# reward function
# takes a probability and an index
# returns an outcome
reward_function <- function(p,i) {
  20-(p-1)*i
}

# Evaluate the result of a draw
evaluate_draw <- function(i) {
  p <- logistic_function(draw_result)
  outcome <- sample(c(0,1),1,replace=TRUE,prob=(c(1-p, p)))
  return(outcome)
}

# Express beliefs as a function
belief_as_function <- function(x) {
  aaply(
    .data=numeric_variable
    , .margins=1
    , .fun=function(i) {
      return(x$successes[i]/(x$successes[i]+x$failures[i]))
    }
  )
}

####### ITERATE #########

# Current belief - linear
current_belief_beta <- list(
  successes=round(rep(20, 20) * linear_function(numeric_variable))
  , failures=20-round(rep(20, 20) * linear_function(numeric_variable))
)

current_belief_k <- list(
  successes=round(rep(20, 20) * linear_function(numeric_variable))
  , failures=20-round(rep(20, 20) * linear_function(numeric_variable))
)

# Prep
trials <- 1000
belief_list_beta <- list()
pick_list_beta <- list()
belief_list_k <- list()
pick_list_k <- list()

# Main loop
for (k in 1:trials) {

  #### Beta-dist apppraoch ####
  
  # randomly draw from beta dist for each value we have a belief for
  draw <- draw_belief(
    current_belief_beta$successes
    , current_belief_beta$failures
  )
  
  # apply reward to the random draws
  weighted_draws <- reward_function(draw, numeric_variable)
  
  # Find the best result after reward
  draw_result <- min(which(weighted_draws == max(weighted_draws)))
  
  # Draw from that distro
  outcome <- evaluate_draw(draw_result)
  
  # Update beliefs
  if (outcome) {
    current_belief_beta$successes[draw_result] <- current_belief_beta$successes[draw_result]+1
  } else {
    current_belief_beta$failures[draw_result] <- current_belief_beta$failures[draw_result]+1
  }
  
  ### record data
  
  # what was our belief after that iteration?
  belief_list_beta[[length(belief_list_beta)+1]] <- data.table(
    iteration=k
    , n=numeric_variable
    , val=belief_as_function(current_belief_beta)
    , wgt=reward_function(belief_as_function(current_belief_beta), numeric_variable)
  )
  
  # which choice did we pick?
  pick_list_beta[[length(pick_list_beta)+1]] <- data.table(
    iteration=k
    , pick=draw_result
    , result=reward_function(logistic_function(draw_result), draw_result)
  )
  
  #### 10% approach
  
  # chance to just sample at random
  if (runif(1,0,1) <= 0.1) {
    draw_result <- sample(numeric_variable, 1)
  } else {
    
    # choose the best point to our current knowledge
    weighted_draws <- reward_function(belief_as_function(current_belief_k), numeric_variable)
    draw_result <- min(which(weighted_draws == max(weighted_draws)))
  }
  
  # Draw from that distro
  outcome <- evaluate_draw(draw_result)
  
  # Update beliefs
  if (outcome) {
    current_belief_k$successes[draw_result] <- current_belief_k$successes[draw_result]+1
  } else {
    current_belief_k$failures[draw_result] <- current_belief_k$failures[draw_result]+1
  }
  
  ### record data
  
  # what was our belief after that iteration?
  belief_list_k[[length(belief_list_k)+1]] <- data.table(
    iteration=k
    , n=numeric_variable
    , val=belief_as_function(current_belief_k)
    , wgt=reward_function(belief_as_function(current_belief_k), numeric_variable)
  )
  
  # which choice did we pick?
  pick_list_k[[length(pick_list_k)+1]] <- data.table(
    iteration=k
    , pick=draw_result
    , result=reward_function(logistic_function(draw_result), draw_result)
  )
  
}

belief_table_beta <- Reduce(rbind, belief_list_beta)
belief_table_k <- Reduce(rbind, belief_list_k)
pick_table_beta <- Reduce(rbind, pick_list_beta)
pick_table_k <- Reduce(rbind, pick_list_k)

####### RESULTS #########

# calculate the best possible outcoming, and a running tally of difference
pick_table_beta[,best:=reward_function(logistic_function(10),10)]
pick_table_beta[,tally:=cumsum(result-best)]
pick_table_k[,best:=reward_function(logistic_function(10),10)]
pick_table_k[,tally:=cumsum(result-best)]


#plot epsilon-gamma 
p1 <- ggplot(belief_table_k[iteration %in% c(1,100,1000,10000),], aes(x=n, y=val)) +
  geom_line(aes(color="Current Belief")) +
  geom_line(data=data.frame(n=1:20, val=logistic_function(1:20)), aes(color="True Belief"))+
  scale_color_discrete(guide=guide_legend(""))+
  ggtitle("Current vs True Belief, by Iteration")+
  ylab("Probability")+
  facet_wrap('iteration')

p2 <- ggplot(belief_table_k[iteration %in% c(1,100,1000,10000),], aes(x=n, y=wgt)) +
  geom_line(aes(color="Current Reward")) +
  geom_line(data=data.frame(n=1:20, wgt=reward_function(logistic_function(1:20), 1:20)), aes(color="Actual Reward"))+
  scale_color_discrete(guide=guide_legend(""))+
  ggtitle("Current vs True Reward, by Iteration")+
  ylab("Probability")+
  facet_wrap('iteration')

p3 <- ggplot(pick_table_k, aes(x=pick)) + geom_histogram()+
  ylab("Times Chosen")+
  xlab("Value Picked")+
  ggtitle("Distribution of Picks")

p4 <- ggplot(pick_table_k, aes(x=iteration, y=tally)) + geom_line() +
  ylab("Penalty vs Optimal Choice") +
  xlab("Iteration")+
  ggtitle("Cumulative Penalty (Opportunity Cost) by Iteration")

png("k1.png", 600, 400, res=96)
p1
dev.off()
png("k2.png", 600, 400, res=96)
p2
dev.off()
png("k3.png", 600, 400, res=96)
p3
dev.off()
png("k4.png", 600, 400, res=96)
p4
dev.off()


# plot beta
p1 <- ggplot(belief_table_beta[iteration %in% c(1,100,1000,10000),], aes(x=n, y=val)) +
  geom_line(aes(color="Current Belief")) +
  geom_line(data=data.frame(n=1:20, val=logistic_function(1:20)), aes(color="True Belief"))+
  scale_color_discrete(guide=guide_legend(""))+
  ggtitle("Current vs True Belief, by Iteration")+
  ylab("Probability")+
  facet_wrap('iteration')

p2 <- ggplot(belief_table_beta[iteration %in% c(1,100,1000,10000),], aes(x=n, y=wgt)) +
  geom_line(aes(color="Current Reward")) +
  geom_line(data=data.frame(n=1:20, wgt=reward_function(logistic_function(1:20), 1:20)), aes(color="Actual Reward"))+
  scale_color_discrete(guide=guide_legend(""))+
  ggtitle("Current vs True Reward, by Iteration")+
  ylab("Probability")+
  facet_wrap('iteration')

p3 <- ggplot(pick_table_beta, aes(x=pick)) + geom_histogram()+
  ylab("Times Chosen")+
  xlab("Value Picked")+
  ggtitle("Distribution of Picks")

p4 <- ggplot(pick_table_beta, aes(x=iteration, y=tally)) + geom_line() +
  ylab("Penalty vs Optimal Choice") +
  xlab("Iteration")+
  ggtitle("Cumulative Penalty (Opportunity Cost) by Iteration")

png("beta1.png", 600, 400, res=96)
p1
dev.off()
png("beta2.png", 600, 400, res=96)
p2
dev.off()
png("beta3.png", 600, 400, res=96)
p3
dev.off()
png("beta4.png", 600, 400, res=96)
p4
dev.off()
