
%%%%% load matlab plugins %%%%%

% addpath('/global/home/hpc3586/JE_packages/PLS_on_OPPNIout')


%% function calls 

prefs       = read_usr_prefs(prefs_file);
input_array = get_oppni_input(INPUT, prefs.detect_runs);

if prefs.detect_runs 
	batch_iterations = unique(input_array.SUBJ_ID);
elseif ~prefs.detect_runs
	batch_iterations = input_array.IN;
end

for subj = 1:length(batch_iterations)
	subj = batch_iterations{subj};

	if prefs.detect_runs
		subj_sessions    = find(strcmp(subj, input_array.SUBJ_ID));
	elseif ~prefs.detect_runs
		subj_sessions    = find(strcmp(subj, input_array.IN));
	end

	subj_onsets      = convert_onsets(input_array, subj_sessions);
	subj_input_array = input_array(subj_sessions,:);

	if prefs.detect_runs
		name = unique(subj_input_array.SUBJ_ID);
	elseif ~prefs.detect_runs
		[~,name,~] = fileparts(subj_input_array.IN);
	end

	write_plsbatch(subj_input_array, name{:}, subj_onsets, outpath, prefs);
	clear subj_input_array;
end

exit

%% define functions

function prefs = read_usr_prefs(prefs_file)

	fid = fopen(prefs_file);
	while ~feof(fid)
		tline = fgetl(fid);
		
		if startsWith(tline, 'brain_region')
			brain_region = strsplit(tline, ' ');
			prefs.brain_region = brain_region{2};
		elseif startsWith(tline, 'win_size')
			win_size = strsplit(tline, ' ');
			prefs.win_size = win_size{2};
		elseif startsWith(tline, 'across_run')
			across_run = strsplit(tline, ' ');
			prefs.across_run = across_run{2};
		elseif startsWith(tline, 'single_subj')
			single_subj = strsplit(tline, ' ');
			prefs.single_subj = single_subj{2};
		elseif startsWith(tline, 'single_ref_scan')
			single_ref_scan = strsplit(tline, ' ');
			prefs.single_ref_scan = single_ref_scan{2};
		elseif startsWith(tline, 'single_ref_onset')
			single_ref_onset = strsplit(tline, ' ');
			prefs.single_ref_onset = single_ref_onset{2};
		elseif startsWith(tline, 'single_ref_number')
			single_ref_number = strsplit(tline, ' ');
			prefs.single_ref_number = single_ref_number{2};
		elseif startsWith(tline, 'normalize')
			normalize = strsplit(tline, ' ');
			prefs.normalize = normalize{2};
		elseif startsWith(tline, 'pipe')
			pipe = strsplit(tline, ' ');
			prefs.pipe = pipe{2};
			prefs.pipe = str2num(prefs.pipe);
		elseif startsWith(tline, 'detect_runs')
			detect_runs = strsplit(tline, ' ');
			prefs.detect_runs = detect_runs{2};
			prefs.detect_runs = logical(str2num(prefs.detect_runs));
		elseif startsWith(tline, 'relative_ref_onset')
			relative_ref_onset = strsplit(tline, ' ');
			prefs.relative_ref_onset = relative_ref_onset{2};
		elseif startsWith(tline, 'relative_ref_num')
			relative_ref_num = strsplit(tline, ' ');
			prefs.relative_ref_num = relative_ref_num{2};
		else
			continue
		end

	end
	fclose(fid);

end

function input_array = get_oppni_input(INPUT, detect_runs)
	%myFun - Description
	%
	% Syntax: input_file_array = myFun(input)
	%
	% Long description

	input_array = readtable(INPUT, 'Delimiter', ' ', 'ReadVariableNames', false, 'HeaderLines', 0);

	for col = 1:size(input_array,2)
		for row = 1:size(input_array,1)

			val_tmp = strsplit( char(input_array{row, col}), '=');
			input_array{row, col} = val_tmp(1,2);

			if row == 1
				input_array.Properties.VariableNames{col} = val_tmp{1,1};
			end

		end

	end

	if detect_runs
		unique_struct.orig = input_array(:,find(strcmp(input_array.Properties.VariableNames, 'STRUCT'))).Variables;
		unique_struct.ls   = unique(unique_struct.orig);
		[~, unique_struct.names,~] = cellfun(@fileparts, input_array(:,find(strcmp(input_array.Properties.VariableNames, 'STRUCT'))).Variables,'un', 0);
		[~,unique_struct.ind] = ismember(unique_struct.orig, unique_struct.ls);
	else
		unique_struct.ind = [1:size(input_array,1)]';
		[~, unique_struct.names,~] = cellfun(@fileparts, input_array(:,find(strcmp(input_array.Properties.VariableNames, 'IN'))).Variables,'un', 0);
	end

	unique_subjs = table(unique_struct.ind, unique_struct.names, 'VariableNames', {'SUBJ_IND', 'SUBJ_ID'});
	input_array  = [input_array, unique_subjs];

end

