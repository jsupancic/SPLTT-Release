% JSS3 2012-03-20
function f1 = f1score(prec,recl)
    f1 = 2*prec*recl/(prec+recl);
end
