function sl_plot_segment_tbd(cfg,SEGNAME,ext,varList)
%--------------------------------------------------------------------------
% function sl_plot_segment_tbd(cfg,ext(2:end),SEGNAME,varList)
% TODO:
%   Add 2 loops: time vs var, and time vs depth vs var for all vars
%   fix error with find_limits.m
%
% NIWA Slocum toolbox
%
% History:
% 2014          ANFOG   diagnostic_plot_tbd
% 2015-Sep-01   FE      Renamed, adapted for the NIWA Slocum toolbox
% sl_plot_segment_sbd
% 2017-Nov-02   FE      Big rewrite, new sensors added
%--------------------------------------------------------------------------


%% --- Set-up ---
disp([getUTC,': STARTING ',mfilename]);
DATA_DIR = fullfile(cfg.PROJECT_DIR,'ascii');
OUTPUT_DIR = fullfile(cfg.PROJECT_DIR,'segments',SEGNAME);
OUTPUT_DIR_CT_PROFILES = fullfile(cfg.PROJECT_DIR,'sci_transects','CT_profiles');
scienceFile  = fullfile(DATA_DIR,[SEGNAME '_' ext '.m']);
titleString = ['Segment: ' SEGNAME];
col = linspecer(3);
plotFiles = {};

% --- Load TBD data
run(scienceFile)
time = ut2mt(data(:,sci_m_present_time));

% --- Process Data
% CTD
pre     = data(:,sci_water_pressure)*10;                  % from [bar] to [dbar]
tem     = data(:,sci_water_temp);
con     = data(:,sci_water_cond);
% Calculate derived variables
dep     = sw_dpth(pre,cfg.DEPLOY_LAT);  
c3515   = sw_c3515*0.1;
sal     = real(sw_salt(con/c3515, tem, pre));
tem     = real(tem);
pden    = real(sw_pden(sal, tem, pre, 0.0) - 1000.0);     % Potential density
% Replace typically bad values
%tem(tem < 0.01) = NaN;
sal(sal < 0.01) = NaN;
pden(pden< 0.01) = NaN;
% Remove NaN's (use original var name if interpolating)
dep1 = dep(~isnan(tem));
sal1 = sal(~isnan(tem));
tem1 = tem(~isnan(tem));
% Use this for other sensors
depNoNan = dep(~isnan(dep));
timeDepNoNan = time(~isnan(dep));

% AADI DO
if exist('sci_oxy4_oxygen','var')
    oxy     = data(:,sci_oxy4_oxygen) ./ 31.25;           % convert from [mmol/L] to [mg/L];
    oxy(oxy < 0.01) = NaN;
    oxy1 = oxy(~isnan(oxy));
end

% BBFLCD
if exist('sci_flbbcd_chlor_units','var')
    chla = data(:,sci_flbbcd_chlor_units);
    cdom = data(:,sci_flbbcd_cdom_units);
    b650 = data(:,sci_flbbcd_bb_units);
    chla1 = chla(~isnan(chla));
    cdom1 = cdom(~isnan(cdom));
    b6501 = b650(~isnan(b650));
end

% BB3SL0
if exist('sci_bb3slo_b470_scaled','var')
    b470 = data(:,sci_bb3slo_b470_scaled);
    b532 = data(:,sci_bb3slo_b532_scaled);
    b660 = data(:,sci_bb3slo_b660_scaled);
    b4701 = b470(~isnan(b470));
    b5321 = b532(~isnan(b532));
    b6601 = b660(~isnan(b660));
end

% BSPAR
if exist('sci_bsipar_par','var')
    bspar = data(:,sci_bsipar_par);
    bspar1 = bspar(~isnan(bspar));
end

% --- Limits
dMin    = 0;
dMax    = ceil(max(dep)*1.1);
[tMin,tmax] = find_limits_test(tem);
[sMin,smax] = find_limits_test(sal);


