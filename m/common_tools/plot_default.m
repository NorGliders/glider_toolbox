function [fh, ah] = plot_default(type,tag)
%--------------------------------------------------------------------------
% [fh, ah] = plot_default_testing(mkfig,type)
%
% Default configuration of plots for real-time display
%
% NIWA Slocum toolbox
%
% History:
% 2017-Jun-28   FE      Made stand alone function to be used by entire toolbox
% 2017-Nov-02   FE      Rewritten
%--------------------------------------------------------------------------

if nargin == 0
    % If type not specified default plot type is landscape
    type = 'surface';
else
    % If type not recognized default plot type is landscape
    if ~ismember(type,{'landscape','square','portrait','squareText','battery','power','surface','tracks','yaxis2','battery_diagnostics'})
        type = 'landscape';
    end
end



% Figure and axis dimensions
switch type   
    case 'landscape'
        figPos  = [2 2 17 10];
        axPos   = [2 1.5 13 7.5];
    case 'square'
        figPos  = [2 2 15 15];
        axPos   = [1.5 1.5 12.2 12.2];
    case 'portrait'
        figPos  = [2 2 10 16];
        axPos   = [1.7 1.5 7.5 12.5];
    case 'squareText'
        figPos  = [2 2 15 17.8];
        axPos   = [1.5 4.5 12.2 12.2];
    case 'battery'
        figPos  = [2 2 13.5 11];
        axPos   = [1.5 4 11 6];
    case 'power'
        figPos  = [2 2 13.5 9];
        axPos   = [1.5 3 11 5];
    case 'surface'
        figPos  = [2 2 16 6.5];
        axPos   = [1.5 1.5 13 4.0];
    case 'tracks'
        figPos  = [2 2 15 15];
        axPos   = [1.5 1.5 12.2 12.2];
    case 'yaxis2'
        figPos  = [2 2 17 10];
        axPos   = [2 1.5 13 7.5];
    case 'battery_diagnostics'
        figPos  = [2 1 20 20];
        axPos(1,:)   = [1.5 13 8 5];
        axPos(2,:)   = [11 13 8 5];
        axPos(3,:)   = [1.5 6 8 5];
        axPos(4,:)   = [11 6 8 5];
end

[m,~] = size(axPos);
fh = figure('Visible','on','Units','Centimeters','NumberTitle','off','color','white');
set(fh,'Position',figPos,'Units','cen');
ah = zeros(1,m);

if strcmp(type, 'yaxis2')
    ah(1) = axes('Parent',fh,'Units','Centimeters','FontSize',9,'FontName','Calibri','Color','#f0f0f0','GridColor','#cccccc');
    set(ah(1),'Position',axPos(1,:),'Units','cen');
    ah(2) = axes('Units','cen','fontsize',9, 'FontName','Calibri','Position',axPos,'Color','none','XAxisLocation','top','YAxisLocation','right');
else
    for i = 1:m
        ah(i) = subplot(2,2,i,'Parent',fh,'Units','Centimeters','FontSize',9,'FontName','Calibri',...
            'XGrid','on','YGrid','on','box','on','Color','#f0f0f0');
        set(ah(i), 'pos', axPos(i,:) )
        hold on 
    end
end

% Convert the XAxis type to an instance of the DatetimeRuler
if strcmp(type, 'surface')
    set(ah, 'XAxis', matlab.graphics.axis.decorator.DatetimeRuler);
end

% Text positioning
x = 0;
switch type   
    case 'squareText'
        y = -4.2;
    case 'battery'
        y = -3.5;
    case 'power'
        y = -2.7;
    case 'surface'
        y = -1.1;
    case 'battery_diagnostics'
        y = -5;
        x = -10;
    otherwise
        y = -1.3;     
end

hTxt = text(x,y,['Figure created ',datestr(posixtime2utc(posixtime()), 'dd-mmm-yyyy HH:MM:SS'), 'Z'],...
    'Units','cen',...
    'Fontsize',7,...
    'FontName','Calibri');
hold on
if nargin == 2
    set(fh,'Tag',tag, 'Name', tag);
end


