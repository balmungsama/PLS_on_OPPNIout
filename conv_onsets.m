%%%%% function to transform onsets from MSEC to TRs %%%%%

function YY = conv_onsets(onsets, TR)
	onsets = str2num(onsets);

	TR = TR * 1000;
	t_onsets = onsets / TR;
	t_onsets = floor(t_onsets);
	t_onsets = num2cell(num2str(t_onsets(:)));
	t_onsets =  strjoin(t_onsets, ',');

	YY = t_onsets;
	% return YY

end