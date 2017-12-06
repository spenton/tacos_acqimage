pro close_gwin
	wins=getWindows(names=getnames)
	foreach win, wins do win.close
end
