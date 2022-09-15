function joincorfiles ( object, event )
%
% function to concatenate two .cor files

	global h_palmpanel proc handles params;
    
    if isempty(params.filename)
        dispmessage('No .cor file loaded. Open a file first.');
        return;
    end
    
    extension = {'*.cor', 'Unsorted Coordinate File (*.COR)'};
    [new_filename, new_pathname] = uigetfile(extension, 'Select a .cor file to join', params.pref_dir);

    if new_filename == 0
        dispmessage('Canceled by user.');
        return;
    end
    
    % check file extension
    [path name ext] = fileparts(new_filename);
    if strcmpi(ext, '.cor') == false
        dispmessage('File to be joined does not appear to be the right file type.');
        return;
    end
    
    % now load the new .cor file
    fullname = [new_pathname new_filename];
    new_data = load(fullname, '-MAT');
    
    % check to see if the data is adequate and match the existing file
    
    if isfield(new_data, 'coords') == false
        dispmessage('New file does not have coordinates.');
        clear new_data;
        return;
    end
   
    % decode the new data
    frames = new_data.coords(1, 5);
    width  = new_data.coords(1, 3) - new_data.coords(1, 1) + 1;
	height = new_data.coords(1, 4) - new_data.coords(1, 2) + 1;
	xoff   = new_data.coords(1, 1);
	yoff   = new_data.coords(1, 2);
	%coords = new_data.coords(2:r, :);
    
    % check the consistency between the two datasets
    if width ~= params.width || height ~= params.height
        msgbox('New file has a different dimension. Cannot join the two files.', 'Cannot join files');
        clear new_data;
        return;
    end
    
    if xoff ~= params.xoff || yoff ~= params.yoff
        msgbox('New file has a different offset (xoff, yoff). Cannot join the two files.', 'Cannot join files');
        clear new_data;
        return;
    end
    
    % ready to join the two files
    [save_filename, save_pathname] = uiputfile(extension, 'Save the joined file as ...', params.pref_dir);
    [r c] = size(params.coords);
    [r_new c_new] = size(new_data.coords);   
    
    if save_filename == 0
        dispmessage('File joining canceled by user.');
        clear new_data;
        return;
    else
        msg1 = 'The following two files will be joined: ';
        msg2 = sprintf('[Current]: %s (%d frames, %d particles)', params.filename, params.frames, r);
        msg3 = sprintf('[To Join]: %s (%d frames, %d particles)', new_filename, frames, r_new-1);
        msg4 = sprintf('and saved as: %s', save_filename);
        msg5 = '';
        msg6 = 'Note: All sorting results and fiducials will be lost!!!';
        
        choice = questdlg({msg1, msg2, msg3, msg4, msg5, msg6, msg5}, ...
                                'Confirm file joining');
        switch choice
            case 'No'
            case 'Cancel'
                dispmessage('File joining canceled by user.');
                clear new_data;
                return;
        end
    end
    
    save_fullname = [save_pathname save_filename];
    
    % append the new data to the existing data

    if c < c_new     % in case one array is an extended version
        c_save = c_new;
    else
        c_save = c;
    end
    r_save = r + r_new;
    
    coords = zeros(r_save, c_save);
    coords(1, :) = new_data.coords(1, :);
    coords(1, 5) = params.frames + frames;
    coords(2:r+1, 1:c) = params.coords(1:r, 1:c);
    coords(r+2:r_save, 1:c_new) = new_data.coords(2:r_new, 1:c_new);
  
    % save the data
    dispmessage('Saving the joint file ... '); 
    pause(0.01);
    save(save_fullname, 'coords', '-MAT');
    
    if isfield(new_data, 'pf_method')
        pf_method = new_data.pf_method;
    end
    
    if isfield(new_data, 'gf_method')
        gf_method = new_data.gf_method;
    end
    
    fiducials = [];
    
    save(save_fullname, 'pf_method', 'gf_method', 'save_fullname', 'fiducials', '-MAT', '-APPEND');
    dispmessage(['Completed saving the joint file as ' save_filename '.']);
    
    clear new_data coords
    % now the new_data.coords contains coords from both data files. 
    % strip the other fields and save the data as unsorted .cor file.
    
    % ask user if the new file should be loaded
    msg1 = 'Would you like to open the joint file?';
    choice = questdlg(msg1, 'Joint file saved to disk.');
    
    switch choice
        case 'Yes'
            palmloadfile(save_fullname, 0);
    end
 
end

