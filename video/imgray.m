% JSS3 2012-04-11
% color to grayscale.
function im2 = imgray(im)
    [H,W,D] = size(im);
    if D == 3
        im2 = mean(im,3);
    end    
end
