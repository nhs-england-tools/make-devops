slack-send-standard-notification: ### Send standard notification - mandatory: NAME=[notification template name],SLACK_WEBHOOK_URL
	make slack-send-notification FILE=$(LIB_DIR)/slack/$(NAME).json

slack-send-notification: ### Send notification based on a template - mandatory: FILE=[template file],SLACK_WEBHOOK_URL
	message=$$(make slack-render-template FILE=$(FILE))
	curl --request POST --header "Content-type: application/json" --data "$$message" $(SLACK_WEBHOOK_URL)

slack-render-template: ### Render message content from a template - mandatory: FILE=[template file]
	make -s file-copy-and-replace SRC=$(FILE) DEST=$(TMP_DIR)/$(@).json > /dev/null 2>&1 && trap "{ rm -f $(TMP_DIR)/$(@).json; }" EXIT
	file=$$(cat $(TMP_DIR)/$(@).json)
	echo $$file

.SILENT: \
	slack-render-template
