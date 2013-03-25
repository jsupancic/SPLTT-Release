% JSS3 - 2012.5.14
% Setup the data structures for a dynamic program tracker
function [NDetStates,NStates,detections,boxes,backPtrs] = ...
        track_dp_init(k_gts,extraStates)
    if nargin < 2
        extraStates = 2;
    end
    
    NDetStates = 25;
    NStates = NDetStates + extraStates; % Occluded State and LK Projected State
    detections = repmat([k_gts(1,:) 0 0 0],NStates,1);

    boxes = [k_gts(1,1:4), inf];
    backPtrs = {struct('boxes',detections,'bPtr',nan)};
    %backPtrs = {struct('boxes',detections,'bPtr',NaN(NStates,1))};
end
