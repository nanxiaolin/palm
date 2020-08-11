function palmexport(object, event)
%
% function that exports the current active image into TIF files
% Added 03/25/2016
% Based on Tao's Palm2Tif function
%
% Xiaolin Nan, Oregon Health and Science University

    global params handles

    [path, basename, ext] = fileparts(params.fullname);

    % First, check if there are rendered images or windows open
    if handles.palmfig == -1 && isempty(params.palm_img)    % no image rendered yet
        msgbox('No image has been rendered yet. Please run RENDER first.');
        return;

    elseif handles.figfine == -1 
        % only regular resolution image present. 
        description = ' at regular resolution (10 nm/pixel).';
        exp_file = [params.pref_dir, basename, '_palm.tif'];

        %see if there are multiple frames present, and ask the user if desiring
        %to save single or multiple images

        if params.palm_frames == 1
            img = params.palm_img;
        else
            choice = questdlg('Would you like to save the current page or the whole stack?', 'Please choose an option ...', ...
                'Current Image', 'Whole Stack', 'Cancel', 'Whole Stack');

            switch choice
                case 'Current Image'
                    frame_num = uint32(get(params.palmslider, 'value'));
                    img = params.palm_img(:, :, frame_num);

                case 'Whole Stack'
                    img = params.palm_img;

                otherwise
                    return;
            end
        end

        % ask the user if 

        
    elseif handles.figfine ~= -1 && handles.palmfig ~= -1
        % both images are present. need to look into more scenarios
        
        choice = questdlg('Which image content to export?', 'Please choose an image to export ...', 'Regular', ...
            'High Res', 'Cancel', 'Regular');
        
        switch choice
            case 'Regular'
                if params.palm_frames > 1
                    choice2 = questdlg('Single image or stack (regular resolution)?', 'Please choose ...', 'Single', 'Stack', 'Cancel', 'Stack');
                    
                    switch choice2
                        case 'Single'
                            frame_num = uint32(get(handles.palmslider, 'value'));
                            img = params.palm_img(:, :, frame_num);
                        case 'Stack'
                            img = params.palm_img;
                        otherwise
                            return;
                    end
                else
                    img = params.palm_img;
                end
                
                description = ' at regular resolutoin (10 nm/pixel)';
                exp_file = [params.pref_dir, basename, '_palm.tif'];
                
            case 'High Res'
                if params.highres_frames > 1
                    choice2 = questdlg('Single image or stack (high resolution)?', 'Please choose ...', 'Single', 'Stack', 'Cancel', 'Stack');
                    
                    switch choice2
                        case 'Single'
                            frame_num = uint32(get(handles.palmfineslider, 'value'));
                            img = params.palm_img_highres(:, :, frame_num);
                        case 'Stack'
                            img = params.palm_img_highres;
                        otherwise
                            return;
                    end
                else
                    img = params.palm_img_highres;
                    
                end
                
                description = ' at high resolution (1 nm/pixel)';
                exp_file = [params.pref_dir, basename, '_palm_highres.tif'];
                
            otherwise
                return;
        end
    end

    % come up with basic descriptions
    description = ['PALM image of ', params.fullname, description];
    write2tif(img, description, exp_file);
end


function write2tif(img, description, dest)

    % add additional description to the file
    [~, username] = system('whoami');
    username = regexprep(username, '\r\n|\n|\r', '');
    description = sprintf('%s.\nFile generated %s by %s using palmexport.', description, datestr(now), username);

    % ask user to pick a file name
    [filename, filepath] = uiputfile('*.tif','Save PALM image as TIFF file',dest);

    if sum(filename)
        fullname = [filepath, filename];

        % see whether it is a single image or an image stack
        if ndims(img) == 2
            imwrite(uint16(img),fullname,'tif','Compression','none','Writemode','overwrite','Description',description);
        elseif ndims(img) == 3
            [~, ~, p] = size(img);
 
            % first image in overwrite mode to avoid adding to existing
            % files
            imwrite(uint16(img(:, :, 1)),fullname,'tif','Compression','none','Writemode','overwrite','Description',description);
            msg = sprintf('Writing image #1 of %d to file. Plese wait ...', p);
            dispmessage(msg);
            pause(0.01);
            
            for i = 2 : p
                imwrite(uint16(img(:, :, i)), fullname, 'tif', 'Compression','none','Writemode','append','Description',description);
                msg = sprintf('Writing image #%d of %d to file. Plese wait ...', i, p);
                dispmessage(msg);
                pause(0.01);
            end
        end
        msg = sprintf('Successfully written image to file %s', filename);
        dispmessage(msg);
    end
end