% JSS3 2012-04-13
% rect_from_center takes a center and a size and returns a
% Kalal format rectangle.
function k_rect = rect_from_center(cen,sz)
    % find the extreme pts.
    x1 = cen(:,1) - sz(:,1)./2;
    y1 = cen(:,2) - sz(:,2)./2;
    x2 = cen(:,1) + sz(:,1)./2;
    y2 = cen(:,2) + sz(:,2)./2;
    
    % return
    k_rect = [x1 y1 x2 y2];
end
