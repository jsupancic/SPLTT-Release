% JSS3 - 2012.8.31
% return 1 if a bb is ok,
% 0 other (maybe it is to large or truncated)
function ok = check_rect_size(k_bb,k_im)
    % size constraints
    n = size(k_bb,1);
    imsz = repmat(rect_size(k_im),[n,1]);
    bbsz = rect_size(k_bb);
    ok = all(bbsz <= 2.*imsz,2);
end
