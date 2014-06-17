% JSS3 - 2012.8.6
% Track Online
function [k_track,f1s] = track_offline(vidName)            
    % DP Track until we find enough new data to learn, then learn
    % and track.
    model = genModel(vidName);
    [k_track,~,f1s,~,~] = track_dp(vidName,model); % DP-online
    tracks = {k_track};
    lambda = zeros(vidLen(vidName),1);
    lambda(1) = 1;    
    
    % run the offline algorithm
    batch_count = 6;
    for iter = 1:batch_count
        % SELECT:A
        last_lambda = lambda;
        % remove retained *NEW* occlusions.
        if iter > 1
            retained = last_lambda & lambda;                        
            ret_occ = retained & ...
                      gt_occluded(tracks{end}) & ...
                      ~gt_occluded(tracks{end-1});
            fprintf('select purne: removing %d retained occlusions\n',sum(lambda(ret_occ)));
            lambda(ret_occ) = 0;
        end
        % SELECT: B
        % how much should we add?
        total_ct = .5 .* vidLen(vidName);
        b = nthroot(total_ct,batch_count);
        cur_ct = clamp(1,round(b.^iter),total_ct);
        fprintf('will select %d frames\n',cur_ct);
        % add that many
        deltas = compute_tsvm_deltas(vidName,model,k_track);
        [~,addI] = sort(deltas);
        lambda = zeros(vidLen(vidName),1);        
        lambda(1) = 1; % never drop the first frame
        lambda(addI(1:ceil(cur_ct))) = 1; 
        % SELECT: C
        % remove excessive drift
        if iter > 1
            retained = last_lambda;
            for frameIter = (find(retained)-1)'
                k_old = tracks{end-1}(frameIter+1,:);
                k_new = tracks{end}(frameIter+1,:);
                if rect_overlap(k_old,k_new) < .95
                    fprintf('select_prune: to much drift to retain\n');
                    obj.lambda(frameIter+1) = 0;
                end
            end
        end       
        
        % learn
        model = Model('gen',vidName,[],[],[]);
        model = model.train_all(vidName,k_track,lambda);        
        
        % track
        [k_track,~,f1,~] = track_dp(vidName,model); % DP-offline
        tracks{end+1} = k_track;
        f1s = [f1s f1];                        
    end
    
    % show the f1s.
    f1s = f1s
end


