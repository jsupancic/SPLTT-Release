% Deva Ramanan 2012-03-19
% qp_init(len,nmax,C)
%
%
% Define global QP problem
% 2012-04-25 JSS3 made it local for parfor.
%
% (Primal) min_{w,e}  .5*||w||^2 + C*sum_i e_i
%               s.t.   w*x_i >= b_i - e_i 
%
% (Dual)   max_{a}   -.5*sum_ij a_i(x_ix_j)a_j + sum_i b_i*a_i
%               s.t.   0 <= a_i <= C
%
% where w = sum_i a_i x_i
%
% qp.x(:,i) = x_i where size(qp.x) = [len nmax]
% qp.b(:,i) = b_i
% qp.d(i)   = ||x(i)||^2
% qp.a(i)   = a_i
% qp.w      = sum_i a_i x_i
% qp.l      = sum_i b_i a_i
% qp.n      = number of constraints
% qp.ub     = .5*||qp.w||^2 + C*sum_i e_i
% qp.lb     = -.5*sum_ij a_i(x_ix_j)a_j + sum_i b_i*a_i
% qp.C      = C
% qp.svfix  = pointers to examples that are always kept in memory
% JSS3 2012-03-18
% init a blank Quadratic Program...
function [qp,nmax] = qp_init(model,C)
    qp = QP(model,C);
    nmax = qp.nmax;
end
