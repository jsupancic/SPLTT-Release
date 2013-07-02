% JSS3 - 2012.7.25 Class to train an SVM and produce a model.
classdef SVM_trainer
    properties(SetAccess = private)
        % configuration (number of positive and negative passes to
        % do with each frame).
        p = 1;
        n = 1;
        
        % State
        passes;
        PASS_CT;
        frameCt;
        weights;
        track;
        vidName;       
        
        % to cumbersome to pass around
        new_poss;
        new_poss_weights;
        new_negs;
        new_negs_weights;
    end
    
    methods
        % How many positive passes to do for each frame?
        function obj = setP(obj,p)
            obj.p = p;
        end
        
        % How many negative passes to do for each frame?
        function obj = setN(obj,n)
            obj.n = n;
        end
        
        % CTOR
        function obj = SVM_trainer()            
        end
        
        function model = train_all(obj,vidName,track,weights,passes,model)
            memo = [cfg('tmp_dir') 'train_all_' ...
                    hashMat(track) ...
                    hashMat(weights) '.mat'];
            if exist(memo,'file')
                load(memo,'model')
                return;
            end          
            
            if nargin < 6 || isempty(model)
                model = Model('gen',vidName,[],[],[]);
            end
            
            if sum(weights > 0) == 1
                % we are only training on a single frame, don't
                % make things to complicated.
                frameIter = find(weights)-1;
                im = get_frame(vidName,frameIter);
                b_bb = rectKtoB(track(frameIter+1,:));
                model = model.train_one(vidName,im,b_bb,5,5);
            else
                % handle default arguments
                if nargin < 5 || isempty(passes)
                    passes = obj.default_passes(track,weights);
                end
                obj.PASS_CT = numel(passes);
                obj.passes = passes;
                
                % assert valid arguments
                assert(~all(weights <= 0));
                
                % store arguments on object
                obj.track = track;
                obj.vidName = vidName;
                obj.weights = weights;
                
                % ensure we don't try to train without any positive SVs.
                if weights(1) > .5
                    model = model.train_one(vidName,...
                                            get_frame(vidName,0),...
                                            rectKtoB(track(1,:)),...
                                            1,1);
                end
                
                % update for frame 2 to N (transduce)
                obj.frameCt = size(track,1);
                % start with an empty model...
                for pass = 1:obj.PASS_CT
                    model = obj.one_training_pass(pass,model);
                end
            end
            
            save(memo,'model');
        end        
        
        % if the user doesn't tell us how our pass structure
        % should be, then generate a sensible default.
        function passes = default_passes(obj,k_track,weights)
            trainingSetSize = sum(weights > 0);
            base = 2;
            iter = 1;
            
            passes = {};
            while 2.^iter < trainingSetSize
                passes{end+1} = 2.^iter;
                iter = iter+1;
            end
            
            FULL_CT = 2;
            % final passes with the full set. 
            for iter = 1:FULL_CT
                passes{end+1} = trainingSetSize;
            end
        end

        % default sizes for a fixed number of passes. 
        function passes = default_passes_fixed_ct(obj,k_track,weights)
            DEFAULT_PASS_CT = 5;
            passes = {};
            base = nthroot(size(k_track,1),DEFAULT_PASS_CT);
            % trainingSetSize = size(k_track,1);
            trainingSetSize = sum(weights > 0);
            
            % build the default pass sequence.
            for pass = 1:DEFAULT_PASS_CT
                if pass == DEFAULT_PASS_CT
                    passSize = trainingSetSize;
                else
                    passSize = clamp(1,round(base.^pass),trainingSetSize);
                end
                
                passes{end+1} = passSize;
            end
        end
            
        function model = one_training_pass(obj,pass,model)
            % compute the new feats for each frame
            bj.new_negs = {};
            obj.new_negs_weights = {};
            obj.new_poss = {};
            obj.new_poss_weights = {};
            passSize = obj.passes{pass};            
            if passSize >= 32
                % use a local cluster because of network overhead.
                cluster_ctl('on','local');
            end
            frames = find(obj.weights > 0) - 1;
            rand_frame_order = frames(randi([1,numel(frames)],size(obj.track,1),1));
            maxneg = round((model.qp.nmax - model.qp.n)./passSize);
            detector = model.detector();
            parfor pFrameIter = 1:passSize
                [np,npw,nn,nnw] = obj.svs_for_pass...
                    (detector,pFrameIter,rand_frame_order,maxneg,passSize,frames,pass);
                new_poss{pFrameIter} = np;
                new_poss_weights{pFrameIter} = npw;
                new_negs{pFrameIter} = nn;
                new_negs_weights{pFrameIter} = nnw;
            end
            % copy into the object
            obj.new_poss = new_poss;
            obj.new_poss_weights = new_poss_weights;
            obj.new_negs = new_negs;
            obj.new_negs_weights = new_negs_weights;
            cluster_ctl('off');
            
            % train with the new feats
            %keyboard;
            model = obj.train_all_commit(model);
            %keyboard;
        end

        function [np,npw,nn,nnw] = svs_for_pass...
                (obj,detector,pFrameIter,rand_frame_order,maxneg,passSize,frames,pass)
            if passSize == numel(frames)
                frameIter = frames(pFrameIter);
            else
                frameIter = rand_frame_order(pFrameIter);
            end
            fprintf('train_all pass %d: visiting  %d of %d\n',...
                    pass,frameIter,size(obj.track,1));
            curPos = obj.track(frameIter+1,:);
            b_pos = rectKtoB(curPos);
            
            % find margin violators.
            weight = obj.weights(frameIter+1);         
            if weight > 0 
                imN = get_frame(obj.vidName,frameIter);
                imsz = rect_size(rect_image(imN));
                dtsz = rect_size(curPos);
            end
            
            new_pos = [];
            new_neg = [];
            if weight > 0 && all(dtsz < imsz) && gt_valid(curPos);
                [featPyr,scale] = featpyramid(imN, detector.sbin, detector.interval);
                if obj.p > 0
                    new_pos = detector.training_pos(b_pos,imN,weight);
                    np = weight.*new_pos.*detector.getJpos();
                    npw = double(repmat(weight.*detector.getJpos(),[size(new_pos,2),1]));
                end
                if obj.n > 0
                    new_neg = detector.training_neg(b_pos,imN,weight,featPyr,scale,maxneg);
                    nn = weight.*-new_neg;
                    nnw = double(repmat(weight,[size(new_neg,2),1]));
                end
                %showBox(imN,curPos);        
            end
            
            xlen = numel(detector.getW())+1;
            if isempty(new_pos)
                np = zeros(xlen,0);
                npw = double([]);
            end
            if isempty(new_neg)
                nn = single(zeros(xlen,0));
                nnw = double([]);
            end
            
            % the first frame must always contain one positive
            % support vector.
            assert(~(frameIter == 0 && isempty(np) && obj.p > 0));
        end
        
        % add all the Support Vectors we found into the cache and optimize.
        function model = train_all_commit...
                (obj,model)
            function c = c2d(c)
                c = cellfun(@(x) double(x), c, 'UniformOutput', false);
            end
            
            %keyboard;
            new_neg = cell2mat(c2d(obj.new_negs));
            new_pos = cell2mat(c2d(obj.new_poss));
            neg_weight = cell2mat(obj.new_negs_weights');
            pos_weight = cell2mat(obj.new_poss_weights');
            fprintf('train_all: writing %d new examples\n',size(new_neg,2)+size(new_pos,2));
            qp = model.qp_get();
            % pos
            qp = qp_write(qp,new_pos,pos_weight,model.Jpos,1);
            % neg
            qp = qp_write(qp,new_neg,neg_weight,1,0);
            % opt
            qp = qp_opt(qp);
            qp = qp_prune(qp);
            % update
            model = model.qp_set(qp);
            model = model.updateModel(model.Jpos);
            fprintf('train_all_commit: model updated\n');
            
            % Show the updated model...
            showModel(model.w); drawnow;
        end
    end
end

