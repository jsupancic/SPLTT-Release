% JSS3 - 2012.10.9
% advanced box drawing function with support for alpha transparency
function showGhostBoxes(boxes,color,width)
    % compute coordinates
    D = max(.5,width./4);
    x1 = boxes(:,1);
    y1 = boxes(:,2);
    x2 = boxes(:,3);
    y2 = boxes(:,4);
    
    % compute alphas
    N = size(boxes,1);
    %alphas = ((N:-1:1)./N)';
    alphas = ((1:N)./N)';
    
    % draw the top and bottom
    patch([x1-D x2+D x2+D x1-D]',[y1-D y1-D y1+D y1+D]',color,'edgecolor','none',...
          'FaceAlpha','flat','FaceVertexAlphaData',alphas);
    patch([x1-D x2+D x2+D x1-D]',[y2+D y2+D y2-D y2-D]',color,'edgecolor','none',...
          'FaceAlpha','flat','FaceVertexAlphaData',alphas);        
    % draw left and right
    patch([x1-D x1+D x1+D x1-D]',[y1+D y1+D y2-D y2-D]',color,'edgecolor','none',...
          'FaceAlpha','flat','FaceVertexAlphaData',alphas);
    patch([x2-D x2+D x2+D x2-D]',[y1+D y1+D y2-D y2-D]',color,'edgecolor','none',...
          'FaceAlpha','flat','FaceVertexAlphaData',alphas);    
end
