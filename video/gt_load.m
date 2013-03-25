% JSS3 2012-04-06
% function to load the gt for a video.
% format should be 1 gt per row
% each row should be [x1 y1 w h]
function gts = gt_load(vidName)
    % prep the gt 
    gt_file = [datapath() vidName '/' vidName ...
               '_gt.txt'];
    gts = importdata(gt_file);

    % pad handle short gts.
    [first,last] = get_vid_range(vidName);
    pad = (last - first + 1) - size(gts,1);
    gts = [gts; zeros(pad,size(gts,2))];    
    
    % handle Kalal [x1 y1 x2 y2] format files.
    if exist(['~/workspace/data/' vidName '/kalal'],'file')
        %'kalal format gt'
        gts = rectKtoB(gts);
    end
end
