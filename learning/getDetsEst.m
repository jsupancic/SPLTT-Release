% JSS3 - 2012.7.3
function [top_detections,NStates] = getDetsEst(vidName,model, ...
                                                       k_track)
    NStates = 1;
    num_top_dets = min(vidLen(vidName),size(k_track,1));
    top_detections = cell(num_top_dets,1);
    for detIter = 1:numel(top_detections)
        top_detections{detIter} = k_track(detIter,:);
    end
end
