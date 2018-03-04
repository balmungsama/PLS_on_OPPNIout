
%%%%% Add the PLS package to Matlab's search path %%%%%

% PLUGINS = fopen('matlab_plugins.txt');
% PLUGINS_DIR = fscanf(PLUGINS, '%c', Inf);
% fclose(PLUGINS);

% PLUGINS_DIR = fullfile( PLUGINS_DIR, 'Pls');

% addpath( genpath(PLUGINS_DIR) );

%%%%% check OS to determine how to access BASH commands %%%%%

if strcmp(OS, 'windows') == true
	bash = 'bash -c ';
else
	bash = 'bash ';
end

%%%%% trouble-shooting print statements %%%%%

disp(class(OS         ))
disp(class(OPPNI_DIR  ))
disp(class(OUTPUT     ))
disp(class(PREFIX     ))
disp(class(BRAIN_ROI  ))
disp(class(WIN_SIZE   ))
disp(class(ACROSS_RUN ))
disp(class(NORM_REF   ))
disp(class(SINGLE_SUBJ))
disp(class(REF_ONSET  ))
disp(class(REF_NUM    ))
disp(class(NORMAL     ))
disp(class(RUN        ))
disp(class(MERGE_RUNS ))

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

disp('1')

input_file = input_file_array;
clear input_file_array tmp_line;
fclose(fileID);

cond_count    = 0;
cond(1).names = 0;

sample_img = input_file{1,1};
if ~exist(sample_img, 'file')
	sample_img = fullfile('/global', sample_img);
end

disp(2)

[status, TR_length] = system(['fslval ', sample_img, ' pixdim4' ]);
TR_length = str2num(TR_length);

num_subs = size(input_file,1);

out_index = strfind(input_file, 'OUT=');
out_index = out_index(1, :);
out_index = find(~cellfun(@isempty, out_index));

out_array  = input_file(:, out_index);

disp(3)

% get an array of all individual subjects and their respective runs
for row = 1:size(out_array, 1);
	out_array2(row,:)  = strsplit(out_array{row}, '=');
	name               = out_array2{row,2};
	[pathstr,name,ext] = fileparts(name);
	out_array2(row,:)  = strsplit(name, '_run');
end

for row = 1:size(out_array, 1);
	out_array2{row,3}  = str2num(out_array2{row,2});
end

disp(4)

out_array = out_array2;
clear out_array2;

group.out_array = out_array;
% group.names     = unique( group.out_array(:,1) ); % get array of unique subjects
[group.names, grp_indx] = unique( group.out_array(:,1) ); % get array of unique subjects
 group.names            = group.out_array(sort(grp_indx)) ;

disp(5)

for row = 1:size(group.names, 1)
	name_index      = strfind( group.out_array(:, 1), group.names{row} );
	name_index      = find(~cellfun(@isempty, name_index))';
	group.runs{row,1} = [ group.out_array{ [name_index] , 3} ];
	group.rows{row,1} = [name_index];
end

clear out_array;

disp(6)
for subj = 1:size(input_file,1)
	subj_task = input_file{subj, 5};
	subj_task = strsplit(subj_task, '=');
	subj_task = subj_task(2);
	subj_task = subj_task{1};
	if ~exist(subj_task, 'file')
		subj_task = fullfile('/global', subj_task);
	end

	% find number of volumes to be dropped
	DROP = input_file(subj,:);
	DROP = strfind(DROP, 'DROP=');
	DROP = DROP(1, :);
	DROP = find(~cellfun(@isempty, DROP));
	DROP = input_file(subj, DROP);
	DROP = DROP{:};
	DROP = strsplit(DROP, '=');
	DROP = DROP{2};
	DROP = str2num(DROP);
	% disp(['DROP = ', num2str(DROP)]);
	
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

		TFname = TFname(:);
		TFons  = TFons(:) ;
		TFdur  = TFdur(:) ;

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
		elseif ~isempty(TFons);
			t_ons = tline;
			t_ons = str2num(t_ons);
			t_ons = conv_onsets(t_ons, TR_length, DROP);
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

