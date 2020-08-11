function findfiducials(object, event)
%
% function that automatically finds fiducial markers based on the coordinates
%
% basic steps for automated fiduciary finding are as follows
% 1. perform a special sorting using the raw coordinates (palmsort(0, 0));
% 2. the results will be stored in params.temp_scf and params.temp_sort_order
% 3. sort temp_scf(:, 5) (number of frames persisted) and identify the first 30 particles that last more than half of the movie
% 4. assemble the (x, y, z) coordinates of all candidate fiducial markers
% 5. calculate an RMS matrix for all the candidate fiduciaries
% 6. identify a 'base' marker that shows the most 'low' RMSs
% 7. choose additional markers that are similar to the base marker
% 8. calculate a drift correction curve for (x, y) (and z if applicable)

global params handles

% step 0, check existing fiduciaries and ask user how to proceed

% step 1, perform a special sorting after setting the parameters
params.temp_thresh = 6;
params.temp_preturn = 5;
params.temp_pdist = 200;
params.temp_min_goodness = 0.3;
params.temp_max_eccentricity = 2;

palmsort(0, 0);
dispmessage('Sorting finsihed. Now identifying potential fiducaries ...');
pause(0.01);

[~, ind] = sort(params.temp_scf(:, 5), 'descend');
min_frames = params.frames * 0.6;

min_particles = 50;
if length(params.coords) < min_particles
    min_particles = length(params.coords);
end

% step 2, identify the indices of all potential fiduciaries    
ind_pf = find(params.temp_scf(ind(1:min_particles), 5) > min_frames);
num_pf = length(ind_pf);

if num_pf > 0
    dispmessage(sprintf('Identified %d potential fiducaries that last at least %d frames.', num_pf, params.temp_scf(ind(ind_pf(end)), 5)));
else
    dispmessage(sprintf('Did not find any potential fiduciaries. Exiting ...'));
    return;
end

pause(0.01);

% step 3, assemble the (x, y) trajectories for all candidate fiducaries.
ind_scf = ind(ind_pf);
traces = zeros(num_pf, params.frames, 3);    % frame_num, x, y, z

% figure; hold on;

for i = 1 : num_pf
   % for each particle, find their ids in the unsorted coord
   ind = find(params.temp_sort_order == ind_scf(i));
   frames = params.coords(ind, 1);
   
   % assign x and y values
   traces(i, frames, 1:2) = params.coords(ind, 2:3);
   %traces_pf(i, frames, 2) = params.coords(ind, 3);

   % reset baselines to 0
   traces(i, frames, 1) = traces(i, frames, 1) - traces(i, frames(1), 1);
   traces(i, frames, 2) = traces(i, frames, 2) - traces(i, frames(1), 2);
   
%    plot(frames, traces(i, frames, 1), 'r-'); 
%    plot(frames, traces(i, frames, 2), 'b-');
%    axis on; axis tight;
%    
%    pause(0.01);
end

%axis on; axis tight;

% now construct a 2-D matrix for the distance fluctuations between two trajectories
dist_rms = zeros(num_pf, num_pf);
for i = 1 : num_pf
    for j = 1 : i-1
        dist = sqrt((traces(i, :, 1) - traces(j, :, 1)).^2 + (traces(i, :, 2) - traces(j, :, 2)).^2);
        dist_rms(i, j) = std(dist);
        dist_rms(j, i) = 100;
    end
    
    dist_rms(i, i) = 100;
end

%params.dist_rms = dist_rms;



%if freq == 1
    % when there is no winner as the most frequent particle # with lowest
    % rms, choose the pair that shows the smallest rms
    [p1 p2] = find(dist_rms == min(min(dist_rms)));
%else
    % when a particle appears multiple times in the search, use it as the
    % base particle
    
    % locate all the cols where the particle row appeared as having the
    % lowest dist rms. there should be at least 2 particles that match with
    % particle # row
    % alternative method
%     [~, ind] = min(dist_rms);
%     [row freq] = mode(ind); 
% 
%     ind2 = find(ind == row);
%     min_dists = dist_rms(row, ind2);
%     [~, min_cols] = sort(min_dists, 'ascend');
% 
%     p3 = row;   p4 = min_cols(1);

%end



% plot the pair in both x and y space
figure; hold on;
plot(1:params.frames, traces(p1, :, 1), 'r-');
plot(1:params.frames, traces(p2, :, 1), 'g-');
plot(1:params.frames, traces(p1, :, 2)+0.5, 'b-');
plot(1:params.frames, traces(p2, :, 2)+0.5, 'm-');

axis on; box on;  axis tight; 
yrange = ylim;  ylim([yrange(1) - 0.2 yrange(2)+0.5]);
legend('Particle #1, X', 'Particle #2, X', 'Particle #1, Y', 'Particle #2, Y');
title(sprintf('Found particles #%d and #%d with lowest distance RMS (%.3f pixel).', p1, p2, dist_rms(p1, p2)));

% figure; hold on;
% 
% % plot the pair in both x and y space
% plot(1:params.frames, traces(p3, :, 1), 'r-');
% plot(1:params.frames, traces(p4, :, 1), 'g-');
% plot(1:params.frames, traces(p3, :, 2)+0.5, 'b-');
% plot(1:params.frames, traces(p4, :, 2)+0.5, 'm-');
% 
% axis on; box on;  axis tight; ylim([-0.5 1.5]);
% legend('Particle #1, X', 'Particle #2, X', 'Particle #1, Y', 'Particle #2, Y');
% title(sprintf('Found particles #%d and #%d with lowest distance RMS of %.3f pixel (with min RMS of all = %.3f)', p3, p4, dist_rms(p3, p4), min(min(dist_rms))));
% 

% mark the fiduciary on the sum image
%figure(params.palmpanel);
%p1_meanx = mean(traces(p1, :, 1));

%hold on; plot(

    
    