function onsets = convert_onsets(input_array, subj_sessions)

	for loop_count = 1:length(subj_sessions)
		session = subj_sessions(loop_count);

		drops = input_array.DROP{session};
		drops = regexprep(drops, '\[(.*)\]', '$1');
		onsets(loop_count).drops = str2num(drops);

		task_file = input_array.TASK{session};

		fid = fopen(task_file);
		while ~feof(fid)
			tline = fgetl(fid);

			if startsWith(tline, 'TR_MSEC')
				tr_msec = strsplit(tline, '=');
				tr_msec = tr_msec{2};
				tr_msec = regexprep(tr_msec, '\[(.*)\]', '$1');
				onsets(loop_count).tr_msec = str2num(tr_msec);
			elseif startsWith(tline, 'NAME')
				name = strsplit(tline, '=');
				name = name{2};
				onsets(loop_count).name = regexprep(name, '\[(.*)\]', '$1');
			elseif startsWith(tline, 'ONSETS')
				event_onsets = strsplit(tline, '=');
				event_onsets = event_onsets{2};
				event_onsets = regexprep(event_onsets, '\[(.*)\]', '$1');
				onsets(loop_count).onsets = str2num(event_onsets);
			end

		end
		fclose(fid);

		% convert the onsets into TRs
		onsets(loop_count).onsets = onsets(loop_count).onsets ./ onsets(loop_count).tr_msec;
		onsets(loop_count).onsets = onsets(loop_count).onsets  - onsets(loop_count).drops(1);

		% round them to integers so that they correspond to specific volumes in the timeseries
		onsets(loop_count).onsets = round(onsets(loop_count).onsets);
	end

end

function write_plsbatch(subject, name, onsets, output_path, prefs)
	pipes = {'CON', 'FIX', 'IND'};
	prefs.pipe = pipes{prefs.pipe}; % convert the pipeline setting to a character vector

	% subject = input_array([1, 27],:)

	for num_run = 1:size(subject,1)
		subject_name = subject.OUT{num_run};
		[~,subject_name,~] = fileparts(subject_name);

		[nifti_file,~]          = fileparts(subject.OUT{num_run});
		nifti_file              = fullfile(nifti_file, 'optimization_results', 'processed', ['*', subject_name, '*' prefs.pipe, '_sNorm.nii']);
		nifti_file              = dir(nifti_file);
		subject.nifti{num_run}  = fullfile(nifti_file.folder, nifti_file.name);
	end

	subject_batch = unique(subject.SUBJ_ID);
	subject_batch = subject_batch{:};
	subject_batch = fullfile(output_path, [subject_batch, '.txt']);

	% the actual writing starts 
	fid = fopen( subject_batch, 'w'); 
	fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); % Division 

	%%%%% first section  - General Section Start
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
	fprintf(fid, ['	%%  General Section Start  %%\n']);
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);
	
	fprintf(fid, [ 'prefix '            , name                      , '\n'   ] ); % prefix for session file and datamat file
	fprintf(fid, [ 'brain_region '      , prefs.brain_region        , '\n'   ] ); % threshold or file name for brain region
	fprintf(fid, [ 'win_size '          , prefs.win_size            , '\n'   ] ); % temporal window size in scans
	fprintf(fid, [ 'across_run '        , prefs.across_run          , '\n'   ] ); % 1: merge data across runs, 0: within each run
	fprintf(fid, [ 'single_subj '	      , prefs.single_subj         , '\n'   ] ); % 1: single subject analysis, 0: normal analysis
	fprintf(fid, [ 'single_ref_scan '	  , prefs.single_ref_scan     , '\n'   ] ); % 1: single ref scan, 0: normal ref scan
	fprintf(fid, [ 'single_ref_onset '  , prefs.single_ref_onset    , '\n'   ] ); % single reference scan onset
	fprintf(fid, [ 'single_ref_number ' , prefs.single_ref_number   , '\n'   ] ); % single reference scan number
	fprintf(fid, [ 'normalize '         , prefs.normalize           , '\n\n' ] ); % normalize vol mean; 0 unless necessary

	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n'  ]);
	fprintf(fid, ['	%%  General Section End  %%\n']);
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

	fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] );  

	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
	fprintf(fid, ['	%%  Condition Section Start  %%\n']);
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

	cond_names = unique({onsets.name});
	for cond_name = cond_names
		fprintf(fid, ['cond_name '     , cond_name{1}            , '\n'   ] );
		fprintf(fid, ['ref_scan_onset ', prefs.relative_ref_onset, '\n'   ] );
		fprintf(fid, ['num_ref_scan '  , prefs.relative_ref_num  , '\n\n' ] );
	end

	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
	fprintf(fid, ['	%%  Condition Section End  %%\n']);
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

	fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); 

	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
	fprintf(fid, ['	%%  Run Section Start  %%\n']);
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);

	% disp(size(onsets))

	for num_run = 1:(size(onsets,2)/length(cond_names))
		fprintf(fid, ['data_files      ', subject.nifti{num_run}, '\n'] );
		% disp(['data_files      ', subject.nifti{num_run}, '\n']);

		for cond_name = unique({onsets.name})
			cond_runs = find(strcmp(cond_name, {onsets.name}));
			cond_run  = cond_runs(num_run);
			
			fprintf(fid, ['event_onsets	 ', num2str(onsets(cond_run).onsets), '\n\n'] );
			% disp(['event_onsets	 ', num2str(onsets(cond_run).onsets), '\n\n']);
		end
	end

	fprintf(fid, [ '\n' ] );
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n']);
	fprintf(fid, ['	%%  Run Section End  %%\n']);
	fprintf(fid, ['	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n']);
	fprintf(fid, [ '\n%%------------------------------------------------------------------------\n\n' ] ); 

	fclose(fid);

end


% matlab -nodesktop -nosplash -r "INPUT='/global/home/hpc3586/SART_data/glm/scripts/glm/level_1/yng_go_input_file.txt';prefs_file='/global/home/hpc3586/SART_data/glm/scripts/glm/level_1/task_pls_prefs.txt';outpath='/global/home/hpc3586/SART_data/glm/scripts/glm/level_1';run('/global/home/hpc3586/JE_packages/PLS_on_OPPNIout/read_subjmat.m')"