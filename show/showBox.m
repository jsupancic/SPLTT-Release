% showBox(im,rect)
% Input:
%   im   is a N X M grayscale image
%   rect is a 1 X 4 array of rectangle coordinates
%        ([x1 y1 x2 y2] coordinates assumed)
% Output: None
%   This function shows an image with a rectangle on it
%   Hint: use Matlab's "imshow.m", "hold.m" and "line.m" functions
function showBox(im,rect,clean)
    if nargin < 3
        clean = 0;
    end
    
    if clean
        set(gca,'position',[0 0 1 1]) ;    
        % im and rect must be fixed
        crop_r = rect_scale(rect,2,2);
        rect([1 3]) = rect([1 3]) - crop_r(1);
        rect([2 4]) = rect([2 4]) - crop_r(2);
        im = imcropr(im,crop_r);
    end
    
    % can't show on the cluster worker.
    if ~isempty(getCurrentTask)
        return
    end
    
    showBoxes(im,rect,clean);
end
