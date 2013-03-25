% JSS3 - 2012.7.10
% Return the rectnagle bounding an image
function rect = rect_image(im)
    [h,w,d] = size(im);
    rect = [0 0 w h];
end
