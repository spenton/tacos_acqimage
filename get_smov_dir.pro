function get_smov_dir,verbose=verbose,analysis=analysis,$
	data=data,pid=pid,lref=lref,science=science,sph=sph,$
	new_modes=new_modes,home=home,objects=objects,dropbox=dropbox,stis=stis,$
	GM=GM,gzip=gzip,box=box,lamps=lamps,oref=oref,GC=GC,dflya=dflya,central_storage=central_storage
	if n_elements(central_storage) ne 1 then central_storage=0 ; use this to operate on central store at STSCI (/smov/cos/...)
	if n_elements(dflya) ne 1 then dflya=0
	if n_elements(GC) ne 1 then GC=0
	if n_elements(oref) ne 1 then oref=0
	if n_elements(box) ne 1 then box=0
	if n_elements(lamps) ne 1 then lamps=0
	if n_elements(gzip) ne 1 then gzip=0 ; adds gzip to Data string
	if n_elements(GM) ne 1 then GM=0
	if n_elements(sph) ne 1 then sph=0
	if n_elements(dropbox) ne 1 then dropbox=0
	if n_elements(objects) ne 1 then objects=0
	if n_elements(new_modes) ne 1 then new_modes=0
	if n_elements(lref) ne 1 then lref=0
	if n_elements(data) ne 1 then data=0
	if n_elements(science) ne 1 then science=0
	if n_elements(analysis) ne 1 then analysis=0
	if n_elements(pid) ne 1 then pid=-1
	if n_elements(verbose) ne 1 then verbose=0
	if n_elements(home) ne 1 then home=0
	if n_elements(stis) ne 1 then stis=0

	HOMEDIR=(central_storage ? "/" : getenv('HOME')+'/')
	basedir=HOMEDIR+"smov/"+(stis ? "stis/" : 'cos/')
	if lref+data+analysis+new_modes+home gt 1 then begin
		message,"ERROR: Only one of Analysis, Data, New_Mode, Home & Lref can be set.",/info
		if verbose then message,/info,'Returning the path to '+basedir
		return,basedir
	endif

	case 1 of
		sph : begin
					dir=basedir+'science/fits/sph/'
					if pid ne -1 then dir+=string1i(pid)+'/'
				end
		analysis : begin
					dir=basedir+'Analysis/'
					if pid ne -1 then dir+=string1i(pid)+'/'
				end
		GM : begin
					dir=basedir+'GM/'
					if pid ne -1 then dir+=string1i(pid)+'/'
				end
		data:	begin
					dir=basedir+'Data/'
					if pid ne -1 then dir+=string1i(pid)+'/'
					if gzip then dir+="gzip/"
					if central_storage then begin
						message,/info,'Watch out '+dir+' uses otfrdata dirs instead of gzip.'
					endif
				end
		home: dir=HOMEDIR
		box:	dir=HOMEDIR+'Box Sync/SPENTON/'
		dflya:  dir=basedir+'science/dflya/'
		dropbox: dir=HOMEDIR+'Dropbox/'
		lamps:	dir=basedir+'Analysis/Lamps/'
		lref:   dir=basedir+'lref/'
		new_modes: dir=basedir+'new_modes/'
		science : dir=basedir+'science/'
		objects: dir=basedir+'Objects/'
		oref:   dir=basedir+'oref/'
		GC: dir=basedir+'Analysis/GC/'
		else:   dir=basedir
	endcase
	if verbose then message,/info,'Returning the path to '+dir

	return,dir
end
