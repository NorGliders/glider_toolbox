function [figure_info, num_lines, dos_name, mission_name]  = generateScienceSegmentFigures(dba_file, deployment, segment_dir)
%GENERATESCIENCESEGMENTFIGURES  Generate figures from individual segments for flight glider data.
%
%  Syntax:
%    FIGURE_INFO = GENERATESCIENCESEGMENTFIGURES(DATA, FIGURE_LIST)
%    FIGURE_INFO = GENERATESCIENCESEGMENTFIGURES(DATA, FIGURE_LIST, OPTIONS)
%    FIGURE_INFO = GENERATESCIENCESEGMENTFIGURES(DATA, FIGURE_LIST, OPT1, VAL1, ...)
%
%  See also:
%    PRINTFIGURE
%    PLOTTRANSECTVERTICALSECTION
%    PLOTTSDIAGRAM
%    PLOTPROFILESTATISTICS
%    CONFIGFIGURES
%    DATESTR
%    NOW
%
%  Authors:
%    Joan Pau Beltran  <joanpau.beltran@socib.cat>
%    Fiona Elliott     <fiona.elliott@uib.no>

%  Copyright (C) 2013-2016
%  ICTS SOCIB - Servei d'observacio i prediccio costaner de les Illes Balears
%  <http://www.socib.es>
%  UIB GFI NorGliders - Universitet i Bergen, Geofysisk Institutt
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.

% narginchk(3, 20);

% for testing
%dba_file = '/home/fel063/glider/data/real_time/202107_sl_urd_noremso_greenland/ascii/urd-2021-189-7-100-tbd.dba';
%segment_dir = '/home/fel063/glider/data/real_time/202107_sl_urd_noremso_greenland/segments';


%% --- Setup ---
[~,file_name, ~] = fileparts(dba_file);
segment_name = file_name(1:end-4);
fprintf(1, '   Plotting: %s \n', file_name);

output_dir  = fullfile(segment_dir,strrep(segment_name,'-','_'));
col         = linspecer(7);
plotFiles   = {};
figure_info = 0;
lat         = 70;

% Load SBD data
[meta, data] = dba2mat(dba_file, 'sensors', 'all'); % options.sensors
dos_name = meta.headers.the8x3_filename;
mission_name = meta.headers.mission_name;
[num_lines, num_sensors] = size(data);
if num_lines <= 1
    figure_info = 2; % 1 data point 
    return
end
[~, loc] = ismember('sci_m_present_time',meta.sensors);
time = ut2mt(data(:,loc));
[~, loc] = ismember('sci_water_pressure',meta.sensors);
depth_ind = ~isnan(data(:,loc));
depth = sw_dpth(data(depth_ind,loc),lat);   %TODO read in deployment info
depth_time = time(depth_ind);
list_sensors = {'sci_water_cond', 'sci_water_pressure', 'sci_water_temp'};


