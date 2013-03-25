% JSS3 - 2012-03-18
% convert rectnalge from [x1 y1 w h] format
% to [x1 y1 x2 y2]
function K = rectKtoB(B)
    K = [B(:,1) B(:,2) (B(:,1)+B(:,3)) (B(:,2)+B(:,4))];
end
