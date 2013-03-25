% JSS3 function to get the HoG feature describing
% a region in the format the SVM requires.
function [feat,featIm] = feature_get_for_svm(model,im,b_bb) 
    if ~check_rect_size(rectBtoK(b_bb),rect_image(im))
        error('logicError','b_bb is to large');
    end
    
    % drop parts of the bounding box multiple of model.sbin?
    %bb_width  = b_bb(3);
%bb_height = b_bb(4);
%    bb_excess_width = mod(bb_width,model.sbin);
%    bb_excess_height = mod(bb_height,model.sbin);
%    b_bb(1) = b_bb(1) - bb_excess_width/2;
%    b_bb(2) = b_bb(2) - bb_excess_height/2;
%    b_bb(3) = b_bb(3) - bb_excess_width;
%    b_bb(4) = b_bb(4) - bb_excess_height;
        
    % get the template...
    k_bb = rectBtoK(b_bb);
    % the next line changes -.6637 to -.8861 when 
    % -.8918 is  the goal. An improvement, a different 
    % resize algorithm may account for the rest...
    dbg_im = im;
    crop_bb = [(k_bb(1)-model.sbin) (k_bb(2)-model.sbin) ...
               (k_bb(3)+model.sbin) (k_bb(4)+model.sbin)];
    im = imcropr(im,crop_bb);
    nx = model.nx;
    ny = model.ny;
    na = model.nx .* model.ny;
    imx = size(im,2);
    imy = size(im,1);
    im_area = imx .* imy;
    sbins = round(sqrt(im_area/na));
    im = imresize(im,[(model.ny+2)*model.sbin,(model.nx+2)*model.sbin]);
    
    % get the feature
    featIm = features(double(im),model.sbin,feat_code('hog'));        
    %keyboard;
    
    zSize = size(model.w,3); % throw out extra components (work
                             % with color or not).
    feat = featIm(:,:,1:zSize);        
    feat = [feat(:); model.sb];

    if isfield(model,'qp')
        assert(~isfield(model.qp,'x') || size(model.qp.x,1) == numel(feat))    
    end
end
