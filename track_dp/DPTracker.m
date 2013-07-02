% JSS3 - 2012.7.30
% Dynamic Programming Tracker
classdef DPTracker
    properties(SetAccess = private)
        % state
        top_detections;
        scorer;
        k_gts;
        vidName;        
    end
    
    properties
        % configuration
        greedy = 0;
    end
    
    methods
        function [trajectory,model,f1,backPtrs,boxesForward] = ...
                track_dp(obj,vidName,model,old_boxes,weights)
            obj.vidName = vidName;
            matlab_init(obj.vidName);    
            % init paths, prngs, mex etc. etc.
            obj.k_gts = rectBtoK(gt_load(obj.vidName));
            imM = get_frame(obj.vidName,0);
            if nargin < 3 || isempty(model)
                model = genModel(obj.vidName);
            end    
            if nargin < 5 || isempty(weights)
                weights = ones(size(obj.k_gts,1),1);
            end
            
            % configure our prior knowlege about the track. 
            if nargin < 4
                old_boxes = zeros(size(obj.k_gts,1),5);
                old_boxes(1,:) = [obj.k_gts(1,:) 0];
            end
            
            % memoize for performance.
            memo_cache = [cfg('tmp_dir') 'track_dp_' ...
                          obj.vidName model.hash() hashMat(old_boxes) ...
                          '.mat'];
            if exist(memo_cache,'file')
                load(memo_cache,'trajectory','model','f1','backPtrs','boxesForward');
                return;
            end
        
            % run the forward tracker
            'starting forward pass'
            [boxesForward,detections,backPtrs] = ...
                track_dp_forward(obj.vidName,model,obj.k_gts,old_boxes,weights);
            
            % run the backward tracker
            'starting backward pass'    
            %keyboard;
            [boxesBackward] = track_dp_backward(obj.vidName,backPtrs);
            %keyboard;
            
            % how well did we do?
            % forward
            [p,r] = plot_resp(rectKtoB(obj.k_gts),boxesForward,obj.vidName);    
            obj.vidName
            L = track_dp_lcl()
            f1Forward = f1score(p,r)    
            %keyboard;
            
            % backward
            [p,r] = plot_resp(rectKtoB(obj.k_gts),boxesBackward,obj.vidName);    
            obj.vidName
            L = track_dp_lcl()
            f1Backward = f1score(p,r)
            
            % output
            trajectory = boxesBackward;
            f1 = f1Backward;
            save(memo_cache,'trajectory','model','f1','backPtrs','boxesForward');
        end
        
        % old_boxes contains information we assume about the trajectory.
        % If we don't know the location of an object at a point of time,
        % we set that row of old_boxes to [0 0 0 0 0].
        function [boxes,detections,backPtrs] = forward(obj,vidName, ...
                                                       model,k_gts,old_boxes,weights)    
            obj.vidName = vidName;
            obj.k_gts = k_gts;
            % configure our prior knowlege about the track. 
            if nargin < 4 || isempty(old_boxes)
                old_boxes = zeros(size(obj.k_gts,1),5);
                old_boxes(1,:) = [obj.k_gts(1,:) 0];
            end
            if nargin < 5 || isempty(weights)
                weights = ones(size(obj.k_gts,1),1);
            end
            fixed_positions = gt_valid(old_boxes);    
            
            % back ptrs ::= Cell array of matrixes
            %   row for each state of format [x1 y1 x2 y2 resp backPtr]
            %
            % Dynamic Programming requires a data structure to represent
            % the accumulated costs....
            % bbsPrev = matrix of the old bounding boxes
            imM = get_frame(obj.vidName,0);
            
            % init the DP trackers state
            [NDetStates,NStates,detections,boxes,backPtrs] = track_dp_init(obj.k_gts);
            
            % Detect in paralel
            obj.top_detections = model.detect_all(~fixed_positions,obj.vidName,NDetStates);
            obj.scorer = track_scorer();
            
            cluster_ctl('on','small');    
            for frameIter = 1:length(obj.k_gts)-1                
                [obj,detections,backPtrs,imM,boxes] = ...
                    iteration_of_detect_track_update_show(...
                        obj,frameIter,detections,backPtrs,...
                        imM,boxes, fixed_positions,model,...
                        weights,old_boxes,NStates);
            end    
            fprintf('\n\n');
            cluster_ctl('off');
            
            %keyboard;
        end
        
        % one iteration of the loop in DPTracker::Forward
        function [obj,detections,backPtrs,imM,boxes] = ...
                iteration_of_detect_track_update_show(...
                    obj,frameIter,detections,backPtrs,...
                    imM,boxes, fixed_positions,model,...
                    weights,old_boxes,NStates)
            % status
            fprintf('\n Dynamic Program Forward %d of %d',frameIter,size(obj.k_gts,1));
            imN = get_frame(obj.vidName,frameIter);
            
            if fixed_positions(frameIter + 1) 
                % we know the position for this frame. 
                new_detections = repmat([old_boxes(frameIter+1,1:4) 0 1 1], ...
                                        NStates,1);
                
                % meaningless work, but avoids duplicate code. 
                [detections,backPtrs] = ...
                    track_dp_forward_one(detections,new_detections,imM,imN,NStates,backPtrs);            
            else            
                % get the new detections
                new_detections = ...
                    obj.dets_for_frame(model,detections,frameIter);
                new_detections(:,5) = weights(frameIter+1).*new_detections(:,5);
                
                % DP Forward step
                [detections,backPtrs] = ...
                    track_dp_forward_one(detections,new_detections,imM, ...
                                         imN,nan,backPtrs);
                %assert(~any(isnan(detections(:,5))));
                detections
            end
            
            % yield
            best_det = detections(1,:);
            boxes(end+1,:) = best_det(:,1:size(boxes,2));
            obj.scorer = obj.scorer.put(obj.k_gts(frameIter+1,:),best_det);
            % plot
            obj.forward_show(frameIter,imN,detections,backPtrs,boxes);
            
            % if we are in greedy mode, remove all non-optimal states
            if obj.greedy
                det_ct = size(detections,1);
                detections(2:end,:) = repmat(detections(1,:),[det_ct-1,1]);
            end
            
            % maintain invarients
            imM = imN;
            
            %keyboard;
        end
        
        function forward_show(obj,frameIter,imN,detections,backPtrs,k_track_forwards)
            %mode = 'NONE';
            %mode = 'GHOST';
            mode = 'NORMAL';
            
            if strcmp(mode,'NORMAL')
                sfigure(1);        
                showBoxes(imN,detections);
                f1 = obj.scorer.score();
                xlabel(['f1 = ' num2str(f1)]);
                drawnow;            
            elseif strcmp(mode,'GHOST')
                % setup the problem
                sfigure(1);
                k_rect = detections(1,:);
                showBoxes(imN,k_rect,1);
                ttailLen = 25;
                tailLen = min(ttailLen,size(k_track_forwards,1));
                
                % show the off-line tail of k_rect
                k_track_backwards = track_dp_backward(obj.vidName,backPtrs,0);
                k_track_backwards = k_track_backwards(end-tailLen+1:end,:);
                showGhostBoxes(k_track_backwards,'g',linWidth(tailLen));
                
                % show the on-line tail of k_rect
                k_track_forwards = k_track_forwards(end-tailLen+1:end,:);
                showGhostBoxes(k_track_forwards,'y',linWidth(tailLen));
                
                % inspect things...
                %keyboard;
                
                % show the score
                f1 = obj.scorer.score();
                xlabel(['f1 = ' num2str(f1)]);
                drawnow expose update;
                
                % detect jumps.
                k_bw = k_track_backwards(end-1,:);
                k_fw = k_track_forwards(end-1,:);
                k_gt = obj.k_gts(frameIter+1,:);                
                if rect_overlap(k_bw,k_fw) < .99 && ...
                        rect_overlap(k_rect,k_gt) > cfg('correct_overlap')
                    %keyboard;
                end
            end
        end        
        
        function new_detections = dets_for_frame(obj,model,detections,frameIter)
        % get the new detections for this frame...
            new_detections = obj.top_detections{frameIter+1};
            
            % generate the extra states (LK and OCC)
            new_detections = track_dp_forward_augment_states(model, ...
                                                             new_detections,detections,obj.vidName,frameIter);
        end        

        %% Run dynamic programming backwards to compute the
        %% backwards marginal.
        function back_boxes = min_marginals_backwards(obj,model,k_track,backPtrs)
            back_boxes = {};
            
            % first iteration is special.
            imN = get_frame(obj.vidName,vidLen(obj.vidName)-1);
            states = backPtrs{end}.boxes;
            states(:,5) = model.score_box(imN,states);
            states(:,5) = -states(:,5);
            back_boxes{vidLen(obj.vidName)} = states;
            
            cluster_ctl('on','small');
            for frameIter = vidLen(obj.vidName)-2:-1:0
                fprintf('min_marginals2: %d\n',frameIter);
                % rest of iterations
                imM = imN;
                imN = get_frame(obj.vidName,frameIter);
                lcl_states = backPtrs{frameIter+1}.boxes;
                lcl_states(:,5) = model.score_box(imN,lcl_states);
                
                % dynprog to get the current states <-
                [~,~,states] = track_dp_forward_one(states, lcl_states, ...
                                                    imM, imN);
                
                % store them
                back_boxes{frameIter+1} = states;
                %keyboard;
            end
            cluster_ctl('off');
        end
        
        % marginals = cell array of matrixes of the form NDets X 5
        function marginals = min_marginals(obj,vidName,model)
            obj.vidName = vidName;
            %% memoize
            memo = [cfg('tmp_dir') 'min_marginals_' ...
                    obj.vidName model.hash() '.mat'];
            if exist(memo,'file')
                load(memo);
                return;
            end                                
            
            %% Step 0, wrap model in a DeltaSVM model to change
            %% response function
            %model = ModelDeltaSVM(model);
            
            %% Step 1: DP Forwards
            % compute the forward marginals                              
            [k_track,~,~,backPtrs] = track_dp(obj.vidName,model);
            
            %% Step 2: DP Backwards
            % now for the tricky part, compute backwards marginals
            back_boxes = obj.min_marginals_backwards(model,k_track,backPtrs);
            
            %% Step 3: Combine
            marginals = {};
            for frameIter = 0:vidLen(obj.vidName)-1
                fprintf('min_marginals3: %d\n',frameIter);
                imN = get_frame(obj.vidName,frameIter);
                
                boxes_forwards = backPtrs{frameIter+1}.boxes;
                boxes_backwards = back_boxes{frameIter+1};
                eqOrNan = boxes_forwards(:,1:4) == boxes_backwards(:,1:4) ...
                          | isnan(boxes_forwards(:,1:4));
                assert(all(all(eqOrNan)));

                marginal = boxes_forwards;
                % cost + cost + (-cost||+resp)
                marginal(:,5) = ...
                    marginal(:,5) + boxes_backwards(:,5) + model.score_box(imN,marginal);
                marginals{frameIter+1} = marginal;
            end
            
            % save 
            save(memo,'marginals','backPtrs','back_boxes');
        end
    end    
end
