% JSS3 - 2012.7.31
% Computes the true TSVM delta for a set of lambda.
function scores = learn_tsvm_score(lambda,NStates,top_detections,...
                                   vidName,model)
    % try to find the result in our cache
    wHash = hashMat(model.w);
    lHash = hashMat(lambda);
    vidName;
    filename = [cfg('tmp_dir') 'learn_tsvm_score' ...
                vidName wHash lHash '.mat'];
    if exist(filename,'file')
        load(filename,'scores');
        return;
    end
    
    % what is the original score?
    ub0 = model.qp.ub;
    lb0 = model.qp.lb;
    
    % score matrix Frames by Detections
    scoresComp = inf(numel(lambda),NStates);
    
    % use the SVM objective function to, in parallel, fill the
    % matrix.
    cluster_ctl('on');
    spmd
    setpath();
    progFrames = labindex:numlabs:(numel(top_detections));
    for frameIter = progFrames
        fprintf('learn_tsvm: computing scores for frame %d of %d\n',frameIter,numel(top_detections));
        for detectionIdx = 1:NStates
            cur_det = ...
                top_detections{frameIter}...
                (detectionIdx,:);

            if lambda(frameIter)
                continue;
            end
            
            scoresComp(frameIter,detectionIdx) = ...
                cost_lcl_tsvm(model,vidName,frameIter-1,cur_det); 
        end
    end
    end
    fprintf('learn_tsvm_score.m: DONE\n');
    
    % collect the scores composite into a scores matrix...
    scores = inf(numel(lambda),NStates);    
    for iter = 1:numel(scoresComp)
        subScores = scoresComp{iter};
        scores(subScores ~= inf) = subScores(subScores ~= inf);
    end
    cluster_ctl('off');
    
    % save to the cache
    save(filename,'scores');
end
