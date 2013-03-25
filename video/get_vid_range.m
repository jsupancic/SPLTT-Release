% JSS3 - 2012.8.27
% return the first and last frame to use for a labeled video.
function [first,last] = get_vid_range(vidName)
    frames_filename = sprintf('%s%s/%s_frames.txt', ...
                              datapath(),vidName,vidName);
    framesData = csvread(frames_filename);
    first = framesData(1);
    last = framesData(2);
end
