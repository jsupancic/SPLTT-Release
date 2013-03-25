function showBoxVia(im,rect,via)
    % extract the params
    x1 = rect(1); y1 = rect(2);
    x2 = rect(3); y2 = rect(4);
    % draw the image
    colormap gray(256);
    via(im);
    hold on;   
    % draw the box.
    line([x1 x2],[y1 y1]) % top
    line([x1 x2],[y2 y2]) % bottom
    line([x1 x1],[y1 y2]) % left
    line([x2 x2],[y1 y2]) % right
    hold off;
    drawnow;
end
