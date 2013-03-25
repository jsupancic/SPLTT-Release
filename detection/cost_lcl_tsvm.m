% JSS3 - 2012-5-30
% the transductive local cost computation
function ei = cost_lcl_tsvm(model,vidName,frameIter,k_det,pos,neg)
    % dissallow training rectangles larger than the image.
    imsz = rect_size(rect_image(get_frame(vidName,frameIter)));
    dtsz = rect_size(k_det);
    if any(dtsz >= imsz)
        ei = inf;
        return;
    end
    
    if nargin < 5
        pos = 1;
    end
    if nargin < 6
        neg = 1;
    end
    
    ub0 = model.qp.ub;
    lb0 = model.qp.lb;
    modelPrime = updateModel(model,model.Jpos);
    modelPrime = modelPrime.train_one(vidName,get_frame(vidName,frameIter),...
                                      rectKtoB(k_det),pos,neg);
    %keyboard;
    %[modelPrime.ub, ub0, modelPrime.lb, lb0]
    % UB is an estimate, LB is correct
    ei = max(modelPrime.qp.lb-lb0,0);
    if gt_occluded(k_det)
        % add a 'fake' occluded example.
        ei = ei + model.qp.C*2; % 2 = worst case, 1 =
                                % average case, 0 = best case.
    end
    assert(~isnan(ei));
end
