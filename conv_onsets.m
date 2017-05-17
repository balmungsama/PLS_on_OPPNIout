%%%%% function to transform onsets from MSEC to TRs %%%%%

function YY = conv_onsets(onsets, TR)

	TR = TR * 1000;
	t_onsets = onsets / TR;
	t_onsets = floor(t_onsets);

	YY = t_onsets;
	% return YY

end