%% Plot 1: Temperature and Salinity profiles
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
    [fh, ah] = plot_default('portrait',[SEGNAME '-CTD_profile']);
    set(ah,'YDir','reverse','XaxisLocation','top','XColor',col(1,:)); %,'XLim',[tMin,tmax]);
    
    hl1 = line(tem2,dep2,'Marker','.','Color',col(1,:),'MarkerSize',8,'Parent',ah);
    yl = get(ah,'ylim');
    set(ah,'ylim',[dMin yl(2)]);
    
    xlabel('Temperature (ITS-90, \circC)', 'FontSize', 10);
    ylabel('Depth (m)', 'FontSize', 11);
    title(['CTD Profile: ' SEGNAME], 'FontSize', 11, 'Interpreter', 'none','Fontweight','normal');
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
    
    print_fig([OUTPUT_DIR '\'])
    print_fig([OUTPUT_DIR_CT_PROFILES '\'])
    plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
    close(fh);
catch
    disp([getUTC,': ERROR: can''t execute Plot 2: Salinity vs Temperature (TS) Scatter']);
    close(fh);
end

%% Plot 2: Salinity vs Temperature (TS) Scatter
% Salinity v Temperature v Depth
try
    [fh, ah] = plot_default('square',[SEGNAME '-CTD_scatter']);
    set(ah,'XLim', [floor(min(sal)*10)/10 ceil(max(sal)*10)/10],'YLim', [floor(min(tem)*10)/10 ceil(max(tem)*10)/10])
    hold on;
    
    if cfg.SHOW_PLOTS == 0
        set(fh,'visible', 'off');
    end
    
    h = scatter(sal,tem,4,dep,'fill','SizeData',14,'Marker','o');
    
    grid on; box on;
    xlabel('Salinity (PSS-78, PSU)','FontSize',10,'Fontname','Calibri');
    ylabel('Temperature (ITS-90, \circC)', 'FontSize', 10);
    
    th = title(['CTD scatter plot: ' SEGNAME],'Interpreter','none',...
        'FontSize',11,'Fontname','Calibri','Unit','cen','Fontweight','normal');
%     set(th,'Position',get(th,'Position')+[0 0.5 0])
    
    cb1 = colorbar;
    set(cb1,'FontSize',10,'Fontname','Calibri');
    ylabel(cb1, 'Depth (m)');
    set(get(cb1,'Title'),'String','','FontSize',10,'Fontname','Calibri');
    
    print_fig([OUTPUT_DIR '\'])
    plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
    close(fh);
catch
    disp([getUTC,': ERROR: can''t execute Plot 2: Salinity vs Temperature (TS) Scatter']);
    close(fh);
end


%% Plot 3: Salinity vs Temperature vs Density Scatter
try
    %[denMin,denmax] = find_limits(density,98,0.1);
    [fh, ah] = plot_default('square',[SEGNAME '-density_scatter']);
    set(ah,'XLim', [floor(min(sal)*10)/10 ceil(max(sal)*10)/10],'YLim', [floor(min(tem)*10)/10 ceil(max(tem)*10)/10])
    hold on;
    
    if cfg.SHOW_PLOTS == 0
        set(fh,'visible', 'off');
    end
    
    scatter(sal,tem,4,pden,'fill','SizeData',14,'Marker','o');
    
    grid on; box on;
    xlabel('Salinity (PSS-78, PSU)','FontSize',10,'Fontname','Calibri');
    ylabel('Temperature (ITS-90, \circC)', 'FontSize', 10);
    
    th = title(['Density scatter plot: ' SEGNAME],'Interpreter','none',...
        'FontSize',11,'Fontname','Calibri','Unit','cen','FontWeight','normal');
%     set(th,'Position',get(th,'Position')+[0 0.5 0])
    
    cb1 = colorbar;
    set(cb1,'FontSize',10,'Fontname','Calibri');
    ylabel(cb1, 'Potential density (kgm^-^3)');
    set(get(cb1,'Title'),'String','','FontSize',10,'Fontname','Calibri');
    
    print_fig([OUTPUT_DIR '\'])
    plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
    close(fh);
catch
    disp([getUTC,': ERROR: can''t execute Plot 3: Salinity vs Temperature vs Density Scatter']);
end


%% Plot 4: WETLABS BBFL2S plots
try
    if exist('sci_flbbcd_chlor_units','var')
        
        % Interpolate dep values to chla
        timeChla = time(~isnan(chla));
        dep4chla = interp1(timeDepNoNan,depNoNan,timeChla); 
        
        inflection_points = find(abs(diff(dep4chla)) > (dMax-dMin)*.5);
        chla2 = chla1; cdom2 = cdom1; b6502 = b6501;
        % insert NaN at inflection points in dep1 , tem1, sal1
        for i = 1:numel(inflection_points)
            num = inflection_points(i);
            dep4chla = [dep4chla(1:num); NaN; dep4chla(num+1:end)];
            chla2 = [chla2(1:num); NaN; chla2(num+1:end)];
            cdom2 = [cdom2(1:num); NaN; cdom2(num+1:end)];
            b6502 = [b6502(1:num); NaN; b6502(num+1:end)];
            inflection_points = inflection_points +1;
            % disp(['length of dep1 is ' num2str(numel(dep1))])
        end
        
        [fh, ah] = plot_default('portrait',[SEGNAME '-BBFLCD_profile']);
        set(ah,'YDir','reverse')
        hold on;
        
        if cfg.SHOW_PLOTS == 0
            set(fh,'visible', 'off');
        end
        
        hl1 = line( chla2, dep4chla, 'Marker', '.', 'Col', col(1,:), 'MarkerSize', 8);
        hl1 = line( cdom2, dep4chla, 'Marker', '.', 'Col', col(2,:), 'MarkerSize', 8);
        hl1 = line( b6502*1000, dep4chla, 'Marker', '.', 'Col', col(3,:), 'MarkerSize', 8);
        set(ah,'ylim',[dMin dMax]);
        
        xlabel(  'Wetlabs BBFLCD');
        ylabel( 'Depth (m)');
        th = title(['BBFLCD Profile: ' SEGNAME],'interpreter','none',...
            'Fontweight','normal','Fontsize',11);

        legend('Chl [ug/L]', 'CDOM [ppb]', 'b650 [m^-^1sr^-^1] x 1000','location','best');
        
        print_fig([OUTPUT_DIR '\'])
        plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
        close(fh);
    end
catch
    disp([getUTC,': ERROR: can''t execute Plot 4: WETLABS BBFL2S plots']);
    close(fh);
end


%% Plot 5: Sensor profiles (PROFILE)
% Loop through all avaialble sensors and plot profiles
% let just plot everything provided except time
for i = 1:size(varList,1)
    if ~(strcmp(varList{i,1},'sci_m_present_secs_into_mission') || strcmp(varList{i,1},'sci_m_present_time'))
        
        try
            name = varList{i,1};
            disp(name)
            
            switch name
                case 'sci_bb3slo_b470_scaled'
                    label = '[1/m.sr] x 1000';
                    thisData = b470*1000;
                case 'sci_bb3slo_b532_scaled'
                    label = '[1/m.sr] x 1000';
                    thisData = b532*1000;
                case 'sci_bb3slo_b660_scaled'
                    label = '[1/m.sr] x 1000';
                    thisData = b660*1000;
                case 'sci_flbbcd_bb_units'
                    label = '[1/m.sr] x 1000';
                    thisData = b650*1000;
                case 'sci_flbbcd_cdom_units'
                    label = '[ppb]';
                    thisData = cdom;
                case 'sci_flbbcd_chlor_units'
                    label = '[ug/L]';
                    thisData = chla;
                case 'sci_bsipar_par'
                    label = '[ue/m^2sec]';
                    thisData = bspar;
                case 'sci_oxy4_oxygen'
                    label = '[mg/l]';
                    thisData = oxy;
                    name = 'dissolved_oxygen';
                case 'sci_water_cond'
                    label = '[PSS-78, PSU]';
                    thisData = sal;
                    name = 'salinity';
                case 'sci_water_temp'
                    label = '[ITS-90, \circC]';
                    thisData = tem;
                case 'sci_water_pressure'
                    label = '[dBar]';
                    thisData = pre;
                otherwise
                    label =  varList{i,2};
                    thisData = data(:,i);
            end
            
            % Interpolate dep values to thisData
            timeThisData = time(~isnan(thisData));
            dep4ThisData = interp1(timeDepNoNan,depNoNan,timeThisData);
            
            % Remove NaN's
            thisData = thisData(~isnan(thisData));
            
            inflection_points = find(abs(diff(dep4ThisData)) > (dMax-dMin)*.5);
            % insert NaN at inflection points in dep1 , tem1, sal1
            for ind = 1:numel(inflection_points)
                num = inflection_points(ind);
                dep4ThisData = [dep4ThisData(1:num); NaN; dep4ThisData(num+1:end)];
                thisData = [thisData(1:num); NaN; thisData(num+1:end)];
                inflection_points = inflection_points +1;
                %     disp(['length of dep1 is ' num2str(numel(dep1))])
            end
            
            [fh, ah] = plot_default('portrait',[SEGNAME '-profile-' name]);
            set(ah,'YDir','reverse')
            hold on;
            
            if cfg.SHOW_PLOTS == 0
                set(fh,'visible', 'off');
            end
            
            hl1 = plot( thisData, dep4ThisData,'Marker','.','MarkerSize',8,'Col', col(1,:));
            set(ah,'ylim',[dMin dMax]);
            
            xlabel(label);
            ylabel( 'Depth (m)');
            th = title([name ': ' SEGNAME],'interpreter','none','Fontweight','normal',...
            'Fontsize',11);
            
            print_fig([OUTPUT_DIR '\'])
            plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
            close(fh);
            
        catch
            disp([getUTC,': ERROR: can''t execute Plot 5: ' name ' profile'])
        end
    end
end


%% Plot 6: Time vs Variable (TIME)
for i = 1:size(varList,1)
    if ~(strcmp(varList{i,1},'sci_m_present_secs_into_mission') || strcmp(varList{i,1},'sci_m_present_time'))
        name = varList{i,1};
        switch name
            case 'sci_bb3slo_b470_scaled'
                label = '[1/m.sr] x 1000';
                thisData = b470*1000;
            case 'sci_bb3slo_b532_scaled'
                label = '[1/m.sr] x 1000';
                thisData = b532*1000;
            case 'sci_bb3slo_b660_scaled'
               label = '[1/m.sr] x 1000';
                thisData = b660*1000;
            case 'sci_flbbcd_bb_units'
                label = '[1/m.sr] x 1000';
                thisData = b650*1000;
            case 'sci_flbbcd_cdom_units'
                label = '[ppb]';
                thisData = cdom;
            case 'sci_flbbcd_chlor_units'
                label = '[ug/L]';
                thisData = chla;
            case 'sci_bsipar_par'
                label = '[ue/m^2sec]';
                thisData = bspar;
            case 'sci_oxy4_oxygen'
                label = '[mg/l]';
                thisData = oxy;
                name = 'dissolved_oxygen';
            case 'sci_water_cond'
                label = '[PSS-78, PSU]';
                thisData = sal;
                name = 'salinity';
            case 'sci_water_temp'
                label = '[ITS-90, \circC]';
                thisData = tem;
            case 'sci_water_pressure'
                label = '[dBar]';
                thisData = pre;
            otherwise
                label =  varList{i,2};
                thisData = data(:,i);
        end     
        
        % Plot
        [fh, ah] = plot_default('landscape',[SEGNAME '-time-' name]);
        
        if cfg.SHOW_PLOTS == 0
            set(fh,'visible', 'off');
        end
        
        plot(time, thisData, 'Marker', '.', 'Col', col(1,:), 'MarkerSize', 8, 'LineStyle', 'none');
        xtimelab(ah)
        ylabel(label);
        th = title([name ': ' SEGNAME],'interpreter','none','Fontweight','normal',...
            'Fontsize',11);
        set(ah,'XGrid','on','YGrid','on','box','on');
        
        print_fig([OUTPUT_DIR '\'])
        plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
        close(fh);
        
    end
end


%% Plot 7: Time vs Depth vs Variable (CONTOUR)
for i = 1:size(varList,1)
    if ~(strcmp(varList{i,1},'sci_m_present_secs_into_mission') || strcmp(varList{i,1},'sci_m_present_time'))
        name = varList{i,1};
        switch name
          
            case 'sci_bb3slo_b470_scaled'
                label = '[1/m.sr] x 1000';
                thisData = b470*1000;
            case 'sci_bb3slo_b532_scaled'
                label = '[1/m.sr] x 1000';
                thisData = b532*1000;
            case 'sci_bb3slo_b660_scaled'
                label = '[1/m.sr] x 1000';
                thisData = b660*1000;
            case 'sci_flbbcd_bb_units'
                label = '[1/m.sr] x 1000';
                thisData = b650*1000;
            case 'sci_flbbcd_cdom_units'
                label = '[ppb]';
                thisData = cdom;
            case 'sci_flbbcd_chlor_units'
                label = '[ug/L]';
                thisData = chla;
            case 'sci_bsipar_par'
                label = '[ue/m^2sec]';
                thisData = bspar;
            case 'sci_oxy4_oxygen'
                label = '[mg/l]';
                thisData = oxy;
                name = 'dissolved_oxygen';
            case 'sci_water_cond'
                label = '[PSS-78, PSU]';
                thisData = sal;
                name = 'salinity';
            case 'sci_water_temp'
                label = '[ITS-90, \circC]';
                thisData = tem;
            case 'sci_water_pressure'
                label = '[dBar]';
                thisData = pre;
            otherwise
                label =  varList{i,2};
                thisData = data(:,i);
        end
        
        % Interpolate depth values to current variable
        time4ThisData = time(~isnan(thisData));
        dep4ThisData = interp1(timeDepNoNan,depNoNan,time4ThisData);
        
        % And finally, plot
        [fh, ah] = plot_default('landscape',[SEGNAME '-contour-' name]);
        set(ah,'Ydir','Reverse');
        hold on;
        
        if cfg.SHOW_PLOTS == 0
            set(fh,'visible', 'off');
        end
        
        scatter(time(~isnan(thisData)),dep4ThisData,4,thisData(~isnan(thisData)),'fill','SizeData',12,'Marker','o');
        xtimelab(ah)
        ylim = get(gca,'ylim');
        set(gca,'Ylim',[0 ylim(2)])
        ylabel('Depth (m)','interpreter','none');
        title([name ': ' SEGNAME],'interpreter','none','Fontweight','normal',...
            'Fontsize',11);

        % Colorbar
        cb1 = colorbar;
        set(cb1,'FontSize',10,'Fontname','Calibri');
        ylabel(cb1, label);
        
        print_fig([OUTPUT_DIR '\'])
        plotFiles{numel(plotFiles)+1} = [get(fh,'Tag') '.png'];
        close(fh);
    end
end


%% Send files to sci_transects
for k = 1:numel(plotFiles)
    newName = ['LastSegment-' plotFiles{k}(length(SEGNAME)+2:end)];
    copyfile(fullfile(OUTPUT_DIR,plotFiles{k}),fullfile(cfg.PROJECT_DIR,'sci_transects',newName));
end
disp([getUTC,': Sent new science segment plots to sci_transects']);

disp([getUTC,': FINISHED ',mfilename]);
