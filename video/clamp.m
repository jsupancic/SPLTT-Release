% JSS3 2012-04-13
% restrict a value to a range...
function val = clamp(var_min,val,var_max)    
    val = max(var_min,val);
    val = min(var_max,val);
end
