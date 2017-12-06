pro save_exposure_info,indir=indir,csvstruct=csvstruct,verbose=verbose,new=new,create_txt=create_txt
if n_elements(create_txt) ne 1 then create_txt=0
if n_elements(new) ne 1 then new=1
if n_elements(verbose) ne 1 then verbose=0
if n_elements(indir) ne 1 then indir=get_smov_dir(/data)
if n_elements(outdir) ne 1 then outdir=get_smov_dir(/analysis)+'/dat/'
exclude=[801,8608,4925]
;Program to read in Brian York's exposure_info.csv file, which contains
; information about each exposure, put the data into a structure, and
; then save the structure to an IDL save file.
;At the moment, the input and output file specifications are hard coded.

;Written by David Sahnow, October 2009
; 11 November 2009 - modified to specify the output filename at the top.
; 21 December 2009 - now prints filenames to screen.
; 21 October 2010 - changed input file to be cos_exposures.csv, which is
;  the new version (generated from the database).
; 12 November 2010 - adding printing of minimum and maximum EXPSTART.

;Input and output files:
infile =(new ? 'cos_exposures.csv' : 'exposure_info.csv')
outfile =(new ? 'cos_exposures.dat' : 'exposure_info.dat')

     print, 'Using input file ', indir+infile
    csvdata = read_csv(indir+infile, header=csvheader, count=numlines)
    numtags = n_tags(csvdata)

    tempstruct = create_struct(csvheader[0], (csvdata.(0))[0])
    for k=1,numtags-1 do begin
         temp = strpos(csvheader[k],"-")    ;replace dashes with underscores
         if (temp ge 0) then begin
              t1 = csvheader[k]
              strput, t1, '_', temp
              csvheader[k] = t1
         endif
         temp = strpos(csvheader[k],"?")    ;replace ? with underscores
         if (temp ge 0) then begin
              t1 = csvheader[k]
              strput, t1, '_', temp
              csvheader[k] = t1
         endif
         temp = strpos(csvheader[k],".")    ;replace . with underscores
         if (temp ge 0) then begin
              t1 = csvheader[k]
              strput, t1, '_', temp
              csvheader[k] = t1
         endif
         temp = strpos(csvheader[k],"_")    ;replace leading underscores w/ o
         if (temp eq 0) then begin
              t1 = csvheader[k]
              strput, t1, 'o', temp
              csvheader[k] = t1
         endif
         tempstruct = create_struct(tempstruct, csvheader[k], (csvdata.(k))[0])
    endfor

    csvstruct = replicate(tempstruct, numlines)
;stop
    for k=0,numtags-1 do begin
         csvstruct.(k) = csvdata.(k)
    endfor

    n_orig=n_elements(csvstruct)
	index=where(csvstruct.proposal ne exclude[0] and csvstruct.proposal ne exclude[1] and csvstruct.proposal ne exclude[2],good_count)
	message,/info,'Excluding '+string1i(n_orig-good_count)+' as non-Science exposures.'
	csvstruct=csvstruct[index]
    fullout = outdir + outfile
    save, csvstruct, file=fullout,/compress,verbose=verbose


     nzero = where(csvstruct.expstart gt 0)
     mjdmin = min(csvstruct[nzero].expstart)
     mjdmax = max(csvstruct[nzero].expstart)
     print, mjdmin, mjd2date(mjdmin), format='("Earliest EXPSTART is ",f10.4," (",a,")")'
     print, mjdmax, mjd2date(mjdmax), format='("  Latest EXPSTART is ",f10.4," (",a,")")'

if create_txt then begin
str='Grating    CENWAVE   FP      OSM1_Coarse     OSM1_Fine       OSM2_coarse     OSM2_FIne  NAME MJD  OSM1_Focus'
c=csvstruct
outdir=get_smov_dir(/Analysis)+'txt/'
fuvfile='JB_FUV2.txt'
bmfile='JB_BM.txt'
nuvfile='JB_NUV2.txt'
mirfile='JB_MIRROR2.txt'
fuv=where(c.detector eq 'FUV' and c.opt_elem ne 'N/A')
nuv=where(c.detector eq 'NUV' and (c.opt_elem ne 'MIRRORA' and c.opt_elem ne 'MIRRORB'))
mir=where(c.detector eq 'NUV' and (c.opt_elem eq 'MIRRORA' or c.opt_elem eq 'MIRRORB'))
FF='(A6,"	",I4,"	",I1,"	",I,"	",I,"	",I,"	",I,"	",A,"	",F10.4,"	",I,"	",I,"	",I)'
svp_forprint,c[fuv].opt_elem,c[fuv].cenwave,c[fuv].FPPOS,c[fuv].OSM1_COARSE,c[fuv].OSM1_FINE,c[fuv].OSM2_COARSE,c[fuv].OSM2_FINE[fuv],$
	c.IPPPSSOOT,c[fuv].expstart,c[fuv].FOCUS,c[fuv].APER_DISP,c[fuv].APER_XDISP,format=FF,textout=outdir+fuvfile
svp_forprint,c[nuv].opt_elem,c[nuv].cenwave,c[nuv].FPPOS,c[nuv].OSM1_COARSE,c[nuv].OSM1_FINE,c[nuv].OSM2_COARSE,c[nuv].OSM2_FINE[nuv],$
	c.IPPPSSOOT,c[nuv].expstart,c[nuv].FOCUS,c[nuv].APER_DISP,c[nuv].APER_XDISP,format=FF,textout=outdir+nuvfile
svp_forprint,c[mir].opt_elem,c[mir].cenwave,c[mir].FPPOS,c[mir].OSM1_COARSE,c[mir].OSM1_FINE,c[mir].OSM2_COARSE,c[mir].OSM2_FINE[mir],$
	c.IPPPSSOOT,c[mir].expstart,c[mir].FOCUS,c[mir].APER_DISP,c[mir].APER_XDISP,format=FF,textout=outdir+mirfile

bm=where(c.detector eq 'FUV' and (c.cenwave eq 1096 or c.cenwave eq 1055),fcount)
svp_forprint,c[bm].opt_elem,c[bm].cenwave,c[bm].FPPOS,c[bm].OSM1_COARSE,c[bm].OSM1_FINE,c[bm].OSM2_COARSE,c[bm].OSM2_FINE[bm],$
	c.IPPPSSOOT,c[bm].expstart,c[bm].FOCUS,c[bm].APER_DISP,c[bm].APER_XDISP,format=FF,textout=outdir+bmfile

svp_forprint,c[bm].opt_elem,c[bm].cenwave,c[bm].FPPOS,c[bm].OSM1_COARSE,c[bm].OSM1_FINE,c[bm].OSM2_COARSE,c[bm].OSM2_FINE[bm],$
	c.IPPPSSOOT,c[bm].expstart,c[bm].FOCUS,c[bm].APER_DISP,c[bm].APER_XDISP,format=FF
endif
end
