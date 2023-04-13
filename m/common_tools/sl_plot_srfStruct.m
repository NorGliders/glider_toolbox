function sl_plot_srfStruct(cfg)
%--------------------------------------------------------------------------
% function sl_plot_srfStruct(cfg)
%
% NIWA Slocum toolbox
% 
% History:
% -2014       ANFOG
% 2015-Jun-17 FE    Adapted for the NIWA Slocum toolbox
% 2018-Jun-28 FE    Updated transect maps to use m_map toolbox and produce
% more informative plots
%--------------------------------------------------------------------------

%% --- Setup ---
% cfg = parse_config_file('\\hjemme.uib.no\fel063\Settings\Desktop\PROCESS\vessel-slocum-web-monitor\Process\Realtime\archive\durin.cfg');
disp('---------------------------------------------------------------------');
disp([getUTC,': STARTING ',mfilename]);

glider      = cfg.GLIDER;
mission     = cfg.MISSION;
col         = linspecer(4); % colormap for plots
dataDir     = cfg.PROJECT_DIR;
surfDir     = fullfile(cfg.PROJECT_DIR,'surface\');

load(fullfile(dataDir,[glider,'_srfStruct.mat']));

numSegs = length(srfStruct);
if numSegs==1
    return
end
varName  = fieldnames(srfStruct(1).Sensors);

% Initialise variables
for i=1:length(varName)
    str=[varName{i},'=[];'];
    eval(str);
end
clear('str');

% Write data to variables
% FE jun 2015 - edited to add NaNs to non existent sensor
for i=1:numSegs
    for ii=1:length(varName)
        str=[varName{ii},'=vertcat(',varName{ii},',srfStruct(',num2str(i),').Sensors.',varName{ii},'(1));'];
        try
            eval(str);
        catch ME
            if (strcmp(ME.identifier,'MATLAB:nonExistentField'))
                disp(['ERROR: ' ME.message])
                disp(['Assigning sensor ' varName{ii} ' to NaN'])
                str=[varName{ii},'=vertcat(',varName{ii},',NaN);'];
                eval(str);
            end
        end
        
    end
end
clear('str');

for i=1:numSegs
    CurrentTimeNum(i,1) = srfStruct(i).CurrentTimeNum;
    GPSLat(i,1)         = srfStruct(i).GPSLocation(1);
    GPSLon(i,1)         = srfStruct(i).GPSLocation(2);
end

% Find valid positions
ind = find(GPSLat<90);
lat = GPSLat(ind);
lon = GPSLon(ind);
t   = CurrentTimeNum(ind);

% Interpolate positionhs to 1min intervals
ti   = [min(t):1/1440:max(t)]';
lati = interp1(t,lat,ti);
loni = interp1(t,lon,ti);

% Current waypoint
[currentWptLat, currentWptLon] = nmea2deg(c_wpt_lat(end),c_wpt_lon(end));


%% --- Create maps ---
% Write transect info variable
[trInfo] = sl_transect(t,cfg,dataDir);

%% --- Plotting

% 0. Map plot
for i = 1:size(trInfo,1)
    startInd = dsearchn(ti,trInfo{i,1});
    endInd   = dsearchn(ti,trInfo{i,2});
    
    fname = ['Glider Track - ',trInfo{i,4}];
    [fh,~] = create_surface_topo(strrep(fname,' ',''),'tracks');
    if cfg.SHOW_PLOTS == 0
        set(fh,'visible', 'off');
    end
    title(fname,'Fontsize',11,'FontWeight','normal');
    m(1) = m_line(loni,lati,'col',[0.5, 0.5, 0.5],'linestyle','-', 'LineWidth',0.4);
    m(2) = m_line(loni(startInd:endInd),lati(startInd:endInd),'col',col(1,:),'linestyle','-', 'LineWidth',1.5);
    
    % Add current vectors
    hh = ~isnan(m_water_vx);
    m(3) = m_quiver(lon(hh),lat(hh),m_water_vx(hh),m_water_vy(hh),'col',[0.5, 0.5, 0.5],'linestyle','-', 'LineWidth',0.4);
    m(4) = m_line(loni(startInd),lati(startInd),'col','k','Marker','o','Markersize',6,'Markerfacecolor',col(3,:),'linestyle','none');
    m(5) = m_line(loni(endInd),lati(endInd),'col','k','Marker','o','Markersize',6,'Markerfacecolor',col(2,:),'linestyle','none');
    if ~any(isnan([currentWptLat; currentWptLon]))
        m(6) = m_line(currentWptLon,currentWptLat,'col','k','Marker','o','Markersize',6,'Markerfacecolor',col(4,:),'linestyle','none');
        m(7) = m_line([currentWptLon loni(endInd)],[currentWptLat lati(endInd)],'col',col(4,:),'linestyle',':', 'LineWidth',1.5);        
        legend([m(3) m(4) m(5) m(6)],{'Depth averaged currents',['Start surfacing: ' datestr(ti(startInd),'dd-mmm HH:MM')],['Latest surfacing: ' datestr(ti(endInd),'dd-mmm HH:MM')],...
            'Current waypoint'},'fontsize',10,'location','best');
    else
        legend([m(3) m(4) m(5)],{'Depth averaged currents',['Start surfacing: ' datestr(ti(startInd),'dd-mmm HH:MM')],['Latest surfacing: ' datestr(ti(endInd),'dd-mmm HH:MM')]},...
            'fontsize',10);
    end
    print_fig(surfDir)
    
    if strcmp(trInfo{i,4},'Entire Mission')
        savefig(fh,fullfile(dataDir,[get(fh,'tag') '.fig']));
    end
    close(fh);
end


%% --- Time series plots ---
% --- Set general plotting parameters    

xmin = min(CurrentTimeNum);
xmax = max(CurrentTimeNum);

% 1. Current time series
if exist('m_water_vx','var')
    [fh,ah] = plot_default('surface','srf_dac');
    if cfg.SHOW_PLOTS == 0
        set(fh,'visible', 'off');
    end
    plot(CurrentTimeNum,m_water_vx,'col',col(1,:),'Marker','.','MarkerSize',6,'Linestyle','-');
    hold on;
    plot(CurrentTimeNum,m_water_vy,'col',col(2,:),'Marker','.','MarkerSize',6,'Linestyle','-');
    if xmax>xmin
        set(gca,'Xlim',[xmin xmax]); %,'Box','On','FontSize',txtSize
    end
    title('Estimated Depth Averaged Currents','FontWeight','normal');
    ylabel('ms^-^1');
    %datetick('x','keeplimits');
    xtimelab(ah)
    lh = legend('V_x','V_y');
    set(lh,'FontSize',6,'FontName','Calibri','Orientation','horizontal','Location','best')
    print_fig(surfDir)
    close(fh);
end

% 1. Speed
if exist('m_avg_climb_rate','var') && exist('m_avg_dive_rate','var') && exist('m_avg_speed','var')
    [fh,ah] = plot_default('surface','speed');
    if cfg.SHOW_PLOTS == 0
        set(fh,'visible', 'off');
    end
    plot(CurrentTimeNum,abs(m_avg_dive_rate),'col',col(1,:),'Marker','.','MarkerSize',6,'Linestyle','-');
    hold on;
    plot(CurrentTimeNum,abs(m_avg_climb_rate),'col',col(2,:),'Marker','.','MarkerSize',6,'Linestyle','-');
    plot(CurrentTimeNum,m_avg_speed,'col',col(3,:),'Marker','.','MarkerSize',6,'Linestyle','-');
    if xmax>xmin
        set(gca,'Xlim',[xmin xmax]); %,'Box','On','FontSize',txtSize
    end
    title('Vehicle speed','FontWeight','normal');
    ylabel('ms^-^1');
    %datetick('x','keeplimits');
    xtimelab(ah)
    lh = legend('dive speed','climb speed','average speed');
    set(lh,'FontSize',6,'FontName','Calibri','Orientation','horizontal','Location','best')
    print_fig(surfDir)
    close(fh);
end

% Open text files containing variable units
fileID = fopen(fullfile(cfg.PROCESS_DIR,'surface.txt'),'r');
S = textscan(fileID, '%s%s%[^\n\r]', 'Delimiter', ',',  'ReturnOnError', false);
fclose(fileID);
surface_units = [deblank(S{1,1}) deblank(S{1,2})]; 

for i = 1:length(varName)
    [fh,ah] = plot_default('surface',varName{i});
    if cfg.SHOW_PLOTS == 0
        set(fh,'visible', 'off');
    end
    plot(CurrentTimeNum,eval(varName{i}),'col',col(1,:),'Marker','+','MarkerSize',3,'Linestyle','-');
    if xmax > xmin
        set(gca,'Xlim',[xmin xmax]); %,'Box','On','FontSize',txtSize
    end
    title(varName{i},'Interpreter','none','fontweight','normal');
    [~, loc] = ismember(varName{i},surface_units(:,1));
    if loc
        ylabel(surface_units{loc,2});
    end
    %datetick('x','keeplimits');
    xtimelab(ah)

    print_fig(surfDir)
    close(fh);
end

disp([getUTC,': FINISHED ',mfilename]);

end


% %% --- Sub Function to configure plots ---
% function plt_default1(mkfig)
% %-----------------------------------------
% % Dimensions - centimeters
% figPos  = [0 0 13 4.5];
% axPos   = [1.5 1.5 11 2.0];
% 
% if nargin >= 1 && mkfig == 1
%     hf = figure('Units','Centimeters','Position',figPos);
%     ah = axes('Units','cen','fontsize',8, 'FontName','Calibri','Position',axPos);
% else
%     hf = gcf;
%     ah = gca;
% end
% 
% movegui('center');
% 
% set(hf,'Units','Centimeters','NumberTitle','off','color','white','PaperPosition',get(gcf,'Position'))
% set(gca,'FontSize',8,'FontName','Calibri','Units','Centimeters','box','on');
% 
% if nargin > 1
%     set(hf,'Position',figPos)
% end
% if nargin > 2
%     set(gca,'Position',axPos)
% end
% 
% end
