% JSS3 - 2012.8.6
% Track Online
function [k_track,f1s] = track_offline(vidName)            
    % DP Track until we find enough new data to learn, then learn
    % and track.
    model = genModel(vidName);
    [k_track,~,f1s,~,~] = track_dp(vidName,model); % DP-online
        
    % run the offline algorithm
    batch_count = 6;
    for iter = 1:batch_count
        % select
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
        
        % learn
        model = Model('gen',vidName,[],[],[]);
        model = model.train_all(vidName,k_track,lambda);        
        
        % track
        [k_track,~,f1,~] = track_dp(vidName,model); % DP-offline
        f1s = [f1s f1];                        
    end
    
    % show the f1s.
    f1s = f1s
end


