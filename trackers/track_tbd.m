% JSS3 - 2012-6-13
% simple track by detection algorithm.
function [track,model,f1] = track_tbd(vidName,model)         
    matlab_init(vidName);    
    % init paths, prngs, mex etc. etc.
    gts = rectBtoK(gt_load(vidName));
    imM = get_frame(vidName,0);
    if nargin < 2 || isempty(model)
        model = Model('gen',vidName,[],[],[0]);        
    end    
    track = [];
    NDetStates = 5;
    showModel(model.w);
    top_detections = model.detect_all(size(gts,1),vidName,NDetStates);
    
    scorer = track_scorer();
    for frameIter = 0:(size(gts,1)-1)
        imN = get_frame(vidName,frameIter);
        top_dets = [top_detections{frameIter+1}; nan(1,4) -1 1 1];
        %keyboard;
        top_dets = flipdim(sortrows(top_dets,5),1);
        top_det = top_dets(1,:);
        showBoxes(imN,top_detections{frameIter+1});
        track(end+1,:) = top_det;
        
        % show the score
        scorer = scorer.put(gts(frameIter+1,:),top_det);
        f1 = scorer.score();
        xlabel(['f1 = ' num2str(f1)]);
        drawnow;
    end
    
    [p,r] = plot_resp(rectKtoB(gts),track,vidName);    
    f1 = f1score(p,r)
end
