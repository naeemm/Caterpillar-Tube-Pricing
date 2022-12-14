options(scipen = 10)

wd <- "/home/mnaeem/r.codes/CaterpillarTubePricing/"
setwd(wd)

lst <- list.files(path = (paste(wd,"input/", sep = "")))
iteration <-  length(lst)
iteration <- 2 * (iteration -1) # every file is scanned twice


for(f in dir("out/")){
  fn <-(paste(wd,"out/", f, sep = ""))
  file.remove(fn)
}


cat("\014")

### Build train and test db
test = read.csv("input/test_set.csv")
train = read.csv("input/train_set.csv")

train$id = -(1:nrow(train))
test$cost = 0

train = rbind(train, test)
j <- 1

cat("\014")

### Merge datasets if only 1 variable in common
continueLoop = TRUE
while(continueLoop){
  continueLoop = FALSE
  for(f in dir("input/")){
    d = read.csv(paste0("input/", f))
    commonVariables = intersect(names(train), names(d))
    ## print (f)     ##print(names(d))     ##print("----------------")     print ( length(commonVariables))
    if(length(commonVariables) >= 1){
      train = merge(train, d, by = commonVariables, all.x = TRUE)
      continueLoop = TRUE
     # print(dim(train))
      
      fn <- paste(toString(j),f, sep=".")
      fn <- paste("out" , fn, sep="/")
      
      write.csv(names(train), fn, row.names = TRUE, quote = FALSE)
      write.csv(train, paste("out/train" , j  , "csv", sep = ".") , row.names = TRUE, quote = FALSE)
      
      j <- j +1
      
      if (j > iteration)
        continueLoop = FALSE
    }
  }
}

cat("\014")


### Clean NA values
for(i in 1:ncol(train)){
  if(is.numeric(train[,i])){
    train[is.na(train[,i]),i] = -1
  }else{
    train[,i] = as.character(train[,i])
    train[is.na(train[,i]),i] = "NAvalue"
    train[,i] = as.factor(train[,i])
  }
}

### Clean variables with too many categories
for(i in 1:ncol(train)){
  if(!is.numeric(train[,i])){
    freq = data.frame(table(train[,i]))
    freq = freq[order(freq$Freq, decreasing = TRUE),]
    train[,i] = as.character(match(train[,i], freq$Var1[1:30]))
    train[is.na(train[,i]),i] = "rareValue"
    train[,i] = as.factor(train[,i])
  }
}

write.csv(train, "train.csv", row.names = TRUE, quote = FALSE)

test = train[which(train$id > 0),]
train = train[which(train$id < 0),]


## write.csv(test, "test.csv", row.names = TRUE, quote = FALSE)
## write.csv(train, "train.csv", row.names = TRUE, quote = FALSE)

###
### Evaluate RF predictions by splitting the train db in 80%/20%
###

### Randomforest
library(randomForest)

# dtrain_cv = train[which(train$id %% 5 > 0),]
# dtest_cv = train[which(train$id %% 5 == 0),]
# 
# ### Train randomForest on dtrain_cv and evaluate predictions on dtest_cv
# set.seed(123)
# rf1 = randomForest(dtrain_cv$cost~., dtrain_cv[,-match(c("id", "cost"), names(dtrain_cv))], ntree = 10, do.trace = 2)
# 
# pred = predict(rf1, dtest_cv)
# sqrt(mean((log(dtest_cv$cost + 1) - log(pred + 1))^2)) # 0.2589951
# 
# ### With log transformation trick
# set.seed(123)
# rf2 = randomForest(log(dtrain_cv$cost + 1)~., dtrain_cv[,-match(c("id", "cost"), names(dtrain_cv))], ntree = 10, do.trace = 2)
# pred = exp(predict(rf2, dtest_cv)) - 1
# 
# sqrt(mean((log(dtest_cv$cost + 1) - log(pred + 1))^2)) # 0.2410004

### Train randomForest on the whole training set
rf = randomForest(log(train$cost + 1)~., train[,-match(c("id", "cost"), names(train))], ntree = 20, do.trace = 2)

pred = exp(predict(rf, test)) - 1

submitDb = data.frame(id = test$id, cost = pred)
submitDb = aggregate(data.frame(cost = submitDb$cost), by = list(id = submitDb$id), mean)

write.csv(submitDb, "submit.csv", row.names = FALSE, quote = FALSE)

