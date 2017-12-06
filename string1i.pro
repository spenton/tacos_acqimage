function string1i,f,format=format,round=round,fix=fix
	if n_elements(fix) ne 1 then fix=0
	; round is the default
	if n_elements(round) ne 1 then round=1
	if not keyword_set(format) then format='(I)'
	fout=f
	if round then fout=round(double(f))
	if fix then fout=fix(double(f))
	return,strtrim(string(round(fout,/L64),format=format),2)
end
