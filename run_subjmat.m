cd(OUTPUT);
disp(pwd);

pls_list = dir([PREFIX, '*']);
pls_list = {pls_list(:).name};

for pls_item = pls_list
	disp(' ');
	disp(['> ', pls_item{:}]);
	batch_plsgui(pls_item{:});
end

exit