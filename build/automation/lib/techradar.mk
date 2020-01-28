techradar-inspect-image: ### Inspect Docker image - mandatory: NAME=[image name]
	hash=$$(make techradar-image-get-hash)
	created=$$(make techradar-image-get-created)
	size=$$(make techradar-image-get-size)
	base=$$(make techradar-image-get-base)
	tech=$$(make techradar-image-detect-tech)
	make techradar-report \
		TYPE=image \
		IMAGE_HASH="$$hash" \
		IMAGE_CREATED="$$created" \
		IMAGE_SIZE="$$size" \
		IMAGE_BASE="$$base" \
		IMAGE_TECH="$$tech"

techradar-report:
	# TODO: Call API and report on inspection

# ==============================================================================

techradar-image-get-hash:
	# TODO: Return image hash

techradar-image-get-created:
	# TODO: Return image creation datetime

techradar-image-get-size:
	# TODO: Return size in MBs

techradar-image-get-base:
	# TODO: Return image name, tag, hash, creation datetime, size in MBs (tuple)

techradar-image-detect-tech:
	# TODO: Return technology name and version
