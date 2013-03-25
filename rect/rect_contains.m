% JSS3 - 2012.6.19
function c = rect_contains(k_rect,k_pts)
    c = k_pts(:,1) >= k_rect(:,1) & k_pts(:,1) <= k_rect(:,3) & ...
        k_pts(:,2) >= k_rect(:,2) & k_pts(:,2) <= k_rect(:,4);
end
