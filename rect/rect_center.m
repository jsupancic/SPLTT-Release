% JSS3 2012-04-14
% return the center of a Kalal format rectangle...
function center = rect_center(k_rect)
    x = (k_rect(:,1)+k_rect(:,3))./2;
    y = (k_rect(:,2)+k_rect(:,4))./2;
    
    center = [x y];
end
