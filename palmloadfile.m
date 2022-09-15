function palmloadfile(object, event)
%
% palmloadfile: file loading routine
% 
% if event == 0, object is the filename
% this allows a direct call to palmloadfile
%
% update 02/09/2020: use a container variable (s) to load the cor files
% such that s can be cleared after loading and that variables from previous
% files do not affect the new file.
% revisions also include the conversion of old .fiducials format into the
% new one to allow more flexible drift corrections.

	global h_palmpanel proc handles params;

    if event == 0
        fullname = object;
        [pathname filename ext] = fileparts(fullname);
        
    else
        pref_dir = params.pref_dir;
        extension = {'*.cor', 'Unsorted Coordinate File (*.COR)'};
        [filename pathname] = uigetfile(extension, 'Select a file to open', pref_dir);

        if filename == 0
            return;
        end
        
        [path name ext] = fileparts(filename);
        fullname = fullfile(pathname, filename);
    end

	%fullname = '/home/xiaolin/Data/2009.03.17/BHK21_PSCFP2Tub_2.cor';
    
    dispmessage(sprintf('Loading file %s ...', filename));
    pause(0.02);
	
	params.fullname = fullname;			% this has to be before file loading
    s = load(fullname, '-MAT');				% this will create a few matrices including 'fullname' (that refers to original data file)
	params.filename = filename;
	params.pref_dir = pathname;

	% record a few other parameters
	params.frames = s.coords(1, 5);
	set(handles.dispframes, 'String', sprintf('%d', params.frames));
    set(handles.startframe, 'String', sprintf('%d', 1));
    set(handles.endframe, 'String', sprintf('%d', params.frames));

    
	params.width  = s.coords(1, 3) - s.coords(1, 1) + 1;
	params.height = s.coords(1, 4) - s.coords(1, 2) + 1;
	params.xoff   = s.coords(1, 1);
	params.yoff   = s.coords(1, 2);
    
    [r c] = size(s.coords);
    params.coords = s.coords(2:r, :);

    % correct for the starting frame. this change will not be committed to
    % the raw data.
    params.coords(:, 1) = params.coords(:, 1) - min(params.coords(:, 1)) + 1;
    
    % check the format of the fiducials. If it is the old format, convert
    % it into the new format
    if ~isfield(s.fiducials, 'total')
        %disp('Old fiducials format');
        
        % when there is no fiducials defined
        if isempty(s.fiducials)
            params.fiducials.total = 0;
            params.fiducials.picked = [];
            params.fiducials.applied = 0;
            params.fiducials.pids = [];
            params.fiducials.coords = [];
            
            % the x and y drift fields are set as 0s
            params.drift.x = zeros(1, params.frames);
            params.drift.y = zeros(1, params.frames);
            
            fiducials = params.fiducials;
            drift = params.drift;
            
            % modify the cor file to the current format (with empty drift
            % and fiducials fields
            save(params.fullname, 'fiducials', 'drift', '-APPEND');
        else
            % start the conversion
            x_ave = mean(s.fiducials(:, :, 1), 1);
            y_ave = mean(s.fiducials(:, :, 2), 1);

            % center the drift trajectories around 0
            x_drift = medfilt1(x_ave - mean(x_ave), 2)';
            y_drift = medfilt1(y_ave - mean(y_ave), 2)';

            x_raw = params.coords(:, 2);
            y_raw = params.coords(:, 3);
            f_num = params.coords(:, 1);
            idx = 1 : length(x_raw);
            
            x_raw(idx) = x_raw(idx) + x_drift(f_num(idx));
            y_raw(idx) = y_raw(idx) + y_drift(f_num(idx));

            % update the raw coordinates to before drift correction
            params.coords(:, 2) = x_raw;
            params.coords(:, 3) = y_raw;

            % populate the .fiducials field
            params.fiducials.total = size(s.fiducials, 1);
            params.fiducials.picked = ones(params.fiducials.total, 1);
            params.fiducials.applied = 1;
            % set the type of fiducials (pids) to 0, meaning pre-defined (not
            % removable or repalceable
            params.fiducials.pids = zeros(params.fiducials.total, 1);   
            params.fiducials.coords = s.fiducials;
            params.drift.x = x_drift';
            params.drift.y = y_drift';

            % save the converted coords, drift, and fiducials fields
            coords = s.coords;
            %whos
            coords(idx+1, 2) = x_raw;
            coords(idx+1, 3) = y_raw;
            fiducials = params.fiducials;
            drift = params.drift;

            save(params.fullname, 'coords', 'fiducials', 'drift', '-APPEND');
            dispmessage('Old fiducials converted into new format and saved to file.');
            clear coords x_raw y_raw x_ave y_ave f_num idx
        end
    else
        params.fiducials = s.fiducials;
        
        % if no .drift field (old format), then convert the fiducials format
        % to the new one
        if ~isfield(s, 'drift')
            params.drift.x = zeros(1, params.frames);
            params.drift.y = zeros(1, params.frames);
        else 
            params.drift = s.drift;
        end        
    end

	% see if the coordinates have been sorted
	if isfield(s, 'scf') && isfield(s, 'sort_order')
        if ~isempty(s.scf)
            params.is_sorted = 1;
            params.scf = s.scf;
            params.sort_order = s.sort_order;
            params.sortpars = s.sortpars;
            sort_nps = length(params.scf(:, 1));
            set(handles.dispsorted, 'String', sprintf('%d', sort_nps));
            set(handles.palmstats, 'enable', 'on');
            set(handles.renderpalm, 'enable', 'on');	
            set(handles.moviemode, 'enable', 'on', 'value', 0);
            set(handles.movieframe, 'enable', 'off');
            params.moviemode = 0;
            set(handles.timecumulative, 'enable', 'off', 'value', 0);
            set(handles.driftcorr, 'enable', 'on');
        else
            params.is_sorted = 0;
            params.scf = [];
            set(handles.renderpalm, 'enable', 'off');
            set(handles.dispsorted, 'String', 'n/a');
            set(handles.palmstats, 'enable', 'off');
            set(handles.moviemode, 'enable', 'off');
            set(handles.movieframe, 'enable', 'off');
            set(handles.timecumulative, 'enable', 'off', 'value', 0);
            set(handles.driftcorr, 'enable', 'on');            
        end
	else
		params.is_sorted = 0;
		params.scf = [];
		set(handles.renderpalm, 'enable', 'off');
		set(handles.dispsorted, 'String', 'n/a');
		set(handles.palmstats, 'enable', 'off');
        set(handles.moviemode, 'enable', 'off');
        set(handles.movieframe, 'enable', 'off');
        set(handles.timecumulative, 'enable', 'off', 'value', 0);
        set(handles.driftcorr, 'enable', 'on');
    end

	% frames, particle finding, and gaussian fitting
	raw_nps = length(params.coords(:, 1));
	set(handles.dispraw, 'String', sprintf('%d', raw_nps));
	
	if isfield(s, 'pf_method')	% particle finding method
		set(handles.disppf, 'String', s.pf_method);
	else
		set(handles.disppf, 'String', 'SIT');
	end

	if isfield(s,'gf_method') % gaussian fitting method
		set(handles.dispfit, 'String', s.gf_method);
	else
		set(handles.dispfit, 'String', 'LSF');
	end
	
	% populate the 'sorted' structure variables
	if isfield(s, 'sortpars')
		set(handles.pixelsize, 'String', sprintf('%d', s.sortpars.pixelsize));
		set(handles.comdist, 'String', sprintf('%.1f', s.sortpars.pdist));
		set(handles.thresh, 'String', sprintf('%.1f', s.sortpars.rms));
		set(handles.comframes, 'String', sprintf('%d', s.sortpars.preturn));
		set(handles.mingood, 'String', sprintf('%.2f', s.sortpars.goodness));
		set(handles.maxeccen, 'String', sprintf('%.1f', s.sortpars.eccentric));
	%else  % set the parameters to default
	%	set(handles.pixelsize, 'String', '140');
	%	set(handles.comdist, 'String', '140');
	%	set(handles.thresh, 'String', '4');
	%	set(handles.comframes, 'String', '15');
	%	set(handles.mingood, 'String', '0.25');
	%	set(handles.maxeccen, 'String', '1.6');
	end

	set(handles.palmsort, 'enable', 'on');
	set(handles.lowres, 'enable', 'off');
	set(handles.palmexport, 'enable', 'off');
	set(handles.rawstats, 'enable', 'on');
    set(handles.joincorfiles, 'enable', 'on');
	
	% enable or disable analysis tool buttons
	set(handles.pointtrack, 'enable', 'off');
	%set(handles.cluster, 'enable', 'off');
	
	% close off windows that associates with previous file
	onfigstatsclosed(0, 0);
	onfigfineclosed(0, 0);
	onfigpalmclosed(0, 0);
    onfigdriftclosed(0, 0);
	
	% initialize status variables
	proc.fileopen = 1;
	
	% stop other processes if they are running
	if proc.cluster == 1
		stopcluster;
	end
	
	tmsg = sprintf('PALM File: %s ', filename);
	set(h_palmpanel, 'name', tmsg);
	showsumimage;
	dispmessage(sprintf('Loading file %s ... Done.', filename));
	
	% all the variables stored; clear variables
	clear;	
    %whos
    %whos global
end


