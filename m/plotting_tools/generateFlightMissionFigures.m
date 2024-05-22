function [figure_info, num_row_data] = generateFlightMissionFigures(raw_data, figure_list, varargin)
%GENERATEFLIGHTSEGMENTFIGURES  Generate figures from individual segments for flight glider data.
%
%  Syntax:
%    FIGURE_INFO = GENERATEGLIDERFIGURES(DATA, FIGURE_LIST)
%    FIGURE_INFO = GENERATEGLIDERFIGURES(DATA, FIGURE_LIST, OPTIONS)
%    FIGURE_INFO = GENERATEGLIDERFIGURES(DATA, FIGURE_LIST, OPT1, VAL1, ...)
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

narginchk(3, 20);

%% Get options from extra arguments.
% Parse option key-value pairs in any accepted call signature.
if isscalar(varargin) && isstruct(varargin{1})
    % Options passed as a single option struct argument:
    % field names are option keys and field values are option values.
    option_key_list = fieldnames(varargin{1});
    option_val_list = struct2cell(varargin{1});
elseif mod(numel(varargin), 2) == 0
    % Options passed as key-value argument pairs.
    option_key_list = varargin(1:2:end);
    option_val_list = varargin(2:2:end);
else
    error('glider_toolbox:processGliderData:InvalidOptions', ...
        'Invalid optional arguments (neither key-value pairs nor struct).');
end
% Overwrite default options with values given in extra arguments.
for opt_idx = 1:numel(option_key_list)
    opt = lower(option_key_list{opt_idx});
    val = option_val_list{opt_idx};
    options.(opt) = val;
end


%% --- Setup ---
[figure_plot, plot_these_sensors] = configFlightMissionFigures();

output_dir = options.dirname;
available_sensors = fieldnames(raw_data);
plot_these_sensors_names = fieldnames(plot_these_sensors);
output_dir  = varargin{4};
col         = linspecer(7);
plotFiles   = {};
figure_info = 0;

[num_row_data, ~] = size(raw_data.m_present_time);
time = ut2mt(raw_data.m_present_time);
sci_time = ut2mt(raw_data.sci_m_present_time);
depth = raw_data.m_depth;
depth_ind = ~isnan(depth);
clean_depth = depth(depth_ind);

if num_row_data <= 2 || numel(clean_depth) <= 2
    figure_info = 2; % not enough data points
    fprintf(1, '    Not plotting, only %i data points\n',num_row_data);
    return
end

% Make segment directory
[status, attrout] = fileattrib(output_dir);
if ~status
    [status, message] = mkdir(output_dir);
end


