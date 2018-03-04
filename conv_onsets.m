%%%%% function to transform onsets from MSEC to TRs %%%%%

function YY = conv_onsets(onsets, TR, DROP)

	% onsets = str2num(onsets);
	% DROP   = str2num(DROP);

	drop.start = DROP(1);
	drop.end   = DROP(2);

	TR = TR * 1000;

	% disp(onsets);
	% disp(TR);

	t_onsets = onsets ./ TR;
	t_onsets = round(t_onsets);  % TODO: decide if you want to use round() or floor()
	t_onsets = t_onsets - drop.start;
	t_onsets = sprintf('%.0f ' , t_onsets);
	t_onsets = t_onsets(1:end-1);

	YY = t_onsets;
	% return YY

end