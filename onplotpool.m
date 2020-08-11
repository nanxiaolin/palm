function onplotpool(object, event)
%
% function onplotpool: plot pooled ripley's k curves
%
% switching action depending on the object value
% 

	global h_palmpanel handles params results;

	%userdata = get(h_palmpanel, 'userdata');
	
	switch(object)
		case handles.cah.btnpoolplotrpk
		    if(results.ktests.num == 0)
    			dispmessage('No curves in the pool.');
  				return;
    		end
	
			showpooled = get(handles.cah.chkshowpooledrpk, 'value');
	
			[r c] = size(results.ktests.rpcs);
			steps = results.ktests.steps;
			msteps = max(steps);
	
			h = figure('Visible', 'off');

			% format figure for convenience of publication	
			pos = get(h, 'Position');
			pos(3) = 560;	pos(4) = 340;		
	
			if(showpooled)
				rpc = results.ktests.rpcs;
				rpc_err = 0;
				plot(steps, rpc, '-', 'LineWidth', 2); axis tight; grid on;
				%hold on; plot(steps, rpc2, 'g-');		
			else
				rpc = mean(results.ktests.rpcs, 2);
				% calculate the error bar (standard error of the mean)
				% FLAG == 0 (2nd parameter) using default normalization
				rpc_err = std(results.ktests.rpcs, 0, 2) / sqrt(c);   
				%whos
				errorbar(steps, rpc, rpc_err); axis tight; grid on;
		
				% redraw the average line
				hold on; plot(steps, rpc, '-', 'LineWidth', 2);
			end

			% draw a red line at 0 horizontal
			zline = zeros(1, r);
			hold on; plot(steps, zline, 'r--', 'LineWidth', 2);

			xlim([-0.25 msteps]);
			%if(max(max(rpc)) < 2.4)
			%	ylim([min(min(rpc - rpc_err))-0.5 3]);
			%else
			ylim([-0.5 1.25]);
			%end
			xlabel('r (nm)');
			ylabel('Normalized L(r) - r'); %ylim([-0.3 1.1]);
			%set(h, 'Color', [1 1 1], 'Position', pos, 'Name', 'Pooled Ripley K-Test', 'NumberTitle', 'off', 'Visible', 'on');
			set(h,'name', 'Pooled Ripley K-Test', 'visible', 'on');
	
			if(showpooled)
				titlestr = sprintf('K-Tests from n = %d sample areas', c);
			else
				titlestr = sprintf('K-Tests from n = %d sample areas (Averaged)', c);
			end
		
			title(titlestr);
			
		case handles.cah.btnpoolplotfcv
		    if(results.fcv.num == 0)
    			dispmessage('No results in the pool.');
  				return;
    		end
			
			% normalize the histograms
			tp = sum(results.fcv.sizes, 2);
			sizes = results.fcv.sizes;
			
			for m=1:results.fcv.num
				sizes(m, :) = sizes(m, :) / tp(m);
			end

			cs = mean(sizes, 1);
			cs_err = std(sizes, 0, 1) / sqrt(results.fcv.num);
			
			% show the results in the message bar
			message = ['Size = [' num2str(cs*100, '%.1f ') '] Err=[' num2str(cs_err*100, '%.1f ') ']'];
			dispmessage(message);
			
			figure;  bar(1:length(cs), cs, 'g');
			hold on; errorbar(1:length(cs), cs, cs_err, '.b'); 
			axis tight; grid on;
			xlim([0.4 10.6]);
			ylim([min(min(cs - cs_err)) max(max(cs + cs_err))*1.25]);
			xlabel('Cluster Size (# of Molecules)'); ylabel('Fraction of Molecules in Clusters');
			
			titlestr = sprintf('Average cluster size distribution of %d sample areas.', results.fcv.num);
			title(titlestr, 'FontWeight', 'bold');
	end

