function delline(num)
% 
% function delline(num)
% that deletes the #num th line in the pool

global results;

total_lines = results.ktests.num
line_length = length(results.ktests.steps)

if num > total_lines
	disp('Out of range. No line deleted.');
	return;
end

rpcs = results.ktests.rpcs;

for i=num:results.ktests.num-1
	rpcs(:, i) = rpcs(:, i+1);
end

results.ktests.rpcs = rpcs(:, 1:results.ktests.num-1);
results.ktests.num = results.ktests.num - 1;

msg = sprintf('Line #%d in the pool deleted.', num);
disp(msg);

end
