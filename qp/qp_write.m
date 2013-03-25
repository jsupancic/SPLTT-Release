% JSS3 - 2012.7.3
% To weight a sample,
% (Primal) min_{w,e}  .5*||w||^2 + C*sum_i v_i*e_i
%               s.t.   w*x_i >= b_i - e_i 
% if u_i = v_i * e_i
% then w*x_i >= b_i - u_i/v_i or 
% w*v_i*x_i >= v_i*b_i - u_i with .5*||w||^2 + C*sum_i u_i
% so multiply the feature and the margin by the weight (2nd and 3rd arguments) 
function qp = qp_write(qp,feat,margin,slack,isPos)
    qp = qp.write(feat,margin,slack,isPos);
end
