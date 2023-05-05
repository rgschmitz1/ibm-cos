#!/bin/sh

# Upload/Download from IBM cloud object storage
#
# Author: Bob Schmitz
#
# History:
#   2023-02-21: Initial creation


API_KEY=''
REGION='us-south'
MODE='upload'
[ -z "$DOWNLOAD_DIR" ] && DOWNLOAD_DIR='/mnt/data'


# Display script usage
usage() {
	cat <<-USAGE
	Usage: $(basename $0) [OPTIONS]

	Options:
	  --credentials	Filepath to apikey.json
	  --region	Region (defaults to us-south)
	  --bucket	Bucket to upload/download object
	  --mode	Set to 'upload' or 'download' (defaults to '$MODE')
	  --key		Key of object to upload or download
	  --object	Filepath to the object
	  --download	Download directory path (defaults to $DOWNLOAD_DIR)
	  --crn		Cloud storage crn (cannot be used with --instance)
	  --instance	Cloud storage instance name (cannot be used with --crn)
	USAGE
}


# Colorized prompts
#
# Inputs
#   $1 - Status
#   $2 - Message
prompt() {
	local status=$1
	local msg="$2"

	# ASCII codes to colorize prompts
	local red='\033[0;31m'
	local cyan='\033[0;36m'
	local nc='\033[0m'

	case $status in
		info)
			printf "${cyan}${msg}${nc}\n"
		;;
		error)
			printf "${red}ERROR: ${msg}${nc}\n"
		;;
		*)
			prompt error 'WAT?!'
			exit 1
		;;
	esac
}


# Create a tar archive for uploading
create_archive_object() {
	prompt info "Creating $KEY.tar for upload"
	tar c -f $KEY.tar $(echo $OBJECT | tr ',' ' ')
	KEY+=.tar
	OBJECT=$KEY
	CLEANUP=$OBJECT
}


# Upload file to IBM cloud object storage
upload() {
	# Verify bucket exists otherwise create it here
	if ! ibmcloud cos bucket-head --bucket $BUCKET &> /dev/null; then
		prompt info "Creating bucket $BUCKET"
		if ! ibmcloud cos bucket-create --bucket $BUCKET; then
			prompt error "Failed to create bucket $BUCKET"
			exit 1
		fi
	fi

	# If object is comma seperated list, create a tar file before uploading
	echo $OBJECT | grep -q ',' && create_archive_object
	prompt info "Uploading $KEY to $BUCKET"
	ibmcloud cos object-put --bucket $BUCKET --key $KEY --body $OBJECT
	local ret=$?
	[ -n "$CLEANUP" ] && rm $CLEANUP
	return $ret
}


# Download file to IBM cloud object storage
download() {
	prompt info "Downloading $KEY from $BUCKET"
	ibmcloud cos object-get --bucket $BUCKET --key $KEY
	return $?
}


#------#
# Main #
#------#
while [ -n "$1" ]; do
	case $1 in
		--credentials)
			if [ ! -s "$2" ]; then
				prompt error 'Credentials file not found or is empty'
				exit 1
			fi
			API_KEY=$(awk '/apikey/ {print $2;exit}' $2 | tr -d '"')
			shift
			shift
		;;
		--region)
			REGION=$2
			shift
			shift
		;;
		--bucket)
			BUCKET=$2
			shift
			shift
		;;
		--mode)
			case $2 in
				upload|download)
					MODE=$2
				;;
				*)
					prompt error "Mode must be 'upload' or 'download'"
					exit 1
				;;
			esac
			shift
			shift
		;;
		--key)
			KEY=$2
			shift
			shift
		;;
		--object)
			OBJECT=$2
			shift
			shift
		;;
		--download)
			DOWNLOAD_DIR=$2
			shift
			shift
		;;
		--crn)
			CRN=$2
			shift
			shift
		;;
		--instance)
			INSTANCE_NAME=$2
			shift
			shift
		;;
		*)
			prompt error "Invalid argument '$1'\n"
			usage
			exit 1
		;;
	esac
done

# Check if API key is set
if [ -z "$API_KEY" ]; then
	prompt error "API key not found in credentials file"
	exit 1
fi

# Check if bucket is set
if [ -z "$BUCKET" ]; then
	prompt error "Bucket must be set using '--bucket' option"
	exit 1
fi

# Check if key is set
if [ -z "$KEY" ]; then
	prompt error "Key must be set using '--key' option"
	exit 1
fi

# If mode is upload, check that an object was passed
if [ "$MODE" = 'upload' ] && [ -z "$OBJECT" ]; then
	prompt error "Object must be set using '--object' option"
	exit 1
fi

# Login using ibmcloud cli
ibmcloud login --apikey $API_KEY -r $REGION || exit $?

# Set the download directory
ibmcloud cos config ddl --ddl $DOWNLOAD_DIR

# Use instance name to search for CRN
[ -n "$INSTANCE_NAME" ] &&
	CRN=$(ibmcloud resource service-instance "$INSTANCE_NAME" --id | awk 'END {print $NF}')

# Configure cloud object storage crn
if [ -n "$CRN" ]; then
	ibmcloud cos config crn --crn $CRN
	ibmcloud cos config crn --list
else
	prompt error 'Either --crn or --instance must be set'
	exit 1
fi

# Execute upload or download based on mode passed
$MODE && exit 0
prompt error "Failed to $MODE $KEY"
exit 1