disp(7)
%%%%% write to text file #####	
for nsubj = 1:size(group.names,1);
	if MERGE_RUNS == 0;
		for run_cur = group.runs{nsubj};

			batch_filename = fullfile(OUTPUT, [PREFIX, '_', group.names{nsubj}, '_run', num2str(run_cur), '_batch_fmri_data.txt']);
			fid = fopen( batch_filename, 'w'); 

			SUBJ_PREFIX = [PREFIX, '_', group.names{nsubj}];

			fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line

			%%%%% first section  - General Section Start

			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
			fprintf(fid, ['	%%  General Section Start  %%\n']);
			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

			fprintf(fid, [ 'prefix '		          , SUBJ_PREFIX    , '\n'   ] ); % prefix for session file and datamat file
			fprintf(fid, [ 'brain_region '	      , BRAIN_ROI      , '\n'   ] ); % threshold or file name for brain region
			fprintf(fid, [ 'win_size '	          , WIN_SIZE       , '\n'   ] ); % temporal window size in scans
			fprintf(fid, [ 'across_run '	        , ACROSS_RUN     , '\n'   ] ); % 1 for merge data across all run, 0 for within each run
			fprintf(fid, [ 'single_subj '	        , SINGLE_SUBJ    , '\n'   ] ); % 1 for single subject analysis, 0 for normal analysis
			fprintf(fid, [ 'single_ref_scan '	    , NORM_REF       , '\n'   ] ); % 1 for single reference scan, 0 for normal reference scan
			fprintf(fid, [ 'single_ref_onset '    , REF_ONSET      , '\n'   ] ); % single reference scan onset
			fprintf(fid, [ 'single_ref_number '   , REF_NUM        , '\n'   ] ); % single reference scan number
			fprintf(fid, [ 'normalize '           , NORMAL         , '\n\n' ] ); % normalize volume mean (keey 0 unless necessary)

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
				fprintf(fid, ['cond_name ', cond(num_conds).names, '\n' ] ); % unique({cond(:).names})
				fprintf(fid, ['ref_scan_onset ', REF_ONSET, '\n'   ] );
				fprintf(fid, ['num_ref_scan '  , REF_NUM  , '\n\n' ] );
			end

			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
			fprintf(fid, ['	%%  Condition Section End  %%\n']);
			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

			%%%%% run section start %%%%%

			fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line

			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
			fprintf(fid, ['	%%  Run Section Start  %%\n']);
			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

			task_run = group.runs{nsubj}; 
			task_run = task_run(run_cur);

			out_index           = strfind(input_file, 'OUT=');
			out_index           = out_index(1, :);
			out_index           = find(~cellfun(@isempty, out_index));

			tmp_input_file      = input_file{task_run, out_index};
			% tmp_input_file      = strsplit(tmp_input_file, '=');
			% tmp_input_file      = tmp_input_file{2};
			tmp_input_file      = strsplit(tmp_input_file, '=');
			tmp_input_file      = tmp_input_file{2};
			[~, nifti_name, ~]  = fileparts(tmp_input_file);
			tmp_input_file      = fullfile(OPPNI_DIR, 'optimization_results', 'processed', ['*', nifti_name, '_IND_sNorm.nii'] );
			[~, tmp_input_file] = fileattrib(tmp_input_file);
			tmp_input_file      = tmp_input_file.Name;

			fprintf(fid, [ 'data_files ', tmp_input_file, '\n' ] );
			
			for num_cond = 1:cond_count;
				cond_ind = ((task_run - 1) * cond_count) + num_cond;
				fprintf(fid, [ 'event_onsets ', cond(cond_ind).ons, '\n' ] );

				% disp([num2str(task_run) ' ' (cond_ind)]); % FIXME: this is a trouble-shooting  line 
			end

			fprintf(fid, [ '\n' ] );

			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
			fprintf(fid, ['	%%  Run Section End  %%\n']);
			fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

			fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line


			fclose(fid);

		end
	else
		batch_filename = fullfile(OUTPUT, [PREFIX, '_', group.names{nsubj}, '_batch_fmri_data.txt']);
		fid = fopen( batch_filename, 'w'); 

		SUBJ_PREFIX = [PREFIX, '_', group.names{nsubj}];

		fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line

		%%%%% first section  - General Section Start

		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
		fprintf(fid, ['	%%  General Section Start  %%\n']);
		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

		fprintf(fid, [ 'prefix '		          , SUBJ_PREFIX    , '\n'   ] ); % prefix for session file and datamat file
		fprintf(fid, [ 'brain_region '	      , BRAIN_ROI      , '\n'   ] ); % threshold or file name for brain region
		fprintf(fid, [ 'win_size '	          , WIN_SIZE       , '\n'   ] ); % temporal window size in scans
		fprintf(fid, [ 'across_run '	        , ACROSS_RUN     , '\n'   ] ); % 1 for merge data across all run, 0 for within each run
		fprintf(fid, [ 'single_subj '	        , SINGLE_SUBJ    , '\n'   ] ); % 1 for single subject analysis, 0 for normal analysis
		fprintf(fid, [ 'single_ref_scan '	    , NORM_REF       , '\n'   ] ); % 1 for single reference scan, 0 for normal reference scan
		fprintf(fid, [ 'single_ref_onset '    , REF_ONSET      , '\n'   ] ); % single reference scan onset
		fprintf(fid, [ 'single_ref_number '   , REF_NUM        , '\n'   ] ); % single reference scan number
		fprintf(fid, [ 'normalize '           , NORMAL         , '\n\n' ] ); % normalize volume mean (keey 0 unless necessary)

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
			fprintf(fid, ['cond_name ', cond(num_conds).names, '\n' ] ); % unique({cond(:).names})
			fprintf(fid, ['ref_scan_onset ', REF_ONSET, '\n'   ] );
			fprintf(fid, ['num_ref_scan '  , REF_NUM  , '\n\n' ] );
		end

		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
		fprintf(fid, ['	%%  Condition Section End  %%\n']);
		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

		%%%%% run section start %%%%%

		fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line

		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
		fprintf(fid, ['	%%  Run Section Start  %%\n']);
		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

		for task_run = group.rows{nsubj}; % was nsubj

			out_index           = strfind(input_file, 'OUT=');
			out_index           = out_index(1, :);
			out_index           = find(~cellfun(@isempty, out_index));

			tmp_input_file      = input_file{task_run, out_index};
			% tmp_input_file      = strsplit(tmp_input_file, '=');
			% tmp_input_file      = tmp_input_file{2};
			tmp_input_file      = strsplit(tmp_input_file, '=');
			tmp_input_file      = tmp_input_file{2};
			[~, nifti_name, ~]  = fileparts(tmp_input_file);
			tmp_input_file      = fullfile(OPPNI_DIR, 'optimization_results', 'processed', ['*', nifti_name, '_IND_sNorm.nii'] );
			[~, tmp_input_file] = fileattrib(tmp_input_file);
			tmp_input_file      = tmp_input_file.Name;

			fprintf(fid, [ 'data_files ', tmp_input_file, '\n' ] );
			
			for num_cond = 1:cond_count;
				cond_ind = ((task_run - 1) * cond_count) + num_cond;
				fprintf(fid, [ 'event_onsets ', cond(cond_ind).ons, '\n' ] );

				% disp([num2str(task_run) ' ' (cond_ind)]); % FIXME: this is a trouble-shooting  line 
			end

			fprintf(fid, [ '\n' ] );

		end

		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
		fprintf(fid, ['	%%  Run Section End  %%\n']);
		fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

		fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division Line


		fclose(fid);
	end
end

disp('Batch file created.');

exit