% JSS3 2012-04-14
% old_boxes contains information we assume about the trajectory.
% If we don't know the location of an object at a point of time,
% we set that row of old_boxes to [0 0 0 0 0].
function [boxes,detections,backPtrs] = track_dp_forward(vidName, ...
                                                      model,gts, ...
                                                      old_boxes,weights)
    if nargin < 2
        model = Model('gen',vidName,[],[],[0]);
    end
    if nargin < 3
        gts = rectBtoK(gt_load(vidName));
    end
    if nargin < 4
        old_boxes = [];
    end
    if nargin < 5
        weights = [];
    end
    
    tracker = DPTracker;
    [boxes,detections,backPtrs] = tracker.forward(vidName,model,gts,old_boxes,weights);
end
