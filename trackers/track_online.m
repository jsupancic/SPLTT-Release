% JSS3 - 2012.8.6
% Track Online
function [k_track,f1s] = track_online(vidName)            
    % DP Track until we find enough new data to learn, then learn
    % and track.
    model = genModel(vidName);
    [~,~,f1s,~,k_track] = track_dp(vidName,model); % DP-online
    k_track2 = k_track;
    
    % wait until we've seen enough to learn...
    for frameIter = 0:size(k_track,1)-1
        fprintf('track_olol %d of %d\n',frameIter,size(k_track,1));
                
        % See if we are ready to update w.
        [f,e] = log2(frameIter);
        powOf2 = f == .5;
        if powOf2 && frameIter >= 4
            % select
            deltas = compute_tsvm_deltas(vidName,model,k_track2(1:frameIter+1,:));
            [~,addI] = sort(deltas);
            lambda = zeros(vidLen(vidName),1);
            lambda(addI(1:ceil(.50.*frameIter))) = 1;
            
            % learn
            fprintf('track_olol: learning\n');
            model = Model('gen',vidName,[],[],[]);
            model = model.train_all(vidName,k_track,lambda);
            
            % track
            [~,~,f1,~,k_track2] = track_dp(vidName,model); % DP-online
            f1s = [f1s f1];                        
            k_track(frameIter+1:end,:) = k_track2(frameIter+1:end,:);                
        end
    end        
    
    % show the f1s.
    f1s = f1s
end

