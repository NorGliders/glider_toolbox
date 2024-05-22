function print_fig(out_dir)

if nargin == 0
    out_dir = pwd;
end

img = getframe(gcf);
imwrite(img.cdata, fullfile(out_dir,[get(gcf,'Tag') '.png']));
%disp([getUTC ': Saving ' fullfile(out_dir,[get(gcf,'Tag') '.png'])])