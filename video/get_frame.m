% JSS3 2012-04-06
% function to grab a frame from a video
% frame zero is the first frame.
function [im,filename] = get_frame(vidName,frameNum)    
    % get the frames filename
    global G_HOME;
    persistent firstFrame lastFrame lastVidName;
    if isempty(firstFrame) || ~strcmp(vidName,lastVidName)
        [firstFrame,lastFrame] = get_vid_range(vidName);
        lastVidName = vidName;
    end
    frameNum = frameNum + firstFrame;

    % debug 
    assert(frameNum <= lastFrame);
    
    % read the image
    filename = sprintf('%s%s/imgs/img%.5d.png', ...
                       datapath(),vidName,frameNum);
    im = imrgb(imread(filename));
end
