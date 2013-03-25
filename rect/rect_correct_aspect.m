% JSS3 2012-04-13
% rect_correct_aspect changes the aspect ratio of a rectangle to
% the desired aspect ratio without changing its area.
function k_rect2 = rect_correct_aspect(k_rect,newAspectRatio)
    % aspect = width/height
        
    % find the new size
    oldWidth = k_rect(3) - k_rect(1);
    oldHeight = k_rect(4) - k_rect(2);
    oldArea = oldWidth.*oldHeight;
    % newArea = newWidth * newHeight
    % newArea = oldArea
    % newAspectRatio = newWidth/newHeight
    % newWidth = newAspectRatio * newHeight
    % oldArea = newHeight * newAspectRatio * newHeight
    % oldArea = newHeight^2 * newAspectRatio
    % newHeight = sqrt(oldArea/newAspectRatio)
    %newAspectRatio
    newHeight = sqrt(oldArea/newAspectRatio);
    newWidth = newAspectRatio*newHeight;
    
    % find the old center
    oldCenX = (k_rect(1)+k_rect(3))./2;
    oldCenY = (k_rect(2)+k_rect(4))./2;
    
    k_rect2 = rect_from_center([oldCenX,oldCenY],[newWidth,newHeight]);
end
