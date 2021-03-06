# Utility packages
library(pacman)
p_load(R2HTML, tidyverse)

# Data packages
packages = c("datasets", "boot", "DAAG", "lmec", "gamclass", "KMsurv", "robustbase", "car", "carData", "cluster", "COUNT", "Ecdat", "gap", "ggplot2", "HistData", "lattice", "MASS", "plm", "plyr", "pscl", "reshape2", "rpart", "sandwich", "sem",  "survival", "vcd", "Zelig", "HSAUR", "psych", "quantreg", "geepack", "texmex", "multgee", "evir", "lme4", "mosaicData", "ISLR", "Stat2Data", "hwde", "mi", "mediation")
p_load(char = packages)

# Functions
get_doc = function(package = 'mi', dataset = 'nlsyV') {
    help.ref = try(help(eval(dataset), package=eval(package)), silent = TRUE)
    out = try(utils:::.getHelpFile(help.ref), silent = TRUE)
    return(out)
}

get_data = function(package = 'mi', dataset = 'nlsyV') {
    e = new.env(hash = TRUE, parent = parent.frame(), size = 29L)
    data(list = dataset, package = package, envir = e)
    out = e[[dataset]]
    return(out)
}

tidy_data = function(dat) {
    if(class(dat)[1]=='ts'){
        dat = try(data.frame('time' = time(dat), 'value' = dat), silent = TRUE)
    } else {
        dat = try(as.data.frame(dat), silent = TRUE)
    }
    if (class(dat)[1] == 'data.frame') {
        out = dat
    } else {
        out = NA
        class(out) = 'try-error'
    }
    return(out)
}

write_data = function(i) {
    package = index$Package[i]
    dataset = index$Item[i]
    dat = data[[i]]
    doc = docs[[i]]
    cat(package, ' -- ', dataset, '\n')
    try(dir.create('csv'), silent = TRUE)
    try(dir.create('doc'), silent = TRUE)
    try(dir.create(paste0('csv/', package)), silent = TRUE)
    try(dir.create(paste0('doc/', package)), silent = TRUE)
    fn_csv = paste0('csv/', package, '/', dataset, '.csv')
    fn_doc = paste0('doc/', package, '/', dataset, '.html')
    write.csv(data[[i]], file = fn_csv)
    tools::Rd2HTML(docs[[i]], out = fn_doc)
}

# Index
index = data(package=packages)$results[,c(1,3,4)]
index = data.frame(index, stringsAsFactors=FALSE)

# Extract Data and Docs and exclude non-data.frames and errors
data = lapply(1:nrow(index), function(i) get_data(index$Package[i], index$Item[i]))
docs = lapply(1:nrow(index), function(i) get_doc(index$Package[i], index$Item[i]))
data = lapply(data, tidy_data)
idx1 = sapply(docs, class) != 'try-error'
idx2 = sapply(data, class) != 'try-error'
idx = as.logical(pmin(idx1, idx2))
data = data[idx]
docs = docs[idx]
index = index[idx,]

# Write to file
for (i in 1:nrow(index)) {
    write_data(i)
}

# Index
hasbeen = function(x) {
    out = try(any(sapply(x, function(y) length(unique(na.omit(y))) == 2)), silent = TRUE)
    if ('try-error' %in% class(out)) {
        out = FALSE
    } 
    return(out)
}
index$Rows = sapply(data, nrow)
index$Cols = sapply(data, ncol)
index$has_logical = sapply(data, function(x) 'logical' %in% sapply(x, class))
index$has_binary = sapply(data, hasbeen)
index$has_numeric = sapply(data, function(x) 'numeric' %in% sapply(x, class))
index$has_character = sapply(data, function(x) 'character' %in% sapply(x, class))
index$CSV = paste('https://raw.github.com/vincentarelbundock/Rdatasets/master/csv/',
                  index$Package, '/', index$Item, '.csv', sep='')
index$Doc = paste('https://raw.github.com/vincentarelbundock/Rdatasets/master/doc/',
                  index$Package, '/', index$Item, '.html', sep='')
index = index[order(index$Package, index$Item),]

# Index CSV
write.csv(index, file = 'datasets.csv', row.names = FALSE)

# Index HTML
index$CSV = paste("<a href='", index$CSV, "'> CSV </a>", sep='')
index$Doc = paste("<a href='", index$Doc, "'> DOC </a>", sep='')
unlink('datasets.html')
rss = '
<style type="text/css">
  tr:nth-child(even){
          background-color: #E5E7E5;
  }
</style>
'
cat(rss, file='datasets.html')
HTML(index, file='datasets.html', row.names=FALSE, append=TRUE)

