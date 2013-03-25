% JSS3 2012-5-23
% this is a class to simplify the scoring of tracks in MATLAB
classdef track_scorer
    properties (SetAccess = private)
        % precision = correctly accepted / number accepted    
        % recall = correctly accepted / gt accepted
        cAccept = 0;
        gAccept = 0;
        nAccept = 0;
        % displacement score info.
        agg_displacement = 0;
        N = 0;
        OR_OCC = 0;
        % simple accuracy
        total_counted = 0;
        total_correct = 0;
    end
    
    % ctor
    %function scorer = track_scorer()        
    %end
    methods
        function scorer = put(scorer,k_gt,k_loc)
            if ~gt_valid(k_gt)
                return;                
            end
            
            % update f1
            [l,c,g,n] = score_track_one(rectKtoB(k_gt),k_loc);
            scorer.cAccept = scorer.cAccept + c;
            scorer.gAccept = scorer.gAccept + g;
            scorer.nAccept = scorer.nAccept + n;
            
            % update displacement error (only meaning without occ)
            if ~gt_occluded(k_gt) && ~gt_occluded(k_loc)
                scorer.N = scorer.N + 1;
                cen_gt = rect_center(k_gt);
                cen_lc = rect_center(k_loc);
                newDist = pdist2(cen_gt,cen_lc);
                assert(~isnan(newDist));
                scorer.agg_displacement = scorer.agg_displacement + ...
                    newDist;
            else
                % something signals occlusion.
                scorer.OR_OCC = scorer.OR_OCC + 1;
            end
            
            % update total correct
            scorer.total_counted = scorer.total_counted + 1;
            if gt_occluded(k_gt) && gt_occluded(k_loc)
                scorer.total_correct = scorer.total_correct + 1;
            elseif ~gt_occluded(k_gt) && ~gt_occluded(k_loc) && ...
                    rect_overlap(k_gt,k_loc) > cfg('correct_overlap')
                scorer.total_correct = scorer.total_correct + 1;
            end
        end
        
        function [f1,p,r,displacement,OR_OCC,acc] = score(scorer)
            p = scorer.cAccept/scorer.nAccept;
            r = scorer.cAccept/scorer.gAccept;
            f1 = f1score(p,r);
            displacement = scorer.agg_displacement ./ scorer.N;
            OR_OCC = scorer.OR_OCC;
            acc = scorer.total_correct./scorer.total_counted;
        end
    end
end
