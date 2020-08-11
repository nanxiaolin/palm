function onfigstatsclosed(object, event)
%
% when stats window closed, reset the handles.figstats to -1
   global handles;

   %disp('Stats windows to be closed.');
   if(handles.figstats == -1) 
   	return;
   end
   
   delete(handles.figstats);
   handles.figstats = -1;


