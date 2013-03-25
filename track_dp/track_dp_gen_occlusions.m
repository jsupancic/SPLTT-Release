% JSS3 2012-6-5 Genreate occluded states for a DP tracker
% stash the time occluded in the 4th element.
function [boxes] = track_dp_gen_occlusions(states,boxes,max_occlusions,occ_cost)
    numStates = size(states,1);
    for stateIter = 1:numStates
        curState = states(stateIter,:);
        if gt_occluded(curState) 
            occlusionTime = curState(:,4);
            curState(:,4) = occlusionTime + 1;
            curState(:,5) = occ_cost;
            if occlusionTime <= max_occlusions
               boxes(end+1,:) = nan(size(boxes(end,:)));
               boxes(end,1:size(curState,2)) = curState;
            end
        end
    end
    boxExtraData = size(boxes,2) - 5;
    boxes = [boxes; nan(1,3) 0 occ_cost nan(1,boxExtraData)];
    %keyboard;
end
