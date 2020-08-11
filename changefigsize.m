function changefigsize(width, height)
%
% function changefigsize(width, height)
% function that changes the size of current figure
% 	when there is no input the function displays current figure size
	
	handle = gcf;
	pos = get(handle, 'position');

	if nargin == 0 	% show current figure size
		mesg = sprintf('Current figure window size: width = %d, height = %d', pos(3), pos(4));
		disp(mesg);
	else
		pos(3) = width;
		pos(4) = height;
		set(handle, 'position', pos);
	end