%% --- Plot sensors ---
for ind_sensor = 1:numel(plot_these_sensors_names)
    sensor =  plot_these_sensors_names{ind_sensor};
    if ismember(sensor,available_sensors) || strcmp(sensor,'depth_rate')
        disp(['   Plotting sensor: ' sensor])
        clear l n this_time_c this_time_d legend_text
        
        if strcmp(sensor,'depth_rate')
            sensor_data = raw_data.m_depth;
        else
            sensor_data = raw_data.(sensor);
        end
        ind = ~isnan(sensor_data);
        this_data = sensor_data(ind);
        this_time = time(ind);
        unit = plot_these_sensors.(sensor).unit;
        location = 'SouthEast';
        %if numel(plot_these_sensors.(sensor).add_sensor)
        %    plot_extra = 1;
        %else
            plot_extra = 0;
        %end
        plot_type = 'landscape';
        ydir = 'normal';
        
        % Proceed if there are more than 2 data points
        if numel(this_data) > 1
            
            % Make figure changes based on sensor here
            switch sensor
                case 'm_bms_aft_current'
                    location = 'Best';
                    extra_sensor_name = 'm_bms_pitch_current';
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = raw_data.(extra_sensor_name)(ind_c);
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'m_bms_aft_current','m_bms_pitch_current'};
                        end
                    end
                    extra_sensor_name2 = 'm_bms_ebay_current';
                    [lac, ~] = ismember(extra_sensor_name2,available_sensors);
                    if lac
                        ind_d = ~isnan(raw_data.(extra_sensor_name2));
                        this_data_d = raw_data.(extra_sensor_name2)(ind_d);
                        this_time_d = time(ind_d);
                        if numel(this_time_d) >= 2
                            plot_extra = 1;
                            legend_text = {'m_bms_aft_current','m_bms_pitch_current','m_bms_ebay_current'};
                        end
                    end
                case 'm_leakdetect_voltage'
                    location = 'Best';
                    extra_sensor_name = 'm_leakdetect_voltage_forward';
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = raw_data.(extra_sensor_name)(ind_c);
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'m_leakdetect_voltage','m_leakdetect_voltage_forward'};
                        end
                    end
                    extra_sensor_name2 = 'm_leakdetect_voltage_science';
                    [lac, ~] = ismember(extra_sensor_name2,available_sensors);
                    if lac
                        ind_d = ~isnan(raw_data.(extra_sensor_name2));
                        this_data_d = raw_data.(extra_sensor_name2)(ind_d);
                        this_time_d = time(ind_d);
                        if numel(this_time_d) >= 2
                            plot_extra = 1;
                            legend_text = {'m_leakdetect_voltage','m_leakdetect_voltage_forward','m_leakdetect_voltage_science'};
                        end
                    end
                case 'm_pitch'
                    this_data = rad2deg(this_data);
                    unit = 'degrees';
                    legend_text = {'pitch'};
                    if any(this_data<0)
                        % Dont add extra lines if theres not enough points below zero
                        plot_extra = 1;
                    end
                case 'm_roll'
                    this_data = rad2deg(this_data);
                    unit = 'degrees';
                case 'm_battpos'
                    location = 'SouthEast';
                    extra_sensor_name = 'c_battpos';
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = raw_data.(extra_sensor_name)(ind_c);
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'measured','commanded'};
                        end
                    end
                case 'm_de_oil_vol'
                    extra_sensor_name = 'c_de_oil_vol';
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = raw_data.(extra_sensor_name)(ind_c);
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'measured','commanded'};
                        end
                    end
                case 'm_heading'
                    unit = 'degrees';
                    this_data = rad2deg(this_data);
                    extra_sensor_name = 'c_heading';
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = rad2deg(raw_data.(extra_sensor_name)(ind_c));
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'measured','commanded'};
                        end
                    end
                case 'm_fin'
                    unit = 'degrees';
                    this_data = rad2deg(this_data);
                    extra_sensor_name = 'c_fin';
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = rad2deg(raw_data.(extra_sensor_name)(ind_c));
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'measured','commanded'};
                        end
                    end
                case 'm_water_vx'
                    extra_sensor_name = 'm_water_vy';
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = raw_data.(extra_sensor_name)(ind_c);
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'m_water_vx','m_water_vy'};
                        end
                    end
                case 'm_depth'
                    plot_type = 'landscape';
                    extra_sensor_name = 'm_altitude';
                    ydir = 'rev';
                    legend_text = {'depth'};
                    [lac, ~] = ismember(extra_sensor_name,available_sensors);
                    if lac
                        ind_c = ~isnan(raw_data.(extra_sensor_name));
                        this_data_c = raw_data.(extra_sensor_name)(ind_c);
                        this_time_c = time(ind_c);
                        if numel(this_time_c) >= 2
                            plot_extra = 1;
                            legend_text = {'depth','altitude'};
                        end
                    end
                case 'depth_rate'
                    location = 'SouthWest';
                    legend_text = {'depth rate','median dive (abs)', 'median climb','stationary'};
                    dz = zeros(size(this_data))*nan; dz(1) = 0;
                    dt = zeros(size(this_data))*nan; dt(1) = 0;
                    for i = 2:length(this_time)
                        dz(i) =  this_data(i)-this_data(i-1);
                        dt(i) =  this_time(i)-this_time(i-1);
                    end
                    dt = dt * 86400;
                    depthRateRaw    = dz./dt;
                    depthRateRaw(1) = 0;
                    depthRateRaw(2) = 0;
                    depthRate       = runmean(depthRateRaw,2,2);
                    this_data = depthRate;
            end
            
            % Create figure
            [fh,ah] = plot_default(plot_type,[sensor]);
            time_bounds = [min(this_time) max(this_time)];
            n = 0;
            
            % Sensor axes
            n = n + 1;
            axes(ah(1))
            l(n) = line(this_time,this_data,'col',col(n,:),'Marker','.','MarkerSize',4,'MarkerFaceColor',col(n,:), 'linestyle','none');
            set(ah(1),'XColor','k','YColor','k','Xlim',time_bounds,'Ydir',ydir);
            datetick(ah(1), 'keeplimits')
            ylabel(ah(1), [sensor '  (' unit ')'],'Interpreter','none');
            
            
            % Add additional lines based on sensor here
            if plot_extra
                n = n + 1;
                if strcmp(sensor,'m_pitch')
                    n = n + 1;
                    line(time_bounds, [0 0],'Parent',ah(1),'LineStyle','--','col','k');
                    line(time_bounds, [26 26],'Parent',ah(1),'LineStyle','--','col','k');
                    line(time_bounds, [-26 -26],'Parent',ah(1),'LineStyle','--','col','k');
                elseif strcmp(sensor,'m_depth')
                    l(n) = line(this_time_c,this_data_c,'col',col(n,:),'Marker','.','MarkerSize',4,'MarkerFaceColor',col(n,:),'linestyle','none');
                elseif strcmp(sensor,'depth_rate')
                    l(n) = line([min(this_time) max(this_time)], [nanmedian(this_data(this_data>0)) nanmedian(this_data(this_data>0))],'LineStyle','--','col',col(n,:));
                    n = n + 1;
                    l(n) = line([min(this_time) max(this_time)], [abs(nanmedian(this_data(this_data<0))) abs(nanmedian(this_data(depthRate<0)))],'LineStyle','--','col',col(n,:));
                    n = n + 1;
                    l(n) = line([min(this_time) max(this_time)], [0 0],'LineStyle','--','col','k');
                elseif strcmp(sensor,'m_heading')
                    l(n) = line(this_time_c,this_data_c,'col',col(n,:),'Marker','.','MarkerSize',4,'MarkerFaceColor',col(n,:), 'linestyle','none');
                    set(gca, 'YLim',[0 360], 'YTick',[0:45:360], 'YTickLabel', {'N','NE','E','SE','S','SW','W','NW','N'})
                else
                    if exist('this_time_c','var') && numel(this_time_c) >= 2
                        l(n) = line(this_time_c,this_data_c,'col',col(n,:),'Marker','.','MarkerSize',4,'MarkerFaceColor',col(n,:), 'linestyle','none');
                    end
                    if exist('this_time_d','var') && numel(this_time_d) >= 2
                        n = n + 1;
                        l(n) = line(this_time_d,this_data_d,'col',col(n,:),'Marker','.','MarkerSize',4,'MarkerFaceColor',col(n,:), 'linestyle','none');
                    end
                end
                legend(l(:),legend_text,'fontsize',8,'fontname','Calibri','Interpreter','none','Location',location);
            end
            title([sensor],'Interpreter','none','fontweight','normal');
            print_fig(output_dir)
            plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
            close(fh);
        else
            disp(['   Less than one data point, not plotting sensor: ' sensor])
        end
    else
        disp(['   Not plotting sensor: ' sensor])
    end
end
figure_info = 1;

close all
pause(0.5)


