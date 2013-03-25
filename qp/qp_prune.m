% Re-indexes qp.x to begin with active consrtaints (eg, the support vectors)
function [qp,n] = qp_prune(qp)
    [qp,n] = qp.prune();
end
