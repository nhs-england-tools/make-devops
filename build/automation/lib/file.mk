file-remove-content: ### Remove multiline content from a given file - mandatory: FILE,CONTENT="// BEGIN: Content(.)*// END: Content"
	permissions=$$(stat -c %a $(FILE))
	str=$$(echo "$(CONTENT)" | sed 's/\//\\\//g')
	tmp_file=/tmp/$$(basename -- "$(FILE)").$$
	cat $(FILE) | perl -0777 -pe "s/$$str//gs" > $$tmp_file
	mv -f $$tmp_file $(FILE)
	chmod $$permissions $(FILE)
