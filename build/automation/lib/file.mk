file-remove-content: ### Remove multiline content from given file - mandatory: FILE,CONTENT="// BEGIN: Content(.)*// END: Content"
	permissions=$$(stat -c %a $(FILE))
	str=$$(echo "$(CONTENT)" | sed 's/\//\\\//g')
	tmp_file=/tmp/$$(basename -- "$(FILE)").$$
	cat $(FILE) | perl -0777 -pe "s/$$str//gs" > $$tmp_file
	mv -f $$tmp_file $(FILE)
	chmod $$permissions $(FILE)

file-replace-content: ### Replace multiline content from given file - mandatory: FILE,OLD="// BEGIN: Content(.)*// END: Content",NEW=[string]
	permissions=$$(stat -c %a $(FILE))
	str1=$$(echo "$(OLD)" | sed 's/\//\\\//g')
	str2=$$(echo "$(NEW)" | sed 's/\//\\\//g')
	tmp_file=/tmp/$$(basename -- "$(FILE)").$$
	cat $(FILE) | perl -0777 -pe "s/$$str1/$$str2/gs" > $$tmp_file
	mv -f $$tmp_file $(FILE)
	chmod $$permissions $(FILE)

file-replace-variables: ### Replace all variables in given file - mandatory: FILE
	echo "Replace variables in '$(FILE)'"
	for str in $$(cat $(FILE) | grep -Eo "[A-Za-z0-9_]*_TO_REPLACE" | sort | uniq); do
		key=$$(cut -d "=" -f1 <<<"$$str" | sed "s/_TO_REPLACE//g")
		value=$$(echo $$(eval echo "\$$$$key"))
		[ -z "$$value" ] && echo "WARNING: Variable $$key has no value in '$(FILE)'" || sed -i \
			"s;$${key}_TO_REPLACE;$${value//&/\\&};g" \
			$(FILE) ||:
	done
