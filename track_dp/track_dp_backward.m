% JSS3 2012-04-14
% backwards pass of a dynamic program
function boxes = track_dp_backward(vidName,backPtrs,show)
    if nargin < 3
        show = 1;
    end    
    
    % find the index of the least cost bb
    bbs = backPtrs{numel(backPtrs)}.boxes;  
    ptrs= backPtrs{numel(backPtrs)}.bPtr;
    [void,idx] = min(bbs(:,5));
    assert(idx > 0);
    k_gts = rectBtoK(gt_load(vidName)); % so we can live plot f1 score 
    
    % init the output...
    boxes = zeros(numel(backPtrs),5);
    backBox = backPtrs{numel(backPtrs)}.boxes(idx,:);
    boxes(end,:) = backBox(:,1:size(boxes,2));
    scorer = track_scorer();
    
    % backwards pass
    for frameIter = (numel(backPtrs)-1):-1:0
        %
        fprintf('\n Dynamic Program Backward %d of %d',frameIter,numel(backPtrs));
        
        % current frame info...
        bbs = backPtrs{frameIter+1}.boxes;  
        ptrs= backPtrs{frameIter+1}.bPtr;
        
        % walk back
        bb = bbs(idx,:);
        if numel(ptrs) == 1
            idx = ptrs(1);
        else
            idx = ptrs(idx,:);
        end
        assert(idx > 0 || isnan(idx));
        
        % yield it! 
        boxes(frameIter+1,:) = bb(:,1:size(boxes,2));
        % plot
        scorer = scorer.put(k_gts(frameIter+1,:),bb);        
        if show
            showBox(get_frame(vidName,frameIter),bb);
            f1 = scorer.score();
            xlabel(['f1 = ' num2str(f1)]);
            drawnow;
        end
        
        if isnan(idx)
            break;
        end
    end
    fprintf('\n\n')
end
