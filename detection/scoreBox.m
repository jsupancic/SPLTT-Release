% JSS3 2012-04-20
% get the response for a given box.
function score = scoreBox(model,im,k_rect)
    %fprintf('+scoreBox\n');
    imsz = rect_size(rect_image(im));
    bbsz = rect_size(k_rect);
    sz = rect_size(k_rect);
    if any(bbsz > 2.*imsz)
        score = -1; % bad bb because it is to large.
    elseif gt_occluded(k_rect) || sz(1) < 2 || sz(2) < 2 ...
            || rect_area(k_rect) > rect_area(rect_image(im))
        score = -1;
    else    
        %fprintf('scoreBox: getting SVM feature\n');
        %keyboard;
        feat = feature_get_for_svm(model,im,rectKtoB(k_rect));
        %fprintf('scoreBox: got SVM feature\n');
        featSz = numel(feat)-1;
        score = feat(1:featSz)'*model.w(1:featSz)' + model.b*model.sb;    
    end
    %fprintf('-scoreBox\n');
end
