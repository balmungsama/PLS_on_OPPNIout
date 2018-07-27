%% TODO %%

% - [x] need to account for multiple conditions. 

%% load data %%
top_path = 'D:\SART_data\output_pls\detrend6_combined_clean\GO\pls_outcome\two_runs\min100_raw';
filename = 'yng&old_mu&sigma&tau&log.err.NOGO_fMRIresult.mat';
cd(top_path)
data = load(filename);

%% user-defined parameters %%
lv          = 4;
zTrans      = false; 
targetBehav = 'log.err.NOGO';

targetBehav = strcmp(targetBehav, data.behavname);
behav       = find(targetBehav);

substr_rm = {'session_Combined_', '_fMRIsessiondata.mat'};

%% get design info %%

ngroups = size(data.SessionProfiles,2);
nbehav  = size(data.behavname,2);
nlvs    = size(data.result.s,1);
nconds  = size(data.cond_name,2);

nsubjs = 0;
for group = 1:ngroups
    nsubjs = size(data.SessionProfiles{1,group},1) + nsubjs;
end

%% loop through groups %%

figure
count = 0;
for cond = 1:nconds
    for group = 1:ngroups
        %% update the count %%
        count = count + 1;
        
        %% get group index %%

        if group > 1
            ind_start = 1;
            ind_end   = 0;
            for grp = 1:(group-1)
                ind_start = ind_start + size(data.SessionProfiles{1,grp}, 1) ; 
            end
            ind_start = ind_start + (nsubjs * (cond-1));

            for grp = 1:group
                ind_end = ind_end + size(data.SessionProfiles{1,grp}, 1);
            end
            ind_end = ind_end + (nsubjs * (cond-1));
        else
            ind_start = 1 + (nsubjs * (cond-1));
            ind_end   = size(data.SessionProfiles{1,group}, 1) + (nsubjs * (cond-1));
        end

        %% create data point labels %%
        plot_labels = data.SessionProfiles{1,group};

        for substring = 1:size(substr_rm,2)
            plot_labels = erase(plot_labels, substr_rm{1,substring});
        end

        plot_labels = strrep(plot_labels,'_','-');

        %% axis labels %%
        x_lab  = data.behavname{behav};
        y_lab = 'brain score';

        %% generate X and Y variables for plotting
        X_data = data.result.stacked_behavdata(ind_start:ind_end , behav ) ;
        Y_data = data.result.usc(ind_start:ind_end               , lv    ) ;

        X_data = double(X_data);
        Y_data = double(Y_data);

        %% convert the X and Y data to zscores %%
        if zTrans == true
            X_data = zscore(X_data);
            Y_data = zscore(Y_data);
        end

        %% getting stats %%
        p_val = data.result.perm_result.sprob(lv);
        r_val = corrcoef(X_data, Y_data);
        r_val = r_val(1,2);

        %% plot the data %%

        subplot(nconds, ngroups, count)
        plot(X_data , Y_data , '.', 'MarkerSize', 15)
        % text(X_data , Y_data , plot_labels')
        lsline

        title([ 'grp' num2str(group) ' LV ' num2str(lv) ' ; r =' num2str(r_val) ' ; p = '  num2str(p_val)])
        xlabel(x_lab)
        ylabel(y_lab)

        % axis([-Inf Inf -200 200])
        
    end
end


