pro cos_target_locate_crowd,image,xoff,yoff,thresh,x,y,csize=csize, centroid=centroid
;+
;			crowd
;
; Crowded field algorithm
;
; CALLING SEQUENCE:
;
;	cos_target_locate_crowd,image,xoff,yoff,thresh,x,y
;
; INPUTS:
;	image - target acquisition image
;	xoff - x offsets field stars
;	yoff - y offsets field stars
;	thresh - detection threshold
; OPTIONAL KEYWORD INPUTS:
;	csize - size of checking box (default = 3)
;	centroid - centroid refinement of central position
; OUTPUTS:
;	x,y - computed center position
;
; HISTORY:
;	version 1.0  D. Lindler & T. Beck, May, 1996
;	version 1.1  S. Penton - direct conversion by just adding cos_ to the name
;					This has no real application to COS, but it is present in cos_target_locate.pro
;
;-
;---------------------------------------------------------------------
	if n_params(0) lt 1 then begin
	    print,'CALLING SEQUENCE: cos_target_locate_crowd,image,xoff,yoff,thresh,x,y'
	    print,'Optional Keyword inputs: CSIZE, /CENTROID'
	    retall
	endif
;
; set defaults
;
	if keyword_set(centroid) then centroid=1 else centroid = 0
	if n_elements(csize) eq 0 then csize=3
	noff = n_elements(xoff)
	s = size(image) & nx=s(1) & ny=s(2)	;size of image
;
; Round offsets
;
	xintoff = fix(xoff + 1000.5)-1000
	yintoff = fix(yoff + 1000.5)-1000
;
; Compute total in boxes with size csize at each pixel
;
	if csize gt 1 then timage = smooth(image,csize)*csize*csize $
		      else timage = image
;
; find points above threshold
;
	above = timage ge thresh
;
; initalize best position
;
	maxtot = 0.0
	maxcount = 0
;
; loop on possible centers
;
	for iy = 0,ny-1 do begin
	    for ix = 0,nx-1 do begin
;
; check each offset
;
		tot = 0.0		;total counts in "checking" boxes
		count = 0		;number of detections
		for i=0,noff-1 do begin
		    iyoff = iy+yintoff(i)
		    ixoff = ix+xintoff(i)
		    if ((iyoff ge 0) and (iyoff lt ny)) and $
		       ((ixoff ge 0) and (ixoff lt nx)) then begin
		    	    if above(ixoff,iyoff) gt 0 then begin
				    tot = tot + timage(ixoff,iyoff)
				    count = count + 1
			    end
		    end
		end
;
; Is it a better position
;
		if (count eq maxcount and tot gt maxtot) or $
		    count gt maxcount then begin   ;better position?
			    x = ix
			    y = iy
			    maxtot = tot
		 	    maxcount = count
		endif
	    end
	end
;
; Did we find a match
;
	if maxcount lt 2 then begin
		x = -999
		y = -999
		!err = -1
		return			;we failed
	endif
;
; Routine for computing position to a fraction of a pixel by centroiding.
;
        if centroid eq 1 then begin
		xcentroids = fltarr(maxcount)
		ycentroids = fltarr(maxcount)
		ncentroids = 0
		half_csize = csize/2
;
; compute centroid for each offset (if star was found)
;
		for i=0,noff-1 do begin
		    ixpos = x + xintoff(i)
		    iypos = y + yintoff(i)

;
; find region to centroid
;
		    if above(ixpos,iypos) then begin
			s1 = (ixpos - half_csize) > 0
			s2 = (ixpos + half_csize) < (nx-1)
			l1 = (iypos - half_csize) > 0
			l2 = (iypos + half_csize) < (ny-1)
			box = image(s1:s2,l1:l2)	;box to centroid
			centroid,box,xc,yc
			xc = xc+s1			;offset for start of box
			yc = yc+l1
;
; determine target position from the centroid (subtract floating point offset)
;
			xcentroids(ncentroids) = xc - xoff(i)
			ycentroids(ncentroids) = yc - yoff(i)
			ncentroids = ncentroids + 1
		    end
		end
;
; determine median centroid (average if only two found)
;
		if maxcount gt 2 then begin
			x = median(xcentroids)
			y = median(ycentroids)
		   end else begin
			x = total(xcentroids)/2.0
			y = total(ycentroids)/2.0
		end
	end
	!err = 1	;success
return
end
