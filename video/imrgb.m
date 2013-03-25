% JSS3 2012-04-06
% function to make rgb or grayscale image rgb.
function im = imrgb(im)
    [H,W,D] = size(im);
    if D == 1
        % we need to duplicate channels
        im(:,:,2) = im(:,:,1);
        im(:,:,3) = im(:,:,1);
    end
end
