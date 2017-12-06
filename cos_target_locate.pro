pro cos_target_locate,image,sample,line,type=type,boxsize=boxsize,area=area, $
	threshold=threshold,xoff=xoff,yoff=yoff,totbox=totbox,outbox=outbox,in9box=in9box,$
	total_counts=total_counts,extracted_box=extracted_box,user=user
;+
;				cos_target_locate
;
; Routine to simulate COS on-board target acquisition (target locate)
; Modified version of stis_target_locate
;
; CALLING SEQUENCE:
;	cos_target_locate,image,sample,line
;
; INPUTS:
;	image - image on cos plate scale
;
; OUTPUTS:
;	sample - sample position of target position (This is the column number, X)
;	line - line position of target position (This is row number, Y)
;
; OPTIONAL KEYWORD INPUTS:
;	type - target acquisition type (character string, case insensitive with
;		at least the first two characters of the following choices:
;		CENTROID (default), GEOMETRIC CENTER, THRESHOLD CENTROID,
;		or CROWDED FIELD
;	boxsize - check box size (default = 3), must be an odd number
;	area - target area in pixels (must be specfied for type =
;		'THRESHOLD CENTROID')
;	threshold - crowded field threshold, must be specified for
;		type = 'CROWDED FIELD'
;	xoff - 3 element vector giving sample offsets for crowded field
;		offset targets
;	yoff - 3 element vector giving line offsets for crowded field
;		offset targets
;	user - set this to indicate that the image is in COS USER coordinates
;		   this is only important in case of "ties" for the maximum count box
;		   in cos_target_locate_checkbox
;
; OPERATIONAL NOTES:
;	if !DUMP is greater than 1, the routine prints the results
;
; HISTORY
;	version 1 D. Lindler, May, 1996
;	version 1.1	S.Penton	Nov., 2017 - Added USER keyword and some comments
;-
;-----------------------------------------------------------------------------
;
; print calling sequence if no parameters supplied
;
	if n_params(0) lt 1 then begin
		print,'CALLING SEQUENCE: cos_target_locate,image,sample,line'
		print,'INPUTS:         image - image on cos plate scale'
		print,'OUTPUTS:        line(Y), sample(X) - found target position'
		print,'KEYWORD INPUTS: type - acq. type (at least 2 char of):'
		print,'                         "CENTROID"  (default)'
		print,'                         "GEOMETRIC CENTER"'
		print,'                         "THRESHOLDED CENTROID"'
		print,'                         "CROWDED FIELD"'
		print,'                         "FWF"'
		print,'                boxsize - default=9'
		print,'                area - required for THRESHOLDED CENTROID'
		print,'                xoff,yoff - three crowded field offsets'
		print,'                threshold - crowded field threshold'
		print,'                user - set this if image is in COS USER coordinates'
		return
	end
;
; set defaults and check input parameters
;
	if n_elements(type) eq 0 then type = 'Centroid'
	if n_elements(user) ne 1 then user=0 ; By default, images are assumed to be in COS detector coordinates.
	if n_elements(boxsize) eq 0 then boxsize = 9

	ltype = strupcase(strmid(type,0,2))

	if ltype eq 'CR' then begin		;crowded field
	    if (n_elements(threshold) ne 1) or $
	       (n_elements(xoff) ne 3) or $
	       (n_elements(yoff) ne 3) then begin
		    print,'cos_target_locate: Error in crowded field parameters'
		    print,'XOFF, YOFF must be supplied as 3 element vectors and'
		    print,'crowded_threshold must be supplied as a scalar'
		    retall
	     endif
	end

	if ltype eq 'TH' then begin
	    if n_elements(area) eq 0 then begin
		    print,'cos_target_locate: Error, AREA must be suplied for a' + $
				'Threshold Centroid acquisition'
		    retall
	    end
	end
;
; consider only positive values in the image
;
	pimage = float(image>0)
;
; Perform one of four locate methods
;
;  GE - geometric center (center of the checkbox with largest flux)
;  CE - centroid (flux weighted centroid of checkbox with largest flux)
;  TH - threshold centroid of checkbox using specified area
;  CR - crowded field (3 offset stars XOFF,YOFF)
; FWF - Same as CE, but subtract the lowest value
;
	case ltype of
;
; Geometric center of checkbox
;
	    'GE' : begin
		   cos_target_locate_checkbox,image,boxsize,sample,line,extracted_box,user=user
		   ;;if !dump gt 1 then print,'GEOMETRIC CENTER =',sample,line
		   end
;
; Centroid of checkbox
;
	    'CE' : begin
				cos_target_locate_checkbox,image,boxsize,sample,line,extracted_box,user=user
				outbox=extracted_box
				;;if !dump gt 1 then print,'GEOMETRIC CENTER =',sample,line
				SPOS = lindgen(boxsize,boxsize) mod boxsize
				LPOS = lindgen(boxsize,boxsize)/boxsize
				totbox = total(extracted_box)
				hbox = boxsize/2.0
				line = uint(line) - uint(hbox) + double(ulong(total(uint(extracted_box)*uint(Lpos))))/ulong(totbox)
				sample = uint(sample) - uint(hbox) + double(ulong(total(uint(extracted_box)*uint(Spos))))/ulong(totbox)
				;;if !dump gt 1 then print,'       CENTROID  =',sample,line
		   end
;
; FWF Centroid of checkbox
;
	    'FWF' : begin
				cos_target_locate_checkbox,image,boxsize,sample,line,extracted_box,user=user
				outbox=extracted_box
				extracted_box-=(min(extracted_box))
				;;if !dump gt 1 then print,'GEOMETRIC CENTER =',sample,line
				SPOS = lindgen(boxsize,boxsize) mod boxsize
				LPOS = lindgen(boxsize,boxsize)/boxsize
				totbox = total(extracted_box)
				hbox = boxsize/2
				line = line - hbox + total(extracted_box*Lpos)/totbox
				sample = sample - hbox + total(extracted_box*Spos)/totbox
				;;if !dump gt 1 then print,'       CENTROID  =',sample,line
		   end
;
; Thresholded Centroid
;
	    'TH' : begin
				cos_target_locate_checkbox,image,boxsize,sample,line,extracted_box,user=user
				outbox=extracted_box
				;if !dump gt 1 then print,'  GEOMETRIC CENTER =',sample,line
				   find_thresh,extracted_box,area,thresh
				;if !dump gt 1 then print,'COMPUTED THRESHOLD =',thresh
				extracted_box = extracted_box ge thresh
				SPOS = lindgen(boxsize,boxsize) mod boxsize
				LPOS = lindgen(boxsize,boxsize)/boxsize
				totbox = total(extracted_box)
				hbox = boxsize/2
				line = line - hbox + total(extracted_box*Lpos)/totbox
				sample = sample - hbox + total(extracted_box*Spos)/totbox
				;if !dump gt 1 then print,'THESHOLDED CENTROID =',sample,line
		   end
;
; Crowded Field
;
	    'CR' : begin
		   cos_target_locate_crowd,image,xoff,yoff,threshold, $
				sample,line,csize=boxsize,/centroid
				extracted_box=image
		   ;if !dump gt 1 then print,'TARGET POSITION = ',sample,line
		   end
	endcase
	total_counts=total(image)
	in9box=total(extracted_box)
end
