% JSS3 2012-04-14
% Dynamic Programming Motion Model for HoG-SVM
% based tracker.
% old_boxes : [0 0 0 0 0] if we don't know the position for the
% frame otherwise we put [x y w h r]. 
% track_dp(vidName,model,old_boxes,weights)
function [trajectory,model,f1,backPtrs,track_forward] = track_dp(varargin)
    tracker = DPTracker;
    [trajectory,model,f1,backPtrs,track_forward] = tracker.track_dp(varargin{:});
end
