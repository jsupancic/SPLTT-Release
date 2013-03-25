% JSS3 2012-5-10
% one forward step of the dynamic program for tracking.
% one iteration of the dynamic program forward pass
% states = states from the previous frame
%              (:,5) = responce = -cost
% new_detections = detections in the current frame
%              (:,5) = cost = -response
% imM, imN = the previous and current frames, respectively.
% NStates = the number of states 
%           (Number of Detections + Occluded + LK State)
function [states,backPtrs,states_unsorted] = track_dp_forward_one...
        (states, new_detections,imM,imN,~,backPtrs)
    %fprintf('+track_dp_forward_one\n');    
    % predict bbs
    oldRects = track_dp_forward_one_predict_rects(states,imM,imN);

    % if all equal inf, all are equally likely.
    if all(states(:,5) == inf) 
        states(:,5) = 0;
    end
    
    % disable occ/emrg constraints
    % new_detections(:,6:7) = 1;
    
    oldRects = cell2mat(oldRects');
    oldRects = oldRects(:,1:4);
    %keyboard;
    assert(size(new_detections,2) >= 7);
    assert(size(states,2) >= 7);
    [states,bp] = dynprog_chain(states,oldRects,new_detections);
    states = [states(:,1:5) new_detections(:,6:end)];
    %keyboard;
        
    % update the backptrs for a backwards pass if required. 
    states_unsorted = states;
    [states,dIdx] = sortrows(states,5);
    if nargin >= 6
        backPtrs{end+1} = ...
            struct('boxes',states,'bPtr',bp(dIdx));             
    else
        backPtrs = [];
    end
    
    %fprintf('-track_dp_forward_one\n');
end

function oldRects = track_dp_forward_one_predict_rects(states,imM,imN)
    %fprintf('+track_dp_forward_one_predict_rects\n');
    % compute the flows for each old rect
    oldRects = {};
    parfor oldIter = 1:size(states,1)
        oldRect = states(oldIter,1:4);            
        
        if ~gt_occluded(oldRect)
            if cfg('use_lk')
                %Use LK CRF 
                projection = tldTracking(oldRect',imM,imN)';
                if gt_occluded(projection)
                    % LK failed
                    projection = oldRect;
                end
            else
                % use use MRF.
                projection = oldRect;
            end
            
            % only use LK if it doens't fail.
            if ~gt_occluded(projection)
                oldRect = projection;
            end
        end
        oldRects{oldIter} = oldRect;
    end
    %fprintf('-track_dp_forward_one_predict_rects\n');
end

