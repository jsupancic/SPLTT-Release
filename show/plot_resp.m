% JSS3 2012-04-06
% MATLAB function to plot the response values
% against some other useful information.
function [p,r] = plot_resp(b_gts,k_boxes,vidName,show)    
    if nargin < 4
        show = 0;
    end
    
    makePlot = isempty(getCurrentTask) && show;
    if makePlot
        clf;
        hold on;
    end

    % compute the graph, frame by frame
    [cAccept,gAccept,nAccept,...
          goodIdx,goodResp,badIdx,badResp,...
          gtVisIdx,gtVisResp,trVisIdx,trVisResp] ...
        = plot_resp_accum(b_gts,k_boxes,vidName);

    if makePlot
        % plot visibilities
        phs = [];
        phs(end+1) = plot(gtVisIdx,gtVisResp,' o','DisplayName','gt accept');
        phs(end+1) = plot(trVisIdx,trVisResp,' s','DisplayName','tracker accept');
        % generate the plot
        phs(end+1) = plot(goodIdx,goodResp,'b+','DisplayName','Correct');
        phs(end+1) = plot(badIdx,badResp,'r+','DisplayName','Incorrect');
        legend show;
        
        % label the plot
        title(vidName);
        xlabel('Frame Number');
        ylabel('Cost');
    
        hold off;
        
        PRESENTATION = 1;
        if PRESENTATION
            legend hide;
            set(gca,'position',[0 0 1 1]) ;    
            h = gca;
            set(h,'XTick',[]);
            set(h,'YTick',[]);
            for iter = 1:numel(phs)
                set(phs(iter),'MarkerSize',12);
            end
        end
    end
    
    % report p and r
    cAccept
    gAccept
    nAccept
    p = cAccept/nAccept;
    r = cAccept/gAccept;
end

function [cAccept,gAccept,nAccept,...
          goodIdx,goodResp,badIdx,badResp,...
          gtVisIdx,gtVisResp,trVisIdx,trVisResp] ...
        = plot_resp_accum(b_gts,k_boxes,vidName)
    % precision = correctly accepted / number accepted    
    % recall = correctly accepted / gt accepted
    cAccept = 0;
    gAccept = 0;
    nAccept = 0;
    
    % error plotting
    goodIdx = [];
    goodResp = [];
    badIdx = [];
    badResp = [];
    % occlusion plotting
    gtVisIdx = [];
    gtVisResp = [];
    trVisIdx = [];
    trVisResp = [];
    
    for i = 2:size(b_gts,1)
        gt = b_gts(i,:);
        box = k_boxes(i,:);
        derivative = 0;
        if derivative
            lastBox = k_boxes(i-1,:);
        else
            lastBox = 2.*box;
        end
        
        % update the counts for p/r
        [l,c,g,n] = score_track_one(gt,box);
        cAccept = cAccept + c;
        gAccept = gAccept + g;
        nAccept = nAccept + n;
                
        % plot pt
        if l > 0
            if c > 0
                % correct
                goodIdx(end+1) = i;
                goodResp(end+1) = lastBox(5)-box(5);
            else
                % incorrect
                badIdx(end+1) = i;
                badResp(end+1) = lastBox(5)-box(5);
            end  
            
            if g > 0
                gtVisIdx(end+1) = i;
                gtVisResp(end+1) = lastBox(5)-box(5);
            end
            
            if n > 0
                trVisIdx(end+1) = i;
                trVisResp(end+1) = lastBox(5)-box(5);
            end
        end
    end    
end
