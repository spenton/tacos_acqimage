pro cos_target_locate_checkbox,the_image,boxsize,Xcen,Ycen,extracted_max_box,maxcounts=maxcounts,forget_edges=forget_edges,user=user,debug=debug,verbose=verbose
;+
;	cos_target_locate_checkbox
;
;	This is based on D. Linders target_locate_checkbox from the CALSTIS IDL version
;
;	Simulate an ACQ/IMAGE by finding the checkbox in the_image with maximum flux (subroutine of cos_target_locate.pro)
;
; CALLING SEQUENCE:
;	cos_target_locate_checkbox,the_image,boxsize,Xcen,Ycen,box
;
; INPUTS:
;	the_image - input image on cos plate scale, normally this is a 145x145 COS image
;	        simulating the "small" box in LTAIMAGE, it is ok if it is bigger.
;	boxsize - checkbox size (this should be set to 9 for COS)
;	forget_edges - set this keyword to not consider the counts at the edge of the image
;					In the original version, this was the default, but for COS the FSW
;					does not do this, so it is turned off
;	user - set this keyword if the image is in COS USER coordinates, by default
;	       detector coordinates are assumed. This only comes into play if there
;	       is a tie between checkboxs with the maximum counts. The COS FSW takes
;	       the one closest to [X,Y]=[0,0] in detector coordinates.
;
; OUTPUTS:
;	Xcen - center line position of the checkbox with the largest flux
;	Ycen - center sample position of the checkbox with the largest flux
;	extracted_max_box - extracted checkbox with the largest flux (boxsize x boxsize)
;
; HISTORY:
;	version 1  	D. Lindler   May, 1996
;	version 1.1	S.Penton    June, 2001
;              Changed "line" and "sample" to "Ycen" and "Xcen"
;              Added the "forget_edges" keyword, and turned it off by default for COS
;	version 1.2	S. Penton   Nov, 2017
;	            Added the "USER" keyword and comments about the COS FSW.
;	            Added comments about which maximum checkbox is chosen in a tie.
;	            Added the /nan to the smooth call.
;	version 1.3	S. Penton, Dec 6, 2017
;               Added debug and verbose keywords
;-
;-----------------------------------------------------------------------------
;
if n_elements(forget_edges) ne 1 then forget_edges=1 ; set the COS default
if n_elements(debug) ne 1 then debug=0
if n_elements(verbose) ne 1 then verbose=0
if n_elements(user) ne 1 then user=0 ; Assume COS detector coordinates (NOT USER)
; Be careful as ACQ/IMAGEs return images in USER coordinates by default, but the
; COS FSW operates in detector coordinates. The transformation is simple:
; 			Xuser = 1023-Ydetector
; 			Yuser = 1023-Xdetector
;
; Get image size and 1/2 boxsize (hbox)
;
	s = size(the_image)
	ns = s[1]
	nl = s[2]
	hbox = boxsize/2 ; this works odd or even
;
; find total within each checkbox
;
	tots = smooth(float(the_image),boxsize,/nan) ; V1.2, added the /NAN
;
; Note that the for the IDL smooth function.
; If none of the EDGE_* keywords are set, the end points are copied from the original array to the result with no smoothing.
;
; don't consider the edges, the smoothing makes them larger than they should be
;
	if forget_edges then begin
			tots[0:hbox,*]=0
			tots[*,0:hbox]=0
			tots[ns-hbox:ns-1,*] = 0
			tots[*,nl-hbox:nl-1] = 0
	endif
;
; find position of maximum
;
	maxt = max(tots)
	index=where(tots eq maxt,count)
;
; In the case of a tie, return the one closest to [X,Y]=[0,0]
; IDL and the C FSW have the same indexing, Y first, then X, so
; the values here should match the FSW.
;
; In USER coordinates, return the one furthest from [0,0] as the
; coordinates have been flipped.
;
	cloc=(user ? index[0] : index[count-1])

	Xcen = cloc mod ns  ; Find X
	Ycen = cloc/ns      ; Find Y
;
; extract best checkbox
;
	if debug then begin
		help,the_image,Xcen,hbox,ns,Ycen,nl
	endif
	extracted_max_box = the_image[Xcen-hbox:Xcen+hbox < (ns-1),Ycen-hbox:Ycen+hbox < (nl-1)]

	maxcounts=maxt
end
