% JSS3 - 2012.8.7
% Simplified interface to learn_tsvm_score.
function deltas = compute_tsvm_deltas(vidName,model,k_track)
    evalFrames = zeros(size(k_track(:,1)));
    [top_detections,NStates] = getDetsEst(vidName,model, ...
                                                  k_track);
    deltas = learn_tsvm_score(evalFrames,NStates,top_detections,...
                             vidName,model);
end
