pro acqimage_centering_vs_sn_4way,aperture=aperture,mirror=mirror,buffer=buffer,redo=redo,debug=debug,verbose=verbose
	if n_elements(debug) ne 1 then debug=0
	if n_elements(verbose) ne 1 then verbose=0
	if n_elements(redo) ne 1 then redo=1
	if n_elements(buffer) ne 1 then buffer=1
	if n_elements(aperture) ne 1 then aperture='BOA'
	if n_elements(mirror) ne 1 then mirror='MIRROA'
	;
	; Just grab the TIME-TIME images with the these mirrors
	close_gwin
	c=cos_exposure_info()
	;
	; Define some directories for input/output
	;
	adir=get_smov_dir(/Analysis)
	tadir=adir+'TA/'
	pngdir=tadir+'png/'
	datdir=tadir+'dat/'

	fuv_color='DARK BLUE'
	nuv_color='HOT PINK'

	nlimit=1000
	nphot=150.0
	nsn=80
	minerrP=0.5
	minerr=double(minerrP/42.5)
	rightshift_boa=10
	xmin=400 ; only consider right half of the detector to remove WCA
	xmax=1000
	ymin=100
	ymax=1000
	xs=xmin+findgen(xmax-xmin+1)
	ys=ymin+findgen(ymax-ymin+1)

	index=where(c.obstype eq 'IMAGING' and c.OBSMODE eq 'TIME-TAG' and c.exptype ne 'DARK' and $
		c.detector eq 'NUV' and c.aperture ne 'FCA' and c.aperture ne 'WCA' and $
		c.proposal ne 11468 and c.proposal ne 11471 and c.proposal ne 11473 and c.proposal ne 11469 and $
		c.proposal ne 11538 and c.proposal ne 11515 and c.proposal ne 12189 ) ; and c.proposal ne 11474

	; 11471 was the NUV acq/image verification program
	; 11468 was original FGS-to-SI alignment program (SIAF was off)
	; 11473 was the NUV Performance verification, all the TIME-TAGs had the shutter closed and just looked at the WCA
	; 11474 was the NUV internal/external wavelength scale. IT's images should be OK.
	; 11469 was COS NUV Optics Alignment and Focus
	; 11538 was IO
	; 11515 was the light leak test
	; 12189 was diffuse filaments in NGC 1275

	im=c[index]

	colors=['DARK BLUE','DARK GREEN','RED','BLACK']
	checkbox_size=9
	scheckbox=string1i(checkbox_size)
	savefile='LowSN_ALL_centering_'+scheckbox+'.dat'

	num_images=4
	bigboxs=[31,47,43,71]
	actual_nimages=lonarr(num_images)
	actual_actual_nimages=actual_nimages
	final_sn=findgen(nsn)+1
	apertures=['PSA','BOA']
	mirrors=['MIRRORA','MIRRORB']

	if redo then begin

		final_errxA=(final_erryA=(final_errRA=fltarr(num_images,nsn)))
		final_errRA[*]=(final_erryA[*]=(final_errxA[*]=!values.f_nan))

		final_errxA9=(final_erryA9=(final_errRA9=fltarr(num_images,nsn)))
		final_errRA9[*]=(final_erryA9[*]=(final_errxA9[*]=!values.f_nan))

		mfinal_errxA=(mfinal_erryA=(mfinal_errRA=fltarr(num_images,nsn)))
		mfinal_errRA[*]=(mfinal_erryA[*]=(mfinal_errxA[*]=!values.f_nan))

		mfinal_errxA9=(mfinal_erryA9=(mfinal_errRA9=fltarr(num_images,nsn)))
		mfinal_errRA9[*]=(mfinal_erryA9[*]=(mfinal_errxA9[*]=!values.f_nan))

		final_sdvxA=(final_sdvyA=(final_sdvRA=fltarr(num_images,nsn)))
		final_sdvRA[*]=(final_sdvyA[*]=(final_sdvxA[*]=!values.f_nan))

		final_sdvxA9=(final_sdvyA9=(final_sdvRA9=fltarr(num_images,nsn)))
		final_sdvRA9[*]=(final_sdvyA9[*]=(final_sdvxA9[*]=!values.f_nan))

	combo=0
	for aper = 0,1 do begin
		this_aperture=apertures[aper]
		for mirror = 0,1 do begin
			this_mirror=mirrors[mirror]
			rightshift=(this_aperture eq 'BOA' ? rightshift_boa : 0)
			bigbox=bigboxs[combo]
			sbigbox=string1i(bigbox)
			ais=where(im.aperture eq apertures[aper] and im.opt_elem eq mirrors[mirror],ai_count)
			actual_nimages[combo]=ai_count

			running_errxA=(running_erryA=(running_errRA=fltarr(ai_count,nsn)))
			running_errRA[*]=(running_erryA[*]=(running_errxA[*]=!values.f_nan))

			running_errxA9=(running_erryA9=(running_errRA9=fltarr(ai_count,nsn)))
			running_errRA9[*]=(running_erryA9[*]=(running_errxA9[*]=!values.f_nan))

			sactual_nimages=string1i(actual_nimages)
			actual_nimage=0
			for b=0,ai_count-1 do begin
				pid=im[ais[b]].proposal
				root=im[ais[b]].IPPPSSOOT
				target=im[ais[b]].targname
				file=strlowcase(root)+'_rawtag.fits.gz'
				dir=get_smov_dir(/Data,pid=pid,/gzip)
				ttag0=mrdfits(dir+file,0,h0,/silent)
				ttag=mrdfits(dir+file,1,h1,/unsigned)
				if n_elements(ttag) le nlimit then goto, skipit
				actual_nimage++
				hdr=[h0,h1]
				exptime=float(svppar(hdr,'EXPTIME'))
				; convert to detector coordinates
				rawx=1023-ttag.rawy
				rawy=1023-ttag.rawx
				ai_image=float(hist_2d(rawx,rawy,min1=xmin,min2=ymin,max1=xmax,max2=ymax))
				bkg_rate=total(ai_image[-50:-1,-50:-1])/(50.0*50.0 * exptime)
				; Every nphot photons run a test
				; but don't let n be greater than S/N=100 = 100000 counts
				n=n_elements(ttag.time)/nphot
				n=(n) < 100000./nphot
				times=(medx=(medy=(sn=fltarr(n))))
				bigboxlines=(bigboxsamples=(lines=(samples=fltarr(n))))
				sn9=(counts_in_9box=fltarr(n))
				snbigbox=(counts_in_bigboxbox=fltarr(n))
				bkg_perp=fltarr(n)

				for i=1,n-1 do begin
					ii=i*nphot
					medx[i]=median(rawx[0:ii])
					medy[i]=median(rawy[0:ii])
					sn[i]=sqrt(float(ii))
					times[i]=ttag[i].time
					ai_image=float(hist_2d(rawx[0:ii],rawy[0:ii],min1=xmin,min2=ymin,max1=xmax,max2=ymax))
					cos_target_locate_checkbox,ai_image,checkbox_size,sample,line,extracted_box,maxcounts=maxcounts
					cos_target_locate_checkbox,ai_image,bigbox,samplebigbox,linebigbox,extracted_boxbigbox,maxcounts=maxcountsbigbox
					lines[i]=ymin+line
					samples[i]=xmin+sample
					bigboxlines[i]=ymin+linebigbox
					bigboxsamples[i]=xmin+samplebigbox
					bkg_perp[i]=bkg_rate*times[i]
					;
					; The background has not been implemented yet. I would need to change the linterps later on to interpol
					; The ETC uses a funny S/N, they use 100% of the target counts, but the 9x9*bkg_rate
					; So, for the ETC, Signal = counts_in_bigbox
					;                  Noise = sqrt(counts_in_bigbox)+bkg_noise(81*rate)
					; BUT, the number of counts in the 9x9 box is not sqrt(counts_in_bigbox)
					;
					; In the 9x9 box, the Signal = count_in_9box-bck_estimate
					;                     Noise = sqrt(Signal)+bck_estimate
					;
					counts_in_9box[i]=total(extracted_box)  ; -bkg_perp[i]*81.0
					counts_in_bigboxbox[i]=total(extracted_boxbigbox) ; -bkg_perp[i]*float(bigbox*bigbox)
					sn9[i]=sqrt(counts_in_9box[i]) ; + bkg_perp[i]*81
					snbigbox[i]=sqrt(counts_in_bigboxbox[i]) ; +bkg_perp[i]*float(bigbox*bigbox)
				endfor
				erry=abs(lines[-1]-lines) > minerrP
				errx=abs(samples[-1]-samples) > minerrP
				eR=sqrt(errx^2+erry^2) > minerrP*sqrt(2)
				erA=eR/42.5 > minerr *sqrt(2)
				erAx=errx/42.5 > minerr
				erAy=erry/42.5 > minerr
				ai=image(hist_equal(ai_image),xs,ys,title='HST PID '+string1i(im[ais[b]].proposal),axis_style=2,layout=[2,1,1],dimensions=[1000,500],buffer=buffer)
				ai.yrange=lines[-1]+[-105,105] > ymin
				ai.xrange=samples[-1]+[-105,105] > xmin

				lyc=lines[-1]-145/2
				lxc=samples[-1]-145/2
				lys=(lxs=145)
				large_x=lxc+[0,0,lxs,lxs,0]
				large_y=lyc+[0,lys,lys,0,0]
				large_box=polygon(large_x,large_y,color='RED',/data,FILL_TRANSPARENCY=90,transparency=25,thick=11)

				tyc=bigboxlines[-1]-bigbox/2
				txc=bigboxsamples[-1]-bigbox/2
				txs=(tys=bigbox)
				targ_x=txc+[0,0,txs,txs,0]
				targ_y=tyc+[0,tys,tys,0,0]
				targ_box=polygon(targ_x,targ_y,color='BLUE',/data,FILL_TRANSPARENCY=99,transparency=25,thick=4)

				cyc=lines[-1]-checkbox_size/2
				cxc=samples[-1]-checkbox_size/2
				cxs=(cys=checkbox_size)
				check_x=cxc+[0,0,cxs,cxs,0]
				check_y=cyc+[0,cys,cys,0,0]
				check_box=polygon(check_x,check_y,color='GREEN',/data,FILL_TRANSPARENCY=99,transparency=25,thick=3)

				erpA=plot(snbigbox,erA,xtitle='SN = Sqrt(All Counts in box)',ytitle='Error in R (")',ylog=1,layout=[2,1,2],/current,$
					xrange=[0,80],title=this_aperture+'+'+this_mirror+' : '+target,name=sbigbox+'x'+sbigbox+' box SN',color='DARK BLUE',$
					yrange=[0.01,15],buffer=buffer)
				erpA=plot(sn9,erA,/overplot,color='PURPLE',name='9x9 checkbox SN')
				l=legend(shadow=0,/auto_text_color,linestyle=6,font_name='TIMES',position=[55,10],/data)
				oplot=plot(erpA.xrange,[0.106,0.106],linestyle=1,color=fuv_color,/overplot,thick=2)
				oplot=plot(erpA.xrange,[0.041,0.041],linestyle=1,color=nuv_color,/overplot,thick=2)
				fuv=text(30,0.128,'FUV Requirement',color=fuv_color,/data,font_name='Times',target=erpA)
				nuv=text(30,0.05,'NUV Requirement',color=nuv_color,/data,font_name='Times',target=erpA)
				ai.save,pngdir+'AI_'+this_aperture+'_'+this_mirror+'_'+target+'_'+sbigbox+'_'+string1i(b)+'.png'
				linterp,snbigbox,erA,final_sn,this_sn_erA		&	running_errRA[b,*]=this_sn_erA > minerr
				linterp,snbigbox,erAx,final_sn,this_sn_erAx		&	running_errxA[b,*]=this_sn_erAx > minerr
				linterp,snbigbox,erAy,final_sn,this_sn_erAy		&	running_erryA[b,*]=this_sn_erAy > minerr

				linterp,sn9,erA,final_sn,this_sn9_erA		&	running_errRA9[b,*]=this_sn9_erA > minerr
				linterp,sn9,erAx,final_sn,this_sn9_erAx		&	running_errxA9[b,*]=this_sn9_erAx > minerr
				linterp,sn9,erAy,final_sn,this_sn9_erAy		&	running_erryA9[b,*]=this_sn9_erAy > minerr
			skipit:
			if debug then stop
			endfor
			for b=0,nsn-1 do begin
				final_errRA[combo,b]=median(running_errRA[*,b])
				final_errxA[combo,b]=median(running_errxA[*,b])
				final_erryA[combo,b]=median(running_erryA[*,b])

				final_errRA9[combo,b]=median(running_errRA9[*,b])
				final_errxA9[combo,b]=median(running_errxA9[*,b])
				final_erryA9[combo,b]=median(running_erryA9[*,b])

				mfinal_errRA[combo,b]=mean(running_errRA[*,b])
				mfinal_errxA[combo,b]=mean(running_errxA[*,b])
				mfinal_erryA[combo,b]=mean(running_erryA[*,b])

				mfinal_errRA9[combo,b]=mean(running_errRA9[*,b])
				mfinal_errxA9[combo,b]=mean(running_errxA9[*,b])
				mfinal_erryA9[combo,b]=mean(running_erryA9[*,b])

				final_sdvRA[combo,b]=stdev(running_errRA[*,b])
				final_sdvxA[combo,b]=stdev(running_errxA[*,b])
				final_sdvyA[combo,b]=stdev(running_erryA[*,b])

				final_sdvRA9[combo,b]=stdev(running_errRA9[*,b])
				final_sdvxA9[combo,b]=stdev(running_errxA9[*,b])
				final_sdvyA9[combo,b]=stdev(running_erryA9[*,b])
			endfor
			pbig=plot(final_sn,final_errRA[combo,*] > minerr,title=this_aperture+'/'+this_mirror+' ('+sactual_nimages+')',xtitle='S/N (Target)',ytitle='Centering Error (") for target with!Cinitial offset of R<0.45"',/ylog,font_name='Times',font_size=16,margin=0.15,dimensions=[800,800],buffer=buffer)
			pbig.save,pngdir+'LowSN_'+this_aperture+'_'+this_mirror+'_centering_'+sbigbox+'.png'
			p9=plot(final_sn,final_errRA9[combo,*] > minerr,title=this_aperture+'/'+this_mirror+' ('+sactual_nimages+')',xtitle='S/N (Target)',ytitle='Centering Error (") for target with!Cinitial offset of R<0.45"',/ylog,font_name='Times',font_size=16,margin=0.15,dimensions=[800,800],buffer=buffer)
			p9.save,pngdir+'LowSN_'+this_aperture+'_'+this_mirror+'_centering_'+scheckbox+'.png'
			actual_actual_nimages[combo]=actual_nimage
			if debug then stop
			combo++
			close_gwin
		endfor ; mirror
	endfor ; aperture

		save,file=datdir+savefile,final_sn,apertures,mirrors,actual_actual_nimages,actual_nimages,$
			final_errRA,final_erryA,final_errxA,final_errRA9,final_erryA9,final_errxA9,$
			mfinal_errRA,mfinal_erryA,mfinal_errxA,mfinal_errRA9,mfinal_erryA9,mfinal_errxA9,$
			final_sdvRA,final_sdvyA,final_sdvxA,final_sdvRA9,final_sdvyA9,final_sdvxA9

	endif else begin
		restore,datdir+savefile,verbose=verbose
	endelse
	; full bigboxes

	pbR=plot(final_sn,final_errRA[0,*] > minerr,title='Accuracy of ACQ/IMAGEs',xtitle='Signal/Noise ($\sqrt$counts of Unvignetted Target)',$
		name=apertures[0]+'+'+mirrors[0]+' ('+string1i(actual_nimages[0])+')',color=colors[0],$
		ytitle='Point Source Centering Error (")',/ylog,font_name='Times',font_size=18,margin=[0.18,0.08,0.08,0.08],dimensions=[800,800],thick=3)
	pbN=plot(final_sn,final_errRA[1,*] > minerr,name=apertures[0]+'+'+mirrors[1]+' ('+string1i(actual_nimages[1])+')',color=colors[1],/overplot,thick=3)
	pbN=plot(final_sn,final_errRA[2,*] > minerr,name=apertures[1]+'+'+mirrors[0]+' ('+string1i(actual_nimages[2])+')',color=colors[2],/overplot,thick=3)
	pbN=plot(final_sn,final_errRA[3,*] > minerr,name=apertures[1]+'+'+mirrors[1]+' ('+string1i(actual_nimages[3])+')',color=colors[3],/overplot,thick=3)
	pbR.xrange=[0,60]
	pbR.yrange=[0.01,20]
	l=legend(font_name='Times',shadow=0,linestyle=6,position=[50,10],/data,font_size=16,/AUTO_TEXT_COLOR)
	oplot=plot(pbR.xrange,[0.106,0.106],linestyle=1,color=fuv_color,/overplot,thick=2)
	oplot=plot(pbR.xrange,[0.041,0.041],linestyle=1,color=nuv_color,/overplot,thick=2)
	fuv=text(30,0.128,'FUV Requirement',color=fuv_color,/data,font_name='Times',target=pbR)
	nuv=text(30,0.05,'NUV Requirement',color=nuv_color,/data,font_name='Times',target=pbR)
	pbR.save,pngdir+'LowSN_ALL_centering_R.png'

	pbX=plot(final_sn,final_errxA[0,*] > minerr,title='Accuracy of ACQ/IMAGEs',xtitle='Signal/Noise ($\sqrt$counts of Unvignetted Target)',$
		name=apertures[0]+'+'+mirrors[0]+' ('+string1i(actual_nimages[0])+')',color=colors[0],$
		ytitle='Point Source Centering Error (AD, ")',/ylog,font_name='Times',font_size=18,margin=[0.18,0.08,0.08,0.08],dimensions=[800,800],thick=3)
	pbN=plot(final_sn,final_errxA[1,*] > minerr,name=apertures[0]+'+'+mirrors[1]+' ('+string1i(actual_nimages[1])+')',color=colors[1],/overplot,thick=3)
	pbN=plot(final_sn,final_errxA[2,*] > minerr,name=apertures[1]+'+'+mirrors[0]+' ('+string1i(actual_nimages[2])+')',color=colors[2],/overplot,thick=3)
	pbN=plot(final_sn,final_errxA[3,*] > minerr,name=apertures[1]+'+'+mirrors[1]+' ('+string1i(actual_nimages[3])+')',color=colors[3],/overplot,thick=3)
	pbX.xrange=[0,60]
	pbX.yrange=[0.01,20]
	l=legend(font_name='Times',shadow=0,linestyle=6,position=[50,10],/data,font_size=16,/AUTO_TEXT_COLOR)

	oplot=plot(pbX.xrange,[0.106,0.106],linestyle=1,color=fuv_color,/overplot,thick=2)
	oplot=plot(pbX.xrange,[0.041,0.041],linestyle=1,color=nuv_color,/overplot,thick=2)
	fuv=text(30,0.128,'FUV Requirement',color=fuv_color,/data,font_name='Times',target=bpX)
	nuv=text(30,0.05,'NUV Requirement',color=nuv_color,/data,font_name='Times',target=bpX)

	pbX.save,pngdir+'LowSN_ALL_centering_AD.png'

	pbY=plot(final_sn,final_erryA[0,*] > minerr,title='Accuracy of ACQ/IMAGEs',xtitle='Signal/Noise ($\sqrt$counts of Unvignetted Target)',$
		name=apertures[0]+'+'+mirrors[0]+' ('+string1i(actual_nimages[0])+')',color=colors[0],$
		ytitle='Point Source Centering Error (XD, ")',/ylog,font_name='Times',font_size=18,margin=[0.18,0.08,0.08,0.08],dimensions=[800,800],thick=3)
	pbN=plot(final_sn,final_erryA[1,*] > minerr,name=apertures[0]+'+'+mirrors[1]+' ('+string1i(actual_nimages[1])+')',color=colors[1],/overplot,thick=3)
	pbN=plot(final_sn,final_erryA[2,*] > minerr,name=apertures[1]+'+'+mirrors[0]+' ('+string1i(actual_nimages[2])+')',color=colors[2],/overplot,thick=3)
	pbN=plot(final_sn,final_erryA[3,*] > minerr,name=apertures[1]+'+'+mirrors[1]+' ('+string1i(actual_nimages[3])+')',color=colors[3],/overplot,thick=3)
	pbY.xrange=[0,60]
	pbY.yrange=[0.01,20]
	l=legend(font_name='Times',shadow=0,linestyle=6,position=[50,1],/data,font_size=16,/AUTO_TEXT_COLOR)

	oplot=plot(pbY.xrange,[0.106,0.106],linestyle=1,color=fuv_color,/overplot,thick=2)
	oplot=plot(pbY.xrange,[0.041,0.041],linestyle=1,color=nuv_color,/overplot,thick=2)
	fuv=text(30,0.128,'FUV Requirement',color=fuv_color,/data,font_name='Times',target=pbY)
	nuv=text(30,0.05,'NUV Requirement',color=nuv_color,/data,font_name='Times',target=pbY)

	pbY.save,pngdir+'LowSN_ALL_centering_XD.png'

 	; 9 checkboxes

	xt='Signal/Noise ($\sqrt$counts of Unvignetted Target, 9x9 box)'
	pbR=plot(final_sn,final_errRA9[0,*] > minerr,title='Accuracy of ACQ/IMAGEs',xtitle=xt,$
		name=apertures[0]+'+'+mirrors[0]+' ('+string1i(actual_nimages[0])+')',color=colors[0],$
		ytitle='Point Source Centering Error (")',/ylog,font_name='Times',font_size=18,margin=[0.18,0.08,0.08,0.08],dimensions=[800,800],thick=3)
	pbN=plot(final_sn,final_errRA9[1,*] > minerr,name=apertures[0]+'+'+mirrors[1]+' ('+string1i(actual_nimages[1])+')',color=colors[1],/overplot,thick=3)
	pbN=plot(final_sn,final_errRA9[2,*] > minerr,name=apertures[1]+'+'+mirrors[0]+' ('+string1i(actual_nimages[2])+')',color=colors[2],/overplot,thick=3)
	pbN=plot(final_sn,final_errRA9[3,*] > minerr,name=apertures[1]+'+'+mirrors[1]+' ('+string1i(actual_nimages[3])+')',color=colors[3],/overplot,thick=3)
	pbR.xrange=[0,60]
	pbR.yrange=[0.01,20]
	l=legend(font_name='Times',shadow=0,linestyle=6,position=[50,10],/data,font_size=16,/AUTO_TEXT_COLOR)
	oplot=plot(pbR.xrange,[0.106,0.106],linestyle=1,color=fuv_color,/overplot,thick=2)
	oplot=plot(pbR.xrange,[0.041,0.041],linestyle=1,color=nuv_color,/overplot,thick=2)
	fuv=text(30,0.128,'FUV Requirement',color=fuv_color,/data,font_name='Times',target=pbR)
	nuv=text(30,0.05,'NUV Requirement',color=nuv_color,/data,font_name='Times',target=pbR)
	pbR.save,pngdir+'LowSN_ALL_centering_R9.png'

	pbX=plot(final_sn,final_errxA9[0,*] > minerr,title='Accuracy of ACQ/IMAGEs',xtitle=xt,$
		name=apertures[0]+'+'+mirrors[0]+' ('+string1i(actual_nimages[0])+')',color=colors[0],$
		ytitle='Point Source Centering Error (AD, ")',/ylog,font_name='Times',font_size=18,margin=[0.18,0.08,0.08,0.08],dimensions=[800,800],thick=3)
	pbN=plot(final_sn,final_errxA9[1,*] > minerr,name=apertures[0]+'+'+mirrors[1]+' ('+string1i(actual_nimages[1])+')',color=colors[1],/overplot,thick=3)
	pbN=plot(final_sn,final_errxA9[2,*] > minerr,name=apertures[1]+'+'+mirrors[0]+' ('+string1i(actual_nimages[2])+')',color=colors[2],/overplot,thick=3)
	pbN=plot(final_sn,final_errxA9[3,*] > minerr,name=apertures[1]+'+'+mirrors[1]+' ('+string1i(actual_nimages[3])+')',color=colors[3],/overplot,thick=3)
	pbX.xrange=[0,60]
	pbX.yrange=[0.01,20]
	l=legend(font_name='Times',shadow=0,linestyle=6,position=[50,10],/data,font_size=16,/AUTO_TEXT_COLOR)

	oplot=plot(pbX.xrange,[0.106,0.106],linestyle=1,color=fuv_color,/overplot,thick=2)
	oplot=plot(pbX.xrange,[0.041,0.041],linestyle=1,color=nuv_color,/overplot,thick=2)
	fuv=text(30,0.128,'FUV Requirement',color=fuv_color,/data,font_name='Times',target=bpX)
	nuv=text(30,0.05,'NUV Requirement',color=nuv_color,/data,font_name='Times',target=bpX)

	pbX.save,pngdir+'LowSN_ALL_centering_AD9.png'

	pbY=plot(final_sn,final_erryA9[0,*] > minerr,title='Accuracy of ACQ/IMAGEs',xtitle=xt,$
		name=apertures[0]+'+'+mirrors[0]+' ('+string1i(actual_nimages[0])+')',color=colors[0],$
		ytitle='Point Source Centering Error (XD, ")',/ylog,font_name='Times',font_size=18,margin=[0.18,0.08,0.08,0.08],dimensions=[800,800],thick=3)
	pbN=plot(final_sn,final_erryA9[1,*] > minerr,name=apertures[0]+'+'+mirrors[1]+' ('+string1i(actual_nimages[1])+')',color=colors[1],/overplot,thick=3)
	pbN=plot(final_sn,final_erryA9[2,*] > minerr,name=apertures[1]+'+'+mirrors[0]+' ('+string1i(actual_nimages[2])+')',color=colors[2],/overplot,thick=3)
	pbN=plot(final_sn,final_erryA9[3,*] > minerr,name=apertures[1]+'+'+mirrors[1]+' ('+string1i(actual_nimages[3])+')',color=colors[3],/overplot,thick=3)
	pbY.xrange=[0,60]
	pbY.yrange=[0.01,20]
	l=legend(font_name='Times',shadow=0,linestyle=6,position=[50,1],/data,font_size=16,/AUTO_TEXT_COLOR)

	oplot=plot(pbY.xrange,[0.106,0.106],linestyle=1,color=fuv_color,/overplot,thick=2)
	oplot=plot(pbY.xrange,[0.041,0.041],linestyle=1,color=nuv_color,/overplot,thick=2)
	fuv=text(30,0.128,'FUV Requirement',color=fuv_color,/data,font_name='Times',target=pbY)
	nuv=text(30,0.05,'NUV Requirement',color=nuv_color,/data,font_name='Times',target=pbY)

	pbY.save,pngdir+'LowSN_ALL_centering_XD9.png'

	if debug then stop
end
