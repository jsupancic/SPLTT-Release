% JSS3 2012-5-25
% load a track file and return it's f1 score
function [f1,p,r,displacement,OR_OCC,acc] = score_track_file(vidName,trackFile,interpolate_occlusion)
    % default args
    if nargin < 3
        interpolate_occlusion = 0;
    end

    % memoize
    memo = [cfg('tmp_dir') 'score_track_file_' ...
            vidName '-' ...
            hashMat(trackFile) '-' ...
            num2str(interpolate_occlusion) '.mat'];
    if exist(memo,'file')
        load(memo);
        return;
    end

    % get the track data
    if ischar(trackFile)        
        S = load(trackFile);
        if isstruct(S)
            % .mat files load struct
            k_track = S.track;
        else
            % .csv files load a mat
            k_track = S;
        end
    else
        k_track = trackFile;
    end
    % do we need to interpolate occlusions?
    if nargin > 2 && interpolate_occlusion
        fprintf('interpolating occlusion\n');        
        %keyboard;
        k_track = interp_occ(k_track);        
    end
    
    % load the ground truth.
    k_gts = rectBtoK(gt_load(vidName));
    
    % check the sizes
    if(size(k_track,1) ~= size(k_gts,1))
        fprintf('%d ~= %d\n',size(k_track,1),size(k_gts,1));
        warning('score_track_file: length mismatch');        
    end
    
    % score the track
    scorer = track_scorer();    
    to = min(vidLen(vidName)-1,size(k_track,1)-1);
    for frameIter = 0:to
        scorer = scorer.put(k_gts(frameIter+1,:),...
                            k_track(frameIter+1,:));
    end
    [f1,p,r,displacement,OR_OCC,acc] = scorer.score();
    
    % cache the results
    save(memo,'f1','p','r','displacement','OR_OCC','acc');
end
