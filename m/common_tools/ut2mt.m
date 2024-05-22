function[mt] = ut2mt(ut)

% convert unix time to matlab time

mt = ut/86400 + datenum(1970,1,1,0,0,0); 