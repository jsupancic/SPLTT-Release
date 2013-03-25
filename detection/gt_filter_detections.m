% JSS3 2012-03-24
% Filter out the detections which overlap the ground
% truth
function [box,feat] = gt_filter_detections(box,feat,gt)
    % filter out the positives if any
    if(~gt_occluded(gt))
        width = gt(3);
        height = gt(4);
        halfThePixels = .5*width*height;
        
        rectB = rectKtoB(box);
        posneg = rectint(rectB,gt) < halfThePixels;
        box = box(posneg,:);
        feat = feat(:,posneg);
    end
end
