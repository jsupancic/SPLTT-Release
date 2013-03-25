% JSS3 - 2012-5-29
% define the global data storage location
function dp = datapath()
    HOSTNAME = getenv('HOSTNAME');
    
    if strcmp(HOSTNAME,'wildHOG')
        HOME = '/home/jsupanci/';
    else
        HOME = getenv('HOME');
    end
    
    dp = [HOME '/workspace/data/'];
    %dp
end
