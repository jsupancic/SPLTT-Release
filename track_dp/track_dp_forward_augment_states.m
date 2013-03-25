% JSS3 2012.5.10
% new_detections : the states detected in the current frame
% detections : the states in the previous frame. 
function new_detections = track_dp_forward_augment_states(model, ...
                                                      new_detections,detections,vidName,frameIter)
    %fprintf('+track_dp_forward_augment_states\n');
    assert(isscalar(frameIter));
    imM = get_frame(vidName,frameIter-1);
    imN = get_frame(vidName,frameIter);
    
    % HERE BE DRAGONS (PARAMS)
    % add the occluded state
    % OCC_COST = cfg('hog_svm/occlusion_cost');
    OCC_COST = model.occ_thresh();
    % generate occlusion states
    new_detections = track_dp_gen_occlusions...
        (detections,new_detections,cfg('dp_min_time_occluded'),OCC_COST);
    
    % generate the LK tracked state...
    visibleDetections = ...
        detections(find(~gt_occluded(detections)),:);
    % shrink scales are only required for detections.
    visibleDetections = flipdim(nms(visibleDetections,.75,model.getScaleX(),model.getScaleY()),1);
    lkImax = min(5,size(visibleDetections,1));
    for lkI = 1:lkImax
        %fprintf('track_dp_forward_augment_states: LK State %d\n',...
        %        lkI);
        if lkI > size(visibleDetections,1)
            break;
        end
        best_det = visibleDetections(lkI,:);
        if cfg('use_lk')
            % it seems my implementation is quite slow...
            %[lk_rect,failed]  = LucasKanade(best_det(1:4),imM,imN,0,0); % Use *my* implementation
            lk_rect = tldTracking(best_det',imM,imN)';
            lk_rect = rect_correct_aspect(lk_rect,model.getAspect());
        else
            lk_rect = best_det(:,1:4);
        end
        %fprintf('track_dp_forward_augment_states: LK Projection Complete\n');
        
        % add LK state with score and occ prob.
        lk_out_of_frame = rect_overlap(lk_rect,[0 0 size(imM,2) size(imN,1)]) <= 0;
        imsz = rect_size(rect_image(imN));
        dtsz = rect_size(lk_rect);
        lk_too_large = any(dtsz >= imsz);
        if lk_out_of_frame || lk_too_large
            %new_detections = [new_detections; NaN NaN NaN NaN -OCC_COST];
        else
            %fprintf('track_dp_forward_augment_states: computing poc\n');
            poc = 1;
            %fprintf('track_dp_forward_augment_states: computing poe\n');
            poe = 1;
            %fprintf('track_dp_forward_augment_states: lk score computing\n');
            lk_score = model.score_box(imN,lk_rect);
            %fprintf('track_dp_forward_augment_states: appending result\n');
            new_detections = [new_detections; ...
                              lk_rect  lk_score ...
                              poc poe];
            %fprintf('track_dp_forward_augment_states: iteration complete\n');
        end    
    end
    %fprintf('-track_dp_forward_augment_states\n');
end
