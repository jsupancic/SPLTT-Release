% JSS3 2012-05-04
function sz = rect_size(k_rect)
    sz = zeros(size(k_rect,1),2);
    % width
    sz(:,1) = k_rect(:,3) - k_rect(:,1);
    % height
    sz(:,2) = k_rect(:,4) - k_rect(:,2);
end