%% --- Plot sensors ---
% Make segment directory
if numel(depth) >= 2
    [status, attrout] = fileattrib(output_dir);
    if ~status
        [status, message] = mkdir(output_dir);
    end
    
    % CTD is default
    [loc, lac] = ismember('sci_water_pressure',meta.sensors);
    pre = data(:,lac) * 10; % bar to dbar
    [loc, lac] = ismember('sci_water_temp',meta.sensors);
    tem = data(:,lac);
    [loc, lac] = ismember('sci_water_cond',meta.sensors);
    con = data(:,lac);
    % Calculate derived variables
    dep     = sw_dpth(pre,lat);
    c3515   = sw_c3515*0.1;
    sal     = real(sw_salt(con/c3515, tem, pre));
    tem     = real(tem);
    pden    = real(sw_pden(sal, tem, pre, 0.0) - 1000.0);     % Potential density
    % Replace typically bad values
    tem(sal < 0.01) = NaN;
    sal(sal < 0.01) = NaN;
    pden(pden< 0.01) = NaN;
    % Remove NaN's (use original var name if interpolating)
    dep1 = dep(~isnan(tem));
    sal1 = sal(~isnan(tem));
    tem1 = tem(~isnan(tem));
    % Use this for other sensors
    %depNoNan = dep(~isnan(dep));
    %timeDepNoNan = time(~isnan(dep));
    
    % --- Limits
    dMin    = 0;
    dMax    = ceil(max(dep)*1.1);
    %[tMin,tmax] = find_limits_test(tem);
    %[sMin,smax] = find_limits_test(sal);
    
    
    % Plot 1: Temperature and Salinity profiles
    try
        inflection_points = find(abs(diff(dep(~isnan(tem)))) > (dMax-dMin)*.5);
        dep2 = dep1; tem2 = tem1; sal2 = sal1;
        % insert NaN at inflection points in dep1 , tem1, sal1
        for i = 1:numel(inflection_points)
            num = inflection_points(i);
            dep2 = [dep2(1:num); NaN; dep2(num+1:end)];
            tem2 = [tem2(1:num); NaN; tem2(num+1:end)];
            sal2 = [sal2(1:num); NaN; sal2(num+1:end)];
            inflection_points = inflection_points +1;
            %     disp(['length of dep1 is ' num2str(numel(dep1))])
        end
        
        % Plot
        [fh, ah] = plot_default('portrait',[segment_name '-CTD_profile']);
        set(ah,'YDir','reverse','XaxisLocation','top','XColor',col(1,:)); %,'XLim',[tMin,tmax]);
        
        hl1 = line(tem2,dep2,'Marker','.','Color',col(1,:),'MarkerSize',8,'Parent',ah);
        yl = get(ah,'ylim');
        set(ah,'ylim',[dMin yl(2)]);
        
        xlabel('Temperature (ITS-90, \circC)', 'FontSize', 10);
        ylabel('Depth (m)', 'FontSize', 11);
        %title(['CTD Profile: ' segment_name], 'FontSize', 11, 'Interpreter', 'none','Fontweight','normal');
        title(['CTD Profile: ' segment_name ],'Interpreter','none','fontweight','normal');
        grid on;
        
        ah2 = axes('Units','cen','YaxisLocation','right', 'Color', 'none', 'XColor', col(2,:),'Fontname','Calibri');
        hold on;
        set(ah2,'YDir','reverse','FontSize',10); % ,'XLim',[sMin,smax]);
        set(ah2,'Position',get(ah,'Position'));
        hl2 = line(sal2, dep2, 'Color', col(2,:), 'Marker', '.', 'MarkerSize', 8, 'Parent', ah2);
        yl = get(ah,'ylim');
        set(ah2,'ylim',yl,'YTickLabel','');
        
        xlabel('Salinity (PSS-78, PSU)','FontSize',10);
        %     legend([hl1,hl2],{'Temperature (^oC)','Salinity (PSU)'},'Fontname','Calibri','location','best');
        
        print_fig(output_dir)
        plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
        close(fh);
    catch
        disp([getUTC,': ERROR: can''t execute Plot 2: Salinity vs Temperature (TS) Scatter']);
        close(fh);
    end
    
    figure_info = 1;
end
close all



function [xMin, xMax] = find_limits_test(data)
%--------------------------------------------------------------------------
% [xmin, xmax] = find_limits(data,percentile,buffer,shorten_range)
%
% Find the max and min to the specified percentile (default 98%) of the
% data supplied.
% Tries to cut out outliers in data so they don't effect the plot
% presentation
%
% INPUTS:   -buffer: user defined buffer on either side of max and min
%            (default = .2). Only applies if the range is < 0.2
%           -shorten_range: user can opt to shorten range (default = off)
%
%
% NIWA Slocum toolbox
%
% History:
% 2015-Sep-11   FE
%--------------------------------------------------------------------------
if nargin < 1
    error('User has not provided enough input arguments')
end

% try remove low outliers
data(data < 0.01) = NaN;

myStd = nanstd(data);
myMean = nanmean(data);

xMin = floor(myMean - (2 * myStd));
xMax = ceil(myMean + (2 * myStd));