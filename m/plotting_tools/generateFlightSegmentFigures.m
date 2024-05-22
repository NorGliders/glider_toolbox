function [figure_info, num_lines, dos_name, mission_name] = generateFlightSegmentFigures(dba_file, deployment, segment_dir)
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

% for testing
% dba_file = '/home/fel063/glider/data/real_time/202107_sl_urd_noremso_greenland/ascii/urd-2021-223-0-28-sbd.dba';


%% --- Setup ---
[~,file_name, ~] = fileparts(dba_file);
segment_name = file_name(1:end-4);
fprintf(1, '\nPlotting: %s \n', file_name);

output_dir  = fullfile(segment_dir,strrep(segment_name,'-','_'));
col         = linspecer(7);
plotFiles   = {};
figure_info = 0;

% Load SBD data
[meta, data] = dba2mat(dba_file, 'sensors', 'all'); % options.sensors
dos_name = meta.headers.the8x3_filename;
mission_name = meta.headers.mission_name;
[num_lines, num_sensors] = size(data);
if num_lines <= 5
    figure_info = 2; % not enough data points 
    fprintf(1, '    Not plotting, only %i data points\n',num_lines);
    return
end
[~, loc] = ismember('m_present_time',meta.sensors);
time = ut2mt(data(:,loc));
[~, loc] = ismember('m_depth',meta.sensors);
depth_ind = ~isnan(data(:,loc));
depth = data(depth_ind,loc);
depth_time = time(depth_ind);
list_sensors = [meta.sensors; 'depth_rate'];


