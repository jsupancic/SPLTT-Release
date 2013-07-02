% JSS3 - 2012.7.30
% Object Oriented Linear HOG Detector
classdef Detector
    properties(SetAccess = private)
        w;
        thresh;
        nms_overlap = .75;
        sbin;
        interval;
        b;
        sb;
        scalex;
        scaley;
        Jpos;
        nx;
        ny;
    end
    
    methods
        % CTOR
        function obj = Detector(w,thresh,sbin,interval,b,sb,scalex,scaley,Jpos,nx,ny)
            obj.w = w;
            obj.thresh = thresh;
            obj.sbin = sbin;
            obj.interval = interval;
            obj.b = b;
            obj.sb = sb;
            obj.scalex = scalex;
            obj.scaley = scaley;
            obj.Jpos = Jpos;
            obj.nx = nx;
            obj.ny = ny;
        end
        
        function w = getW(obj)
            w = obj.w;
        end
        
        function Jpos = getJpos(obj)
            Jpos = obj.Jpos;
        end
        
        function [box,feat] = detect(obj,im,maxdet)    
            % [box,feat] = detect(im,model,maxnum)        
            % compute the response for each position
            [respPyr,scales,featImPyr] = obj.resppyr(im);
            assert(size(featImPyr{1},3) == size(obj.w,3));
            
            % optimization... for speed.
            if nargout > 1
                [box,feat] = obj.detect_with_resps(im,nan,...
                                                   respPyr,scales, ...
                                                   featImPyr);
            else
                box = obj.detect_with_resps(im,nan,...
                                            respPyr,scales, ...
                                            featImPyr);
            end
        end
        
        function [box,feat] = detect_with_resps...
                (obj,im,maxdet,respPyr,scales, ...
                 featImPyr)   
            [h,w,nf] = size(obj.w);
            
            maxnum = 0;
            for s = 1:length(respPyr)
                maxnum = maxnum + size(respPyr{s},1) * size(respPyr{s},2);
            end
            if ~isnan(maxdet)
                maxnum = min(maxnum,maxdet);
            end 
            
            % Pre-allocate space
            if nargout > 1,
                len  = numel(obj.w) + numel(obj.b);
                feat = uninit(len,maxnum,'single');
            end
            box = zeros(maxnum,5);
            cnt = 0;
            
            for s = 1:numel(respPyr),     
                % extract features and responses for this pyr level
                resp = respPyr{s};
                featIm = featImPyr{s};
                scale  = obj.sbin*scales(s);
                padx = w-1;
                pady = h-1;
                
                [y,x] = find(resp >= obj.thresh);
                %keyboard;
                I  = (x-1)*size(resp,1)+y;
                x1 = (x-1-padx)*scale+1;
                y1 = (y-1-pady)*scale+1;
                x2 = x1 + w*scale - 1;
                y2 = y1 + h*scale - 1;
                J  = cnt+1:cnt+length(I);
                box(J,:) = [x1 y1 x2 y2 resp(I)];
                cnt = cnt+length(I);
                
                %Write out features if necessary
                if nargout > 1,
                    for i = 1:length(I),
                        dat = featIm(y(i):y(i)+h-1,x(i):x(i)+w-1,:);
                        feat(:,J(i)) = [dat(:); obj.sb];
                    end
                end
            end
                        
            rand_idxs = randperm(cnt);
            cnt = min(cnt,maxnum);
            box = box(rand_idxs,:);
            if nargout > 1,
                feat = feat(:,rand_idxs);
            end    
        end
        
        function [respPyr,scales,featImPyr] = resppyr(obj,im)            
            % Compute feature pyramid
            [featpyr,scales] = featpyramid(im,obj.sbin,obj.interval,'hog');
            
            % finish up the computation.
            [respPyr,scales,featImPyr] = obj.resppyr_with_feats(im,featpyr,scales);
        end

        % compute the responce pyrmid for given features
        function [respPyr,scales,featImPyr] = resppyr_with_feats(obj,im,featpyr,scales)
            [h,w,nf] = size(obj.w);
            
            %Pre-rotate so that a convolution is handled accordingly
            ww = obj.w;
            for i = 1:nf,
                ww(:,:,i) = rot90(ww(:,:,i),2);
            end
            beta = obj.b * obj.sb;
    
            % Compute the responce for each scale.
            respPyr = {};
            featImPyr = {};
            for s = 1:length(scales),
                featIm = featpyr{s};
                scale  = obj.sbin*scales(s);
                
                % Pad feature map, using an extra cell to handle loss of cell border
                % from feature construction
                padx = w-1;
                pady = h-1;
                % massive padding so we can detect objects which aren't 
                % fully in frame.
                featIm  = padarray(featIm,[pady+1 padx+1 0],0);
                
                % Score each location
                fsiz = size(featIm(:,:,1));
                resp = zeros(fsiz - [h w] + 1);
                
                resp = obj.respyr_gather_features(nf, resp, featIm, ww, beta);
                
                % size(resp) @= size(vars)./sbins
                % size(ww) @= size(varones)./sbins
                sz = round(scale.*[h.*obj.scaley w.*obj.scalex]);
                % look at the ratio between the area of the hog template
                % and the hog feature image and the pixel template and the 
                % raw image.
                % wArea/featImArea = varArea/imArea
                % varArea = imArea * wArea/featImArea
                %[imh,imw] = size(im);
                %sz = (imh*imw) * (h*w) / (fsiz(1) * fsiz(2));
                
                % store the output
                respPyr{end+1} = resp;
                featImPyr{end+1} = featIm;
            end
        end
        
        function resp = respyr_gather_features(obj, nf, resp, featIm, ww, beta)
            % send to GPU
            %gpu_featIm = gpuArray(featIm);
            %gpu_ww = gpuArray(ww);
            %gpu_resp = gpuArray(resp);        
            %[respR,respC] = size(resp);
            %respR * respC        
    
            % Loop over the features
            for i = 1:nf,            
                resp = resp + conv2(featIm(:,:,i),ww(:,:,i),'valid');
                %gpu_resp = gpu_resp +
                %gather(conv2(gpu_featIm(:,:,i),gpu_ww(:,:,i),'valid'));
                % 200 = .61 sec
                % 500 = .40 sec
                % 1000 = .33 sec
                % 1500 = .27 sec
                % 2000 = .26 sec
                %if respR*respC > 2000
                %    gpuFeat = gpuArray(featIm(:,:,i));
                %    gpuWW = gpuArray(ww(:,:,i));
                %    resp = resp + gather(conv2(gpuFeat,gpuWW,'valid'));
                %else
                %    resp = resp + conv2(featIm(:,:,i),ww(:,:,i),'valid');
                %end
                %convRes = fconv(featIm,{ww},1,1);
                %resp = resp + convRes{1};
            end
            resp = resp + beta;                    
            %resp = gather(gpu_resp);
        end
        
        
        % find all detections in a video sequence for a given model and qp.
        % top_detections = {dets1 dets2 ...}
        % dets1 = [x1 y1 x2 y2 resp; x1 y1 x2 y2 resp; x1 y1 x2 y2 resp;
        % ...]
        %
        % top_detections has one cell for each frame in the video
        % frames(frameNum) = 1 if we want to detect or 0 for NULL result. 
        function top_detections = detect_all(obj,frames,vidName,NStates)
            if isscalar(frames)
                frames = ones(frames,1); 
            elseif isempty(frames)
                frames = ones(vidLen(vidName),1);
            end
            % lookup vid length using ground truth
            vlen = vidLen(vidName);
            if numel(frames) ~= vlen
                frameCt = numel(frames)
                vlen
                assert(numel(frames) == vlen);
            end
            
            
            % check cache
            wHash = hashMat(obj.w);
            fHash = hashMat(frames);
            filename = [cfg('tmp_dir') 'detect_all_' ...
                        vidName wHash fHash ...
                        '-n=' num2str(NStates) 'nms=' num2str(obj.nms_overlap) ...
                        '.mat'];
            if exist(filename,'file')
                load(filename,'top_detections');
                %keyboard;
                return
            end
    
            % do the core computation if the cache misses.
            USE_OPENCV = 0;
            if USE_OPENCV
                % use a faster C++ implementation...
            else
                top_detections = obj.do_detect_all(frames,vidName,NStates);
            end
            
            % save the learned detections.
            save(filename,'top_detections');
        end
        
        function top_detections = do_detect_all(obj,frames,vidName,NStates)
            vlen = vidLen(vidName);
            top_detections = repmat({},numel(frames),1);    
            % parfor or for
            frameIdxs = find(frames)-1;
            %frameIdxs
            comp_pf_frames = {};
            comp_pf_results = {};
            cluster_ctl('on');
            % first make sure we have SIFT features for each frame.
            % do this as pre-procesisng to prevent workers from overwriting
            % eachother and opening partially completed caches.
            %parfor frameIter = 0:vlen-2
            %    SIFT_matches(vidName,frameIter);
            %end
            
            % do the detection
            spmd
                progFrames = labindex:numlabs:numel(frameIdxs);
                for iter = progFrames
                    frameIter = frameIdxs(iter);
                    [pf_frame,pf_result] = obj.detect_all_one...
                        (frameIter,vlen,vidName,NStates);
                    comp_pf_frames{end+1} = pf_frame;
                    comp_pf_results{end+1} = pf_result;
                end
            end
            
            % I'm not sure this collect step is more efficent than
            % parfor looping over the entire domain...
            for compIter = 1:numel(comp_pf_frames)
                pf_frames = comp_pf_frames{compIter};
                pf_results= comp_pf_results{compIter};
                for iter = 1:numel(pf_frames)
                    frame = pf_frames{iter};
                    result = pf_results{iter};
                    top_detections{frame} = result;
                end
            end
            cluster_ctl('off');
            
            fprintf('\n\n');
        end

        function [pf_frame,pf_results] = detect_all_one...
                (obj,frameIter,vlen,vidName,NStates)
            % status
            fprintf('\n detecting %d of %d',frameIter,vlen-1);
            % get the frame
            %imM = get_frame(vidName,frameIter-1);
            imN = get_frame(vidName,frameIter);
            
            % detect and apply NMS
            cur_detections = obj.detect_all_one_detect_and_nms(imN,NStates);
                        
            % now, after detection and NMS: Compute occlusion probs.
            cur_detections = [cur_detections ones(size(cur_detections,1),2)];
            for detectionIter = 1:size(cur_detections,1)
                cur_detections(detectionIter,6) = 1;
                cur_detections(detectionIter,7) = 1;
            end
            
            % store
            pf_frame = frameIter+1;
            pf_results = cur_detections;    
        end
        
        function cur_detections = detect_all_one_detect_and_nms(obj,imN,NStates)
            % detect with Prof. Ramanan's NMS
            obj.thresh = -inf;
            cur_detections = obj.detect(imN,inf);
            numDet = size(cur_detections,1);
            if(~(numDet >= NStates))
                fprintf('warning: not enough detections!!!\n');
                fprintf('warning: duplicating some!\n');
                deficit = NStates - numDet;
                cur_detections(end+1:end+deficit,:) = ...
                    repmat([1 1 1 1 -inf],deficit,1);        
                assert(size(cur_detections,1) >= NStates);
            end
            cur_detections = nms(cur_detections,obj.nms_overlap,obj.scalex,obj.scaley);
            numPasSup = size(cur_detections,1);
            if(~(numPasSup >= NStates))
                deficit = NStates - numPasSup;
                fprintf('warning: not enough detections after NMS\n');
                fprintf('warning: numDet = %d, numPassSup = %d\n',numDet,numPasSup);
                cur_detections(end+1:end+deficit,:) = ...
                    repmat(cur_detections(1,:),deficit,1);
                assert(size(cur_detections,1) >= NStates);
            end
            % take the 5 most confident maximal detections.
            cur_detections = cur_detections(1:NStates,:);                        
            
            % detect with my NMS
            %cur_detections = detect_best(imN,model,NStates,.1);                        
        end     
        
        function new_neg = training_neg(obj,B_bb,im,weight,featPyr,scales,maxnum)
            if cfg('sample_negatives')
                new_neg = training_neg_subsample(obj,B_bb,im,weight,featPyr,scales,maxnum);
            else
                new_neg = training_neg_all(obj,B_bb,im,weight,featPyr,scales,maxnum);
            end
        end
            
        function new_neg = training_neg_subsample(obj,B_bb,im,weight,featPyr,scales,maxnum)
            % paramters
            SAMPLE_CT = 65;
            POS_DIST = 25;
            NEG_DIST = 50;
            [H,W,D] = size(im);    
            
            % start with zero features                
            new_neg = zeros([numel(obj.w)+1,SAMPLE_CT]);
            sample_boxes = zeros(SAMPLE_CT,4);
            k_bb = rectBtoK(B_bb);
            bb_center = rect_center(k_bb);
            bb_size = rect_size(k_bb);
            
            % add new random samples            
            for sampleIter = 1:SAMPLE_CT % 65 from MIL CVPR paper.
                % find the center of the sample.
                theta = 360.*rand;
                distance = POS_DIST+(NEG_DIST-POS_DIST).*rand; % taken from MIL
                sample_cen_x = bb_center(1) + distance.*cosd(theta);
                sample_cen_y = bb_center(2) + distance.*sind(theta);                
                % find the size of the sample?
                size_entropy = .5;
                sample_sz = (1 - .5.*size_entropy).*bb_size + size_entropy.*rand.*bb_size;
                % get the sample bb
                k_sample = rect_from_center([sample_cen_x,sample_cen_y],sample_sz);
                % clamp it to a reasonable size
                k_sample(1) = clamp(0,k_sample(1),W);
                k_sample(2) = clamp(0,k_sample(2),H);
                k_sample(3) = clamp(0,k_sample(3),W);
                k_sample(4) = clamp(0,k_sample(4),H);
                
                % get the sample
                sample_neg = feature_get_for_svm(obj,im,rectKtoB(k_sample));
                new_neg(:,sampleIter) = sample_neg;
                sample_boxes(sampleIter,:) = k_sample;
            end
            
            showBoxes(im,[k_bb; sample_boxes]);
            drawnow;
            %keyboard;
        end
            
        function new_neg = training_neg_all(obj,B_bb,im,weight,featPyr,scales,maxnum)
            oldThresh = obj.thresh;
            obj.thresh = -weight;
            
            [respPyr,scales,featImPyr] = ...
                obj.resppyr_with_feats(im,featPyr,scales);
            [box,new_neg] = obj.detect_with_resps...
                (im,maxnum,respPyr,scales, featImPyr);
            % [box,new_neg] = detect(im,model);
            [void,I] = sort(box(:,5),'descend');
            I = I(1:min(maxnum,numel(I)));
            box = box(I,:);
            new_neg = new_neg(:,I);
            if ~gt_occluded(B_bb)
                [box,new_neg] = gt_filter_detections(box,new_neg,B_bb);
            end
            
            obj.thresh = oldThresh;
        end
        
        function new_pos = training_pos(obj,B_bb,im,weight)
            
            if gt_occluded(B_bb)
                new_pos = [];
            else
                assert(~all(B_bb == 0));
                new_pos = feature_get_for_svm(obj,im,B_bb);
            end
        end
    end
end
