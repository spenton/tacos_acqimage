function string1f,f,format=format
	if not keyword_set(format) then format='(F)'
	s_out=string(f)
	nf=ulong64(n_elements(f))
	for j=ulong64(0),ulong64(nf-1) do $
		s_out[j]=strtrim(string(f[j],format=format),2)
	return,s_out	
end