%% --- Plot sensors ---
% Make segment directory
if numel(depth) >= 2
    [status, attrout] = fileattrib(output_dir);
    if ~status
        [status, message] = mkdir(output_dir);
    end
    
    for sensor_ind = 1:numel(list_sensors)
        varname =  list_sensors{sensor_ind};
        clear l n
        
        % If sensor is depth_rate, set to same value as depth
        if strcmp(varname,'depth_rate')
            [~, loc] = ismember('m_depth',meta.sensors);
            sensor_ind = loc;
        end
        
        if ~contains(varname,{'m_present_time','m_lat','m_lon','m_gps_lat',...
                'm_gps_lon','m_water_vx','m_water_vy','c_battpos',...
                'c_de_oil_vol','c_heading','m_altitude','m_present_secs_into_mission'})
            ind = ~isnan(data(:,sensor_ind));
            this_data = data(ind,sensor_ind);
            this_time = time(ind);
            unit = meta.units{sensor_ind};
            location = 'SouthEast';
            plot_extra = 0;
            plot_type = 'yaxis2';
            ydir = 'normal';
            
            % Proceed if there are more than 2 data points
            if numel(this_data) > 1
                disp(['   Plotting sensor: ' varname])
                % Make figure changes based on sensor here
                switch varname
                    case {'m_pitch'}
                        this_data = rad2deg(this_data);
                        
                        unit = 'degrees';
                        legend_text = {'pitch','abs dive pitch','depth', 'median dive','abs median climb','horizontal'};
                        if any(this_data<0)
                            % Dont add extra lines if theres not enough points below zero
                            plot_extra = 1;
                        end
                    case {'m_roll'}
                        this_data = rad2deg(this_data);
                        unit = 'degrees';
                    case 'm_battpos'
                        location = 'NorthEast';
                        extra_varname = 'c_battpos';
                        [lac, loc] = ismember(extra_varname,meta.sensors);
                        if lac
                            ind_c = ~isnan(data(:,loc));
                            this_data_c = data(ind_c,loc);
                            this_time_c = time(ind_c);
                            if numel(this_time_c) >= 2
                                plot_extra = 1;
                                legend_text = {'measured','depth','commanded'};
                            end
                        end
                    case 'm_de_oil_vol'
                        extra_varname = 'c_de_oil_vol';
                        [lac, loc] = ismember(extra_varname,meta.sensors);
                        if lac
                            ind_c = ~isnan(data(:,loc));
                            this_data_c = data(ind_c,loc);
                            this_time_c = time(ind_c);
                            if numel(this_time_c) >= 2
                                plot_extra = 1;
                                legend_text = {'measured','depth','commanded'};
                            end
                        end
                    case 'm_heading'
                        unit = 'degrees';
                        this_data = rad2deg(this_data);
                        extra_varname = 'c_heading';
                        [lac, loc] = ismember(extra_varname,meta.sensors);
                        if lac
                            ind_c = ~isnan(data(:,loc));
                            this_data_c = rad2deg(data(ind_c,loc)); 
                            this_time_c = time(ind_c);
                            if numel(this_time_c) >= 2
                                plot_extra = 1;
                                legend_text = {'measured','depth','commanded'};
                            end
                        end
                    case 'm_fin'
                        unit = 'degrees';
                        this_data = rad2deg(this_data);
                        extra_varname = 'c_fin';
                        [lac, loc] = ismember(extra_varname,meta.sensors);
                        if lac
                            ind_c = ~isnan(data(:,loc));
                            this_data_c = data(ind_c,loc);
                            this_time_c = time(ind_c);
                            if numel(this_time_c) >= 2
                                plot_extra = 1;
                                legend_text = {'measured','depth','commanded'};
                            end
                        end
                    case 'm_depth'
                        plot_type = 'landscape';
                        extra_varname = 'm_altitude';
                        ydir = 'rev';
                        [lac, loc] = ismember(extra_varname,meta.sensors);
                        if lac
                            ind_c = ~isnan(data(:,loc));
                            this_data_c = data(ind_c,loc);
                            this_time_c = time(ind_c);
                            if numel(this_time_c) >= 2
                                plot_extra = 1;
                                legend_text = {'depth','altitude'};
                            end
                        end
                    case 'depth_rate'
                        plot_extra = 1;
                        unit = 'm/s';
                        location = 'SouthWest';
                        legend_text = {'depth rate','depth','abs depth rate','median dive', 'median climb','stationary'};
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
                [fh,ah] = plot_default(plot_type,[segment_name '-' varname]);
                time_bounds = [min(this_time) max(this_time)];
                n = 0;
                
                % Sensor axes
                n = n + 1;
                axes(ah(1))
                l(n) = line(this_time,this_data,'col',col(n,:),'Marker','o','MarkerSize',4,'MarkerFaceColor',col(n,:));
                set(ah(1),'XColor','k','YColor','k','Xlim',time_bounds,'Ydir',ydir);
                datetick(ah(1), 'keeplimits')
                ylabel(ah(1), [varname '  (' unit ')'],'Interpreter','none');
                
                % Depth axes
                if strcmp(plot_type,'yaxis2') && ~strcmp(varname,'m_depth')
                    n = n + 1;
                    axes(ah(2))
                    l(n) = line(depth_time,depth,'col',col(n,:),'Parent',ah(2));
                    set(ah(2),'XColor','k','YColor',col(n,:),'Xlim',time_bounds,'XTickLabel','','Color','none','ydir','rev','XGrid','off','XTickMode','manual');
                    ylabel(ah(2),'Depth (m)');
                end
                
                % Add additional lines based on sensor here
                if plot_extra
                    
                    %%
                    % *axes(ah(1))*
                    n = n + 1;
                    if strcmp(varname,'m_pitch')
                        l(n) = line(this_time(this_data<0), abs(this_data(this_data<0)),'Parent',ah(1),'col',col(n,:),'Marker','o','MarkerSize',4,'MarkerFaceColor',col(n,:));
                        n = n + 1;
                        l(n) = line(time_bounds, nanmedian(this_data(this_data>0))*[1 1],'Parent',ah(1),'LineStyle','--','col',col(n,:)); % climb median
                        n = n + 1;
                        l(n) = line(time_bounds, abs(nanmedian(this_data(this_data<0)))*[1 1],'Parent',ah(1),'LineStyle','--','col',col(n,:)); % dive median
                        n = n + 1;
                        l(n) = line(time_bounds, [0 0],'Parent',ah(1),'LineStyle','--','col','k');
                    elseif strcmp(varname,'m_depth')
                        l(n) = line(this_time_c,this_data_c,'col',col(n,:),'Marker','o','MarkerSize',4,'MarkerFaceColor',col(n,:),'linestyle','none');
                    elseif strcmp(varname,'depth_rate')
                        l(n) = line(this_time,abs(this_data),'col',col(n,:),'Marker','o','MarkerSize',4,'MarkerFaceColor',col(n,:));
                        n = n + 1;
                        l(n) = line([min(this_time) max(this_time)], [nanmedian(this_data(this_data>0)) nanmedian(this_data(this_data>0))],'LineStyle','--','col',col(n,:));
                        n = n + 1;
                        l(n) = line([min(this_time) max(this_time)], [abs(nanmedian(this_data(this_data<0))) abs(nanmedian(this_data(depthRate<0)))],'LineStyle','--','col',col(n,:));
                        n = n + 1;
                        l(n) = line([min(this_time) max(this_time)], [0 0],'LineStyle','--','col','k');
                    else
                        if numel(this_time_c) >= 2
                            l(n) = line(this_time_c,this_data_c,'col',col(n,:),'Marker','o','MarkerSize',4,'MarkerFaceColor',col(n,:));
                        end
                    end
                    legend(l(:),legend_text,'fontsize',8,'fontname','Calibri','Interpreter','none','Location',location);
                end
                
                if strcmp(plot_type,'yaxis2'); axes(ah(2));end
                
                title([varname ': ' segment_name ],'Interpreter','none','fontweight','normal');
                print_fig(output_dir)
                plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png']; 
                close(fh);
            else
                disp(['   Less than one data point, not plotting sensor: ' varname])
            end
        else
            disp(['   Not plotting sensor: ' varname])
        end
    end
    figure_info = 1;
else
    figure_info = 3; % not enough depth data points
    fprintf(1, '    Not plotting, only 2 depth values\n');
end
close all
pause(0.5)


