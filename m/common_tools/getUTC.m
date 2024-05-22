function [UTC] = getUTC()

%-----------
% MATLAB doesn't provide native timezone conversion.
% USE THIS HACK FOR THE TIME BEING
% Attempts to adjust for daylight
% NZ only
%-----------
timeNow = now;
UTC = [datestr(now - 2/24) 'Z'];

% if timeNow > datenum(2017,9,25) && timeNow < datenum(2018,4,2)
%     % Time zone = NZDT
%     UTC = [datestr(now - 2/24) 'Z'];
% else
%     % Time zone = NZST
%     UTC = [datestr(now - 12/24) 'Z'];
% end