function cos_exposure_info,redo=redo,verbose=verbose,datdir=datdir
if n_elements(redo) ne 1 then redo=0
if n_elements(verbose) ne 1 then verbose=0
if n_elements(datdir) ne 1 then datdir=get_smov_dir(/Analysis)+'dat/'
datfile ='cos_exposures.dat'

	if verbose then print, 'Using COS Exposure file ', datdir+datfile
	if redo then begin
		save_exposure_info,csv=csv,/new
	endif else begin
		restore,datdir+datfile,verbose=verbose
		csv=csvstruct
	endelse

	return,csv
end
