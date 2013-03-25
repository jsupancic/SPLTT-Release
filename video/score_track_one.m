% JSS3 2012-04-06
% update the counts for the p/r calcuation
function [l, c, g, n] = score_track_one(b_gt,k_box,thresh)
    if nargin < 3
        thresh = cfg('correct_overlap');
    end
    
    % correctly accepted
    c = zeros(size(k_box,1),1);
    % ground truth accepted
    g = 0;
    % accepted by tracker
    n = zeros(size(k_box,1),1);
    % is the frame labeled?
    l = 0;
    
    % ignore frames without a ground truth
    if ~gt_valid(b_gt)
        return;
    end
    l = 1;
    
    % did the b_gt accept the frame?
    if(~gt_occluded(b_gt))
        g = 1;
    end
    
    % did the tracker accept the frame?
    n = ~gt_occluded(k_box);
    
    % was the acceptence correct?
    overlaps = rect_overlap(k_box,rectBtoK(b_gt));
    c = ~gt_occluded(b_gt) & ~gt_occluded(k_box) & overlaps > thresh;
end
