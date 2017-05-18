% TODO: write function to transform onsets from MSEC to TRs

%%%%% Add the PLS package to Matlab's search path %%%%%

PLUGINS = fopen('matlab_plugins.txt');
PLUGINS_DIR = fscanf(PLUGINS, '%c', Inf);
fclose(PLUGINS);

PLUGINS_DIR = fullfile( PLUGINS_DIR, 'Pls');

addpath( genpath(PLUGINS_DIR) );

%%%%% check OS to determine how to access BASH commands %%%%%

if strcmp(OS, 'windows') == true
	bash = 'bash -c ';
else
	bash = 'bash ';
end

%%%%% begin gathering data to build text file %%%%%

fileID     = fullfile(OPPNI_DIR, 'input_file.txt');
fileID     = fopen(fileID);
input_file = fscanf(fileID, '%c');
input_file = strsplit(input_file, 'IN=')';
input_file = {input_file{2:end}};

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

cond_count    = 0;
cond(1).names = 0;

[status, TR_length] = system(['fslval ', input_file{1,1}, ' pixdim4' ], '-echo');
TR_length = str2num(TR_length);

num_subs = size(input_file,1);
for subj = 1:num_subs
	subj_task = input_file{subj, 5};
	subj_task = strsplit(subj_task, '=');
	subj_task = subj_task(2);
	subj_task = subj_task{1};

	% subj_task ='C:\Users\john\Desktop\practice_PLS\nathan_splitinfo_GO\older\10745_run4.txt'; % TESTING

	fid = fopen(subj_task);

	while true

		tline = fgetl(fid);

		if sum(size(tline)) == 0; continue; end % check if the line is blank
		if ~ischar(tline); break; end           % check if the file has ended

		TFname = strfind(tline, 'NAME='    );
		TFons  = strfind(tline, 'ONSETS='  );
		TFdur  = strfind(tline, 'DURATION=');
		SCunit = strfind(tline, 'UNIT='    );
		SCtr   = strfind(tline, 'TR_MSEC=' );
		SCtype = strfind(tline, 'TYPE='    );
		DROP   = strfind(tline, 'DROP='    );

		TFname = TFname(:);
		TFons  = TFons(:) ;
		TFdur  = TFdur(:) ;
		DROP   = DROP(:)  ;

		tline = strsplit(tline, '[');
		tline = tline(2); 
		tline = tline{1};
		tline = strsplit(tline, ']');
		tline = tline(1);
		tline = tline{1};

		% scan and cond are the variables containing important information

		if ~isempty(TFname);
			cond_count             = cond_count + 1;		
			cond(cond_count).names = tline;
		elseif ~isempty(DROP);
			cond(cond_count).drop  = tline;
		elseif ~isempty(TFons);
			t_ons = tline;
			t_ons = conv_onsets(t_ons, TR_length, cond(cond_count).drop);
			cond(cond_count).ons   = t_ons;
		elseif ~isempty(TFdur);
			cond(cond_count).dur   = tline;
		elseif ~isempty(SCunit)
			scan.unit = tline;
		elseif ~isempty(SCtr)
			scan.tr   = tline;
		elseif ~isempty(SCtype);
			scan.type = tline;
		end

	end

	fclose(fid);

end

%%%%% write to text file #####	

fid = fopen( fullfile(OUTPUT, [PREFIX, '_batch_fmri_data.txt']), 'w'); 

fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line

%%%%% first section  - General Section Start

fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
fprintf(fid, ['	%%  General Section Start  %%\n']);
fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

fprintf(fid, [ 'prefix '		          , PREFIX     , '\n'   ] ); % prefix for session file and datamat file
fprintf(fid, [ 'brain_region '	      , BRAIN_ROI  , '\n'   ] ); % threshold or file name for brain region
fprintf(fid, [ 'win_size '	          , WIN_SIZE   , '\n'   ] ); % temporal window size in scans
fprintf(fid, [ 'across_run '	        , ACROSS_RUN , '\n'   ] ); % 1 for merge data across all run, 0 for within each run
fprintf(fid, [ 'single_subj '	        , SINGLE_SUBJ, '\n'   ] ); % 1 for single subject analysis, 0 for normal analysis
fprintf(fid, [ 'single_ref_scan '	    , NORM_REF   , '\n'   ] ); % 1 for single reference scan, 0 for normal reference scan
fprintf(fid, [ 'single_ref_onset '    , REF_ONSET  , '\n'   ] ); % single reference scan onset
fprintf(fid, [ 'single_ref_number '   , REF_NUM    , '\n'   ] ); % single reference scan number
fprintf(fid, [ 'normalize '           , NORMAL     , '\n\n' ] ); % normalize volume mean (keey 0 unless necessary)

fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
fprintf(fid, ['	%%  General Section End  %%\n']);
fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

%%%%% second section - Condition Section Start

fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line

fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
fprintf(fid, ['	%%  Condition Section Start  %%\n']);
fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

cond_count = unique({cond(:).names});
cond_count = length(cond_count);
for num_conds = 1:cond_count;
	fprintf(fid, [cond(num_conds).names, ' c', num2str(num_conds), '\n' ] ); % unique({cond(:).names})
	fprintf(fid, ['ref_scan_onset ', num2str(0), '\n'   ] );
	fprintf(fid, ['num_ref_scan '  , num2str(1), '\n\n' ] );
end

fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
fprintf(fid, ['	%%  Condition Section End  %%\n']);
fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

%%%%% run section start %%%%%

fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line

fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
fprintf(fid, ['	%%  Run Section Start  %%\n']);
fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

for nsubj = 1:num_subs;

	out_index           = strfind(input_file, 'OUT=');
	out_index           = out_index(1, :);
	out_index           = find(~cellfun(@isempty, out_index));

	tmp_input_file      = input_file{nsubj, out_index};
	[~, nifti_name, ~]  = fileparts(tmp_input_file);
	tmp_input_file      = fullfile(OPPNI_DIR, 'optimization_results', 'processed', ['*', nifti_name, '_IND_sNorm.nii'] );
	[~, tmp_input_file] = fileattrib(tmp_input_file);
	tmp_input_file      = tmp_input_file.Name;

	fprintf(fid, [ 'data_files ', tmp_input_file, '\n' ] );
	
	for num_cond = 1:cond_count;
		cond_ind = ((nsubj - 1) * cond_count) + num_cond;
		fprintf(fid, [ 'event_onsets ', cond(cond_ind).ons, '\n' ] );
	end

	fprintf(fid, [ '\n' ] );

end

fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
fprintf(fid, ['	%%  Run Section End  %%\n']);
fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line


fclose(fid);

disp('Batch file created.');

%%%%% run the PLS file that was just created %%%%%

% [status, tmp_output_dir] = system([bash, '"bash lin2win.sh ', OUTPUT, '"']);

if RUN == true
	disp('Running the batch file...');
	batch_plsgui fullfile(OUTPUT, [PREFIX, '_batch_fmri_data.txt'])
	disp('DONE!');
end

exit