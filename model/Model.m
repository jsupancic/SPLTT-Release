% JSS3 - 2012.7.30
% I'm finally making the big change; converting the model to a
% class.
classdef Model
    properties(SetAccess = private)
        gt_width;
        gt_height;
        aspect;
        Jpos;
        nx;
        ny;
        nf;
        featType;
        w;
        b;
        sb;
        scalex;
        scaley;
        interval;
        sbin;
        sym;
        thresh;
        qp;
    end
    
    methods
        % use of this method is strongly discouraged
        % as it breaks encapsulation.
        function qp = qp_get(obj)
            qp = obj.qp;
        end
        
        % use of this method is strongly discouraged
        % as it breaks encapsulation.
        function obj = qp_set(obj,qp)
            obj.qp = qp;
            obj = updateModel(obj,obj.Jpos);
        end
        
        function aspect = getAspect(obj)
            aspect = obj.aspect;
        end
        
        function scalex = getScaleX(obj)
            scalex = obj.scalex;
        end
        
        function scaley = getScaleY(obj)
            scaley = obj.scaley;
        end
        
        function Jpos = getJpos(obj)
            Jpos = obj.Jpos;
        end
        
        function C = getC(obj)
            C = obj.qp.getC();
        end
        
        function qp = getQP(obj)
            qp = obj.qp;
        end
                
        function model = setThresh(model,thresh)
            model.thresh = thresh;
        end

        function d = detector(obj)
            d = Detector(obj.w,obj.thresh,obj.sbin,obj.interval,...
                         obj.b,obj.sb,obj.scalex,obj.scaley,obj.Jpos,...
                         obj.nx,obj.ny);
        end
        
        function top_detections = detect_all(obj,frames,vidName, ...
                                             NDetStates)
            d = obj.detector();
            top_detections = d.detect_all(frames,vidName,NDetStates);
        end
        
        function [box,feat] = detect(obj,im,model,maxdet)
            [box,feat] = detect(im,model,maxdet);
        end

        function h = hash(obj)
            h = hashMat(obj.w);
        end
        
        % score some boxes! Oh Yea!
        function score = score_box(obj,im,k_rect)
            boxCt = size(k_rect,1);
            score = zeros(boxCt,1);
            for iter = 1:boxCt
                score(iter,1) = scoreBox(obj,im,k_rect(iter,:));    
            end
        end        
        
        % support two different construtction methods.
        function obj = Model(ctor,varargin)
            if strcmp(ctor,'init')
                obj = obj.init(varargin{:});
            elseif strcmp(ctor,'gen')
                obj = obj.generate(varargin{:});
            elseif strcmp(ctor,'copy')
                obj = obj.copy(varargin{:});
            else
                error('Model::Model invalid constructor');
            end
        end
        
        function obj = copy(obj,other)
            props = properties(other);
            for iter = 1:length(props)
                obj.(props{iter}) = other.(props{iter});
            end
        end
        
        function model = init(model,sbins,nx,ny,Jpos,~,gt_width,gt_height)
            featType = 'hog';
            
            % model = initmodel(bigbox,smallbox,sbin)
            % Initialize model given size of bounding boxes in positive images
            model.gt_width = gt_width;
            model.gt_height = gt_height;
            model.aspect = gt_width/gt_height;
            
            model.Jpos = Jpos;
            
            model.nx = nx;
            model.ny = ny;
            model.nf = length(features(zeros([3 3 3]),1,feat_code(featType)));
            model.featType = featType;
            
            % Main parameters; linearly-scored template and bias
            model.w = zeros([model.ny model.nx model.nf])
            model.b = 0;
            
            % Encode scale factor for bias, width and height
            model.sb = 10;
            model.scalex = gt_width/(nx*sbins); % needed because hog templates cannot exactly 
            model.scaley = gt_height/(ny*sbins); % have same aspect ratio as image templates.
            
            % Default number of scales in a 2X octave for image pyramid
            model.interval = 4; 
            
            % Size of spatial bin
            model.sbin = sbins;

            % Enforce symmetry
            model.sym = true;
            
            % default threshold...
            model.thresh = -1;
        end
        
        function model = generate(model,vidName,~,AREA, trainOn)
            if nargin < 4 || isempty(AREA)
                AREA = 36;
            end
            featType = 'hog';
            if nargin < 5
                trainOn = [0];
            end
            
            C = cfg('C');
            Jpos = 1;
            b_gts = gt_load(vidName);
            b_gt1 = b_gts(1,:);
            gt_width = b_gt1(3)
            gt_height = b_gt1(4)
            gt_area = gt_width*gt_height;
            % compute
            nx = round(sqrt(AREA)*sqrt(gt_width)/sqrt(gt_height))
            ny = round(sqrt(AREA)*sqrt(gt_height)/sqrt(gt_width))
            na = nx*ny;
            sbins = round(sqrt(gt_area/na));
            
            model = model.init(sbins,nx,ny,Jpos,featType,gt_width,gt_height);
            model.qp = qp_init(model,C);   
            
            % set the variance filter
            imM = get_frame(vidName,0);
            T0 = imcropr(imM,rectBtoK(b_gts(1,:)));
            
            model_cache_file = [cfg('tmp_dir') 'model_' ...
                                featType num2str(AREA) hashMat(trainOn) ...
                                vidName '.mat'];
            if exist(model_cache_file,'file')
                load(model_cache_file,'model');
            else
                for trainIter = 1:numel(trainOn)
                    trainFrame = trainOn(trainIter);
                    imM = get_frame(vidName,trainFrame);            
                    
                    % train on frame
                    for tIter = 1:5
                        fprintf('track_dp: training iteration %d of %d\n',tIter,5);
                        model = model.train_one(vidName,imM,b_gts(trainFrame+1,:));
                        showModel(model.w);
                        drawnow;
                    end
                end
                save(model_cache_file,'model');
            end
        end
        
        % Train the SVM on one frame.
        function [model] = train_one(model,vidName,im,B_bb,p,n)
            % default args
            if nargin < 5
                p = 1; 
            end
            if nargin < 6
                n = 1;
            end
            qp_out = @qp_write;           
            update_model = 1; 
            featSrc = @featpyramid;
            weight = 1;
            maxneg = inf;
            Jpos = model.Jpos;
            
            % dissallow training rectangles larger than the image.
            imsz = rect_size(rect_image(im));
            dtsz = rect_size(rectBtoK(B_bb));
            if any(dtsz > imsz)
                dtsz = dtsz
                assert(~any(dtsz > imsz));
            end
            
            featpyr = [];
            scales = [];
            if n >= 1
                [featpyr,scales] = featSrc(im,model.sbin,model.interval);        
            end
            
            % add the positive examples...
            [model] = train_one_pos(model,B_bb,im,update_model,p,qp_out,weight);
            
            % now add the negative examples...
            model.thresh = -weight;
            %model.minVar = -inf;
            for i = 1:n
                [model] = train_one_neg...
                    (model,im,featpyr,scales,B_bb,qp_out,update_model,weight,maxneg);
            end
            %showModel(model.w,1);
            %keyboard;
        end
        
        function [model] = train_one_neg...
                (model,im,featpyr,scales,B_bb,qp_out,update_model,weight,maxneg)
            model.qp = qp_prune(model.qp); 
            maxnum = model.qp.nmax - model.qp.n;
            detor = model.detector();
            feat = detor.training_neg(B_bb,im,weight,featpyr,scales,min(maxnum,maxneg));
            
            % make sure we don't overfill the cache...
            if size(feat,2)+model.qp.n >= model.qp.nmax
                model.qp = qp_prune(model.qp);            
            end
            assert(size(feat,2)+model.qp.n <= model.qp.nmax);
            
            % model.qp = qp_out(model.qp,-feat,1,1+box(:,end));
            model.qp = qp_out(model.qp,weight.*-feat,weight.*1,1,0);
            model.qp = qp_opt(model.qp);
            if update_model
                model = updateModel(model,model.Jpos);
            end
        end
        
        function [model] = train_one_pos(model,B_bb,im,update_model,p,qp_out,weight)
            Jpos = model.Jpos;
            
            % add the positive examples
            for iter = 1:p        
                % if we don't have enough room for the sample try to prune non-svs
                if model.qp.n + 1 >= model.qp.nmax
                    model.qp = qp_prune(model.qp);
                end
                % if pruning doesn't work, quit.
                if model.qp.n + 1 >= model.qp.nmax
                    break;
                end
                
                feat = model.detector().training_pos(B_bb,im,weight);
                if isempty(feat)
                    continue;
                end
                model.qp = qp_out(model.qp,weight.*Jpos*feat,weight.*Jpos,Jpos,1);
                model.qp = qp_opt(model.qp);
            end
            
            % update model and show template
            if update_model
                model = updateModel(model,Jpos);
            end
        end     

        % Update model with current QP solution
        function model = updateModel(model,Jpos)
            model.w = reshape(model.qp.w(1:end-1),size(model.w));
            model.b = model.qp.w(end); 
            
            model.interval = 14;
        end
        
        function ot = occ_thresh(obj)
            ot = -1;
            return;
            
            posProb = .95;
            
            % Store model threshold that allows us to find 95% of training
            % positives
            qp = obj.qp;
            r = qp.w'*qp.x(:,find(qp.pos));
            r = sort(r);
            idx = round(clamp(1,length(r)*(1-posProb),numel(r)));
            ot = double(r(idx)/obj.Jpos);
        end        
        
        function c = cost(obj)
            c = obj.qp.lb;
        end
        
        function obj = train_all(obj,vidName,k_track,lambda)
            trainer = SVM_trainer;
            obj = trainer.train_all(vidName,k_track,lambda,[],obj);
        end
    end
end
