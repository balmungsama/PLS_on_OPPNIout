%%%%% function to transform onsets from MSEC to TRs %%%%%

function YY = conv_onsets(onsets, TR)
	onsets = str2num(onsets);

	TR = TR * 1000;

	t_onsets = onsets / TR;
	t_onsets = round(t_onsets);  % TODO: decide if you want to use rouond() or floor()
	t_onsets = sprintf('%.0f,' , t_onsets);
	t_onsets =  t_onsets(1:end-1);

	YY = t_onsets;
	% return YY

end