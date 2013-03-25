% JSS3 2012-5-25
% simple crop with replication to maintain size...
function IC = imcropr(I,k_cr)
    % validate that the input is of resonable size...
    imsz = rect_size(rect_image(I));
    bbsz = rect_size(k_cr);
    if any(bbsz > 2.*imsz)
        warning('failed to crop image due to size error');
        % return an invalid crop for something to massive
        % (trying to compute the massive crop would result in out
        % of memory crashes).
        IC = [];
        return;
    end
    
    % extract stats
    iSize = size(I);
    i_h = iSize(1);
    i_w = iSize(2);

    % find the padding
    pad_t = round(max(0,0-k_cr(2)));
    pad_b = round(max(0,k_cr(4)-i_h));
    pad_l = round(max(0,0-k_cr(1)));
    pad_r = round(max(0,k_cr(2)-i_w));

    % do the crop!
    IC = imcrop(I,rectKtoB(k_cr));
    IC = padarray(IC,[pad_t pad_l],'replicate','pre');
    IC = padarray(IC,[pad_b pad_r],'replicate','post');
end
