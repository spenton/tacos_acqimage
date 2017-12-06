function svppar,hdr,key,silent=silent,count=count,comment=comment
	if n_elements(silent) ne 1 then silent=1

	val=sxpar_svp(hdr,key,silent=silent,count=count,comment=comment)

	st=size(val,/type)
	if st eq 7 then begin ; its a string
		val=strtrim(val,2)
	endif
	return,val
end
