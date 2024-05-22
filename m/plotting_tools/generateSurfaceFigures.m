function generateSurfaceFigures(processed_logs, glider, figure_dir, units)
%GENERATESURFACEFIGURES  Generate figures from individual segments for flight glider data.
%
%  Syntax:
%    FIGURE_INFO = GENERATESURFACEFIGURES(DATA, FIGURE_LIST)
%    FIGURE_INFO = GENERATESURFACEFIGURES(DATA, FIGURE_LIST, OPTIONS)
%    FIGURE_INFO = GENERATESURFACEFIGURES(DATA, FIGURE_LIST, OPT1, VAL1, ...)
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

narginchk(4, 4);

if height(processed_logs) < 2
    return
end

disp('Plot surface data');
col = linspecer(4);
unit_names = fieldnames(units);
var_names  = processed_logs.Properties.VariableNames;
numeric_vars = varfun(@isnumeric,processed_logs,'output','uniform');
numeric_vars = var_names(numeric_vars);
remove_these = ismember(numeric_vars, {'bytes', 'verified', 'mission_time', 'DR_lat', 'DR_lon', 'GPS_lat', 'GPS_lon'});
numeric_vars = numeric_vars(~remove_these);
time = processed_logs.current_time; % data type: verd: datetime array
if ~isdatetime(time)
    time = datetime(time);
end

for i = 1:length(numeric_vars)
    [fh,~] = plot_default('surface',numeric_vars{i});
    this_var = processed_logs.(numeric_vars{i});
    if ismember(numeric_vars{i},unit_names)
        this_unit = units.(numeric_vars{i});
    else
        this_unit = 'nodim';
    end
    plot(time,this_var,'col',col(1,:),'Marker','.','MarkerSize',3,'Linestyle','-');
    
    % Current time series
    if strcmp(numeric_vars{i},'m_water_vx') && ismember ('m_water_vy', numeric_vars)
        hold on;
        plot(time,processed_logs.('m_water_vy'),'col',col(2,:),'Marker','.','MarkerSize',3,'Linestyle','-');
        lh = legend('V_x','V_y');
        set(lh,'FontSize',6,'FontName','Calibri','Orientation','horizontal','Location','best')
    end
    
    % Speed
    if strcmp(numeric_vars{i},'m_avg_climb_rate') && ismember('m_avg_dive_rate', numeric_vars)
        hold on;
        plot(time,processed_logs.('m_avg_dive_rate'),'col',col(2,:),'Marker','.','MarkerSize',6,'Linestyle','-');
        if ismember('m_avg_speed', numeric_vars)
            plot(time,processed_logs.('m_avg_speed'),'col',col(3,:),'Marker','.','MarkerSize',6,'Linestyle','-');
            lh = legend('dive speed','climb speed','average speed');
        else 
            lh = legend('dive speed','climb speed');
        end
        set(lh,'FontSize',6,'FontName','Calibri','Orientation','horizontal','Location','best')
    end
    
    set(gca,'Xlim',[min(time) max(time)]);
    title(numeric_vars{i},'Interpreter','none','fontweight','normal');
    ylabel(this_unit);
    print_fig(figure_dir)
    close(fh);
end

