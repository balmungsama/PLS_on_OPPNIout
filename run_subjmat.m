pls_list = dir([PREFIX, '*']);
pls_list = {pls_list(:).name};

for pls_item = pls_list
	batch_plsgui(pls_item{:});
end