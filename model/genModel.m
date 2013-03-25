% JSS3 - 2012.5.29
% high level, give a valid blank model for the video.
function [model,Jpos,C] = genModel(varargin)   
    model = Model('gen',varargin{:});
    Jpos = model.getJpos();
    C = model.getQP().getC();
end

% with AREA = 80
% 
% C = .01 gives .6549 on coke11
% C = .05 gives .7080 on coke11
% C = .5  gives .72

% with AREA = 40
% C = .5
