

input_file = fscanf(fileID, '%c');
input_file = strsplit(input_file, 'IN=')';
input_file = {input_file{2:end}};

% input_file_array = cell(length(input_file),length(strsplit(input_file{1})));

for line = 1:length(input_file)
	tmp_line    = strsplit( input_file{line} );
	% tmp_line{1} = ['IN=', tmp_line{1}];
	tmp_line    = tmp_line(~cellfun('isempty',tmp_line));

	if exist('input_file_array') == true
		input_file_array = vertcat(input_file_array, tmp_line);
	else
		input_file_array = tmp_line;
	end

end

input_file = input_file_array;
clear input_file_array tmp_line;
fclose(fileID);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% include loop for groups after this %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_subs = size(input_file,1);
for subj = 1:num_subs
	subj_task = input_file{subj, 5};
	subj_task = strsplit(subj_task, '=');
	subj_task = subj_task(2);
	subj_task = subj_task{1};

	%TODO insert subject loop in here %%%%%

end

% subj_task ='C:\Users\john\Desktop\practice_PLS\nathan_splitinfo_GO\older\10745_run4.txt'; %TODO TESTING
fid       = fopen(subj_task);

cond_count    = 0;
cond(1).names = 0;

while true

	tline = fgetl(fid);

	if sum(size(tline)) == 0; continue; end % check if the line is blank
	if ~ischar(tline); break; end                % check if the file has ended

	TFname = strfind(tline, 'NAME='    );
	TFons  = strfind(tline, 'ONSETS='  );
	TFdur  = strfind(tline, 'DURATION=');
	SCunit = strfind(tline, 'UNIT='    );
	SCtr   = strfind(tline, 'TR_MSEC=' );
	SCtype = strfind(tline, 'TYPE='    );

	TFname = TFname(:);
	TFons  = TFons(:) ;
	TFdur  = TFdur(:) ;

	tline = strsplit(tline, '[');
	tline = tline(2); 
	tline = tline{1};
	tline = strsplit(tline, ']');
	tline = tline(1);
	tline = tline{1};

	if ~isempty(TFname);
		cond_count             = cond_count + 1;		
		cond(cond_count).names = tline;
	elseif ~isempty(TFons);
		cond(cond_count).ons   = tline;
	elseif ~isempty(TFdur);
		cond(cond_count).dur   = tline;
	elseif ~isempty(SCunit)
		scan.unit = tline;
	elseif ~isempty(SCtr)
		scan.tr   = tline;
	elseif ~isempty(SCtype);
		scan.type = tline;
	end

	% scan and cond are the variables containing important information

end

fclose(fid);

%%%%% write to text file #####	

fid = fopen('MyFile.txt','w');

for num_conds = 1:cond_count;
	fprintf(fid, [cond(num_conds).names, ' c', num2str(num_conds), '\n' ] );
	fprintf(fid, ['ref_scan_onset ', num2str(0), '\n'   ] );
	fprintf(fid, ['num_ref_scan '  , num2str(1), '\n\n' ] );
end

for nsubj = 1:num_subs;
	fprintf(fid, [ 'data_files ', input_file{nsubj,1}, '\n' ] );
	
	% this doesn't properly cycle trhough the subjects
	for num_conds = 1:cond_count;
		fprintf(fid, [ 'data_files ', cond(num_conds).ons, '\n' ] );
	end

	fprintf(fid, [ '\n' ] );

end

fclose(fid);

