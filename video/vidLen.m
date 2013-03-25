% JSS3 2012-5-18
% Return the length of the named video
function len = vidLen(vidName)
    gt = gt_load(vidName);
    len = size(gt,1);
end
