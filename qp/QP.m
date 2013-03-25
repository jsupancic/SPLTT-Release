% JSS3 - 2012.7.26
% This is a class defining a Quadratic Program
% OOP interface to the methods in this directory
% (Primal) min_{w,e}  .5*||w||^2 + C*sum_i e_i
%               s.t.   w*x_i >= b_i - e_i 
%                      e_i >= 0
%
% (Dual)   max_{a}   -.5*sum_ij a_i(x_ix_j)a_j + sum_i b_i*a_i
%               s.t.   0 <= a_i <= C
classdef QP
    properties(SetAccess = protected)
        % Define global QP problem using 1GB of memory
        % 2e7 = 2GB
        % 5e6 = 500 MB
        QP_SIZE;
        nmax;
        x;
        b;
        d;
        a;
        sv;
        % JSS3 2012-5-26, which examples are positive?
        pos;
        w;
        n;
        ub;
        lb;
        l;
        C;
        svfix;
        lb_old;
        obj;
        
        % prevent addition of duplicate features using a map of md5
        % hashes
        containment;
    end
    
    methods
        % getter for n
        function n = get_n(obj)
            n = obj.n;
        end
        
        % getter for nmax
        function nmax = get_nmax(obj)
            nmax = obj.nmax;
        end
        
        function C = getC(obj)
            C = obj.C;
        end
        
        % CTOR
        function obj = QP(model,C)
            if nargin == 1
                % Copy CTOR
                prps = properties(model);
                for iter = 1:length(prps)
                    obj.(prps{iter}) = model.(prps{iter});
                end
            elseif nargin == 2
                obj = obj.init(model,C);
            end
        end
        
        function obj = init(obj,model,C)
            % Define model length
            len = numel(model.w) + numel(model.b);
    
            % 2e7 = 2GB
            % 5e6 = 500 MB
            QP_SIZE = 2e7; 
            nmax  = floor(QP_SIZE/len);
            obj.nmax = nmax;
            obj.x  = zeros(len,nmax,'single');
            obj.b  = zeros(nmax,1,'single');
            obj.d  = zeros(nmax,1,'double');
            obj.a  = zeros(nmax,1,'double');
            obj.sv = logical(zeros(1,nmax));  
            % JSS3 2012-5-26, which examples are positive?
            obj.pos= logical(zeros(1,nmax));  
            obj.w  = zeros(len,1);
            obj.n  = 0;
            obj.ub = 0;
            obj.lb = 0;
            obj.l  = 0;
            obj.C  = C;
            obj.svfix = [];
            
            % prevent addition of duplicate features using a map of md5
            % hashes
            obj.containment = containers.Map();
        end
        
        function obj = assert(obj,feat,margin,slack,pos)    
            if isempty(feat)
                return
            end
            
            % Add constraints to QP
            % w*feat(:,i) >= margin(i) - slack(i)
            i    = obj.n+1:obj.n + size(feat,2);
            obj.x(:,i) = feat;
            obj.d(i)   = sum(feat.^2);
            obj.b(i)   = margin;
            obj.sv(i)  = 1;
            obj.pos(i) = pos;
            obj.ub     = obj.ub + obj.C*sum(max(slack,0));
            obj.n      = obj.n  + size(feat,2);      
            assert(obj.n <= obj.nmax);
        end
        
        function obj = opt_one(obj)
            MEX = true;
  
            % Random ordering of support vectors
            I = find(obj.sv);
            I = I(randperm(length(I)));
            assert(~isempty(I));
            
            % Mex file is much faster
            if MEX,
                bSize = size(obj.b);
                
                [loss,obj.a,obj.w,obj.sv,obj.l] = qp_one_c(obj.x,obj.b,obj.d,obj.a,obj.w,obj.sv,obj.l,obj.C,I);
                %keyboard;    
                
                assert(all(bSize == size(obj.b)));
            else
                loss = 0;
                for i = I,
                    % Compute clamped gradient
                    G = obj.w'*obj.x(:,i) - obj.b(i);
                    if (obj.a(i) == 0 && G >= 0) || (obj.a(i) == obj.C && G <= 0),
                        PG = 0;
                    else
                        PG = G;
                    end
                    if (obj.a(i) == 0 && G > 0),
                        obj.sv(i) = 0;
                    end
                    if G < 0,
                        loss = loss - G;
                    end
                    % Update alpha,w, dual objective, support vector
                    if (abs(PG) > 1e-12)
                        a = obj.a(i);
                        obj.a(i) = min(max(obj.a(i) - G/obj.d(i),0),obj.C);
                        obj.w = obj.w + (obj.a(i) - a)*obj.x(:,i);
                        obj.l = obj.l + (obj.a(i) - a)*obj.b(i);
                    end
                end
            end
            
            % Update objective
            obj.sv(obj.svfix) = 1;
            obj.lb_old = obj.lb;
            obj.lb = obj.l - obj.w'*obj.w*.5;
            obj.ub = obj.w'*obj.w*.5 + obj.C*loss;
            assert(all(obj.a(1:obj.n) >= 0 - 1e-5));
            assert(all(obj.a(1:obj.n) <= obj.C + 1e-5));

            %{
            % Sanity check (expensive to commute)
            J = find(mask);
            K = obj.x(:,J)*obj.a(J);
            dual = obj.b(J)'*obj.a(J) - K'*K*.5;
            fprintf('obj=(%.3f,%.3f)',obj.obj,dual);
            assert(abs(obj.obj - dual) < .1);
            %}
        end
        
        function obj = opt(obj,tol,iter)
        % obj_opt(tol,iter)
        % Optimize QP until relative difference between lower and upper bound is below 'tol'
            
            if nargin < 2 || isempty(tol)
                tol = .05;
            end
            
            if nargin < 3 || isempty(iter)
                iter = 1000;
            end
            
            slack = obj.b' - obj.w'*obj.x;
            loss  = sum(max(slack,0));
            ub    = obj.w'*obj.w*.5 + obj.C*loss; 
            lb    = obj.lb;
            %fprintf('\n LB=%.4f,UB=%.4f [',lb,ub);
            %fprintf('[');
            
            % Iteratively apply coordinate descent, pruning active set (support vectors)
            % If we've possible converged over active set
            % 1) Compute true upper bound over full set
            % 2) If we haven't actually converged, 
            %    reinitialize optimization to full set
            obj.sv(1:obj.n) = 1;
            for t = 1:iter,
                obj = qp_one(obj);
                lb     = obj.lb;
                ub_est = min(obj.ub,ub);
                %fprintf('.');
                if lb > 0 && 1 - lb/ub_est < tol,
                    slack = obj.b' - obj.w'*obj.x;
                    loss  = sum(max(slack,0));
                    ub    = min(ub,obj.w'*obj.w*.5 + obj.C*loss);  
                    if 1 - lb/ub < tol,
                        break;
                    end
                    obj.sv(1:obj.n) = 1;
                end
                %fprintf('t=%d: LB=%.4f,UB_true=%.5f,UB_est=%.5f,#SV=%d\n',t,lb,ub,ub_est,sum(obj.sv));
            end
            
            obj.ub = ub;
            %fprintf(']');
            %fprintf('] LB=%.4f,UB=%.4f\n',lb,ub);
            
        end
        
        % Re-indexes qp.x to begin with active consrtaints (eg, the support vectors)
        function [obj,n] = prune(obj)            
        % if cache is full of support vectors, only keep non-zero (and fixed) ones
            if all(obj.sv),
                obj.sv = obj.a > 0;
                obj.sv(obj.svfix) = 1;
            end
            
            I = find(obj.sv > 0);
            n = length(I);
            assert(n > 0);
                        
            % remove the non-support vectors from the 
            NI = find(obj.sv(1:obj.n) <= 0);
            for i = 1:numel(NI)
                feat = obj.x(:,NI(i));    
                hash = hashMat(feat);
                if obj.containment.isKey(hash)
                    remove(obj.containment,hash);
                end
            end
            
            % move svs into the front of the cache
            obj.l = 0;
            obj.w = zeros(size(obj.w));
            for j = 1:n,
                i = I(j);
                obj.x(:,j) = obj.x(:,i);
                obj.b(j)   = obj.b(i);
                obj.d(j)   = obj.d(i);
                obj.a(j)   = obj.a(i);
                obj.sv(j)  = obj.sv(i);
                obj.pos(j) = obj.pos(i);
                obj.l = obj.l +   double(obj.b(j))*obj.a(j);
                obj.w = obj.w + double(obj.x(:,j))*obj.a(j);
            end
            
            % clear the rest of the cache
            obj.sv(1:n)     = 1;
            j = n+1:length(obj.a);
            obj.sv(j)  = 0;
            obj.a(j)   = 0;
            obj.b(j)   = 0;
            obj.pos(j) = 0;
            obj.x(:,j) = 0;
            obj.obj = obj.l - obj.w'*obj.w*.5;
            obj.n   = n;
            %fprintf('\n Pruned to %d/%d with dual=%.4f \n',obj.n,length(obj.a),obj.obj); 
        end
        
        function obj = retract(obj,what,margin,slack)
            if numel(what) == 1
                num = what;
            else
                feat = what;
                num = size(feat,2);
            end
            
            index    = obj.n:-1:(obj.n-num+1);
            obj.x(:,index) = 0;
            obj.d(index)   = 0;
            obj.b(index)   = 0;
            obj.sv(index)  = 0;
            obj.ub     = obj.ub - obj.C*sum(max(slack,0));
            obj.n      = obj.n - num;
            assert(obj.n <= obj.nmax);
        end        
        
        function obj = write(obj,feat,margin,slack,isPos)
        % Compute the (md5) hash code for the feature vector.
        %keyboard;
            hashCode = hashMat(feat);
            
            % make sure we don't overfill the cache...
            assert(size(feat,2) == numel(margin) || numel(margin) == 1);
            if size(feat,2)+obj.n >= obj.nmax
                obj = obj.prune();            
            end
            num_keep = clamp(0,obj.nmax-obj.n,size(feat,2));
            feat = feat(:,1:num_keep);
            if numel(margin) ~= 1
                margin = margin(1:num_keep);
            end
            
            % only add the feature to the cache if it hasn't
            % already been added....
            if ~obj.containment.isKey(hashCode)
                % function obj_write(feat,margin,slack)
                obj = obj.assert(feat,margin,slack,isPos);
                
                obj.containment(hashCode) = 1;
            else
                'would add duplicate key';
            end            
        end        
        
        % JSS3 - 2012.8.15 
        % quick estimate for UB given a w
        function loss = compute_loss(obj,w)
            if nargin < 2
                w = obj.w;
            end
            
            % compute loss
            is = 1:obj.n;
            resp = w' * obj.x(:,is);
            margins = obj.b(is);
            slacks = max(margins' - resp,0);
            %.5*||w||^2 + C*sum_i e_i
            % loss = .5.*w'*w + obj.C .* sum(slacks);            
            loss = obj.C .* sum(slacks);
        end
    end
end
