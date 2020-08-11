function palm2tif()
% save PALM image as 16bit .tif file
% generated by tao 20131006
% based on palm.m

global params handles

if gcf == handles.palmfig
    palm_img = params.palm_img;
    disp('Converting regular PALM image to TIF.');
elseif gcf == handles.figfine
    palm_img = params.palm_img_highres;
    disp('Converting high resolution PALM image to TIF. ');
end

[disp_low disp_high] = autoscale2d(palm_img);
disp_low = fix(disp_low);
disp_high = ceil(disp_high);
description = sprintf('min=%1.1f\nmax=%1.1f',disp_low,disp_high);
if isstruct(params)
    [filename, filepath] = uiputfile('*.tif','Save PALM image as TIFF file',[params.pref_dir, 'palm.tif']);
    if sum(filename)
        filename = [filepath, filename];
        imwrite(uint16(palm_img),filename,'tif','Compression','none','Writemode','overwrite','Description',description);
    end
else
    msgbox('No data found. Please run PALM.m first.');
end