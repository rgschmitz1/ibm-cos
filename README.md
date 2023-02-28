# Purpose

Create container for IBM Cloud Object Stroage upload/download

# Build

The `build.sh` script will build a Docker image.

# Run

## Usage

```
Usage: ibm-cos.sh [OPTIONS]

Options:
  --credentials Filepath to apikey.json
  --region      Region (defaults to us-south)
  --bucket      Bucket to upload/download object
  --mode        Set to 'upload' or 'download' (defaults to 'upload')
  --key         Key of object to upload or download
  --object      Filepath to the object
  --download    Download directory path (defaults to /mnt/data)
  --crn         Cloud storage crn (cannot be used with --instance)
  --instance    Cloud storage instance name (cannot be used with --crn)
```

## Example Docker command

```
docker run --rm -v /mnt/data:/mnt/data biodepot/ibm-cos
	--credentials <path to apikey.json>
	--instance <insert instance name>
	--bucket <bucket name>
	--key <key name in IBM COS>
	--object <path to file to upload>
```
