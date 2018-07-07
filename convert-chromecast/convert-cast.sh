#!/bin/bash

SUPPORTED_EXTENSIONS=('mkv' 'avi' 'mp4' '3gp' 'mov' 'mpg' 'mpeg' 'qt' 'wmv' 'm2ts' 'flv')
SUPPORTED_VCODECS=('h264')
SUPPORTED_ACODECS=('aac' 'mp3')
SUPPORTED_VLEVELS=('30' '31' '40' '41')
SUPPORTED_VPROFILES=('Constrained Baseline', 'Baseline' 'Main' 'High')
SUPPORTED_EXTENSIONS=('mkv' 'avi' 'mp4' '3gp' 'mov' 'mpg' 'mpeg' 'qt' 'wmv' 'm2ts' 'flv')

probe() {
  av=$1
  key=$2
  path=$3
  ffprobe -v fatal -show_streams -select_streams $av "$path" \
    | grep "\<$key\>=" | awk -F'=' '{print $2}'
}

# Check if a value exists in an array
# @param $1 mixed  Needle  
# @param $2 array  Haystack
# @return  Success (0) if value exists, Failure (1) otherwise
# Usage: in_array "$needle" "${haystack[@]}"
# See: http://fvue.nl/wiki/Bash:_Check_if_array_element_exists
in_array() {
    local hay needle=$1
    shift
    for hay; do
        [[ $hay == $needle ]] && return 0
    done
    return 1
}

is_supported_ext() {
	EXT=`echo $1 | tr '[:upper:]' '[:lower:]'`
	in_array "$EXT" "${SUPPORTED_EXTENSIONS[@]}"
}

process_file() {
  FILENAME=$1
	BASENAME=$(basename "$FILENAME")
	EXTENSION="${BASENAME##*.}"
  TEMP_FILENAME="$FILENAME.$EXTENSION"

	if ! is_supported_ext "$EXTENSION"; then
		echo "$FILENAME not a video format, skipping"
		return
	fi

  NEED_CONVERT=false
  INPUT_VCODEC=$(probe v codec_name "$FILENAME")
  if in_array "$INPUT_VCODEC" "${SUPPORTED_VCODECS[@]}"; then
    OUTPUT_VCODEC="-vcodec copy"
  else
    OUTPUT_VCODEC="-vcodec libx264"
    NEED_CONVERT=true
    echo "$INPUT_VCODEC -> $OUTPUT_VCODEC"
  fi

  INPUT_ACODEC=$(probe a codec_name "$FILENAME")
  if in_array "$INPUT_ACODEC" "${SUPPORTED_ACODECS[@]}"; then
    OUTPUT_ACODEC="-acodec copy"
  else
    OUTPUT_ACODEC="-acodec libmp3lame"
    NEED_CONVERT=true
    echo "$INPUT_ACODEC -> $OUTPUT_ACODEC"
  fi

  INPUT_VLEVEL=$(probe v level "$FILENAME")
  if ! in_array "$INPUT_VLEVEL" "${SUPPORTED_VLEVELS[@]}"; then
    OUTPUT_VLEVEL="-vlevel 41"
    OUTPUT_VCODEC="-vcodec libx264"
    NEED_CONVERT=true
    echo "$INPUT_VLEVEL -> $OUTPUT_VLEVEL"
  fi

  #INPUT_VPROFILE=$(probe v profile "$FILENAME")
  #if ! in_array "$INPUT_VPROFILE" "${SUPPORTED_VPROFILES[@]}"; then
    #OUTPUT_VPROFILE="-profile:v high"
    #OUTPUT_VCODEC="-vcodec libx264"
    #NEED_CONVERT=true
    #echo "$INPUT_VPROFILE -> $OUTPUT_VPROFILE"
  #fi

  if ! $NEED_CONVERT; then
    echo "$FILENAME should be playable by chromecast"
    return
  fi
  echo "Transcoding $FILENAME with ffmpeg $OUTPUT_VCODEC $OUTPUT_ACODEC $OUTPUT_VLEVEL $OUTPUT_VPROFILE ..."
  ffmpeg -y -v info -i "$FILENAME" $OUTPUT_VCODEC $OUTPUT_ACODEC $OUTPUT_VLEVEL $OUTPUT_VPROFILE "$TEMP_FILENAME"
  if [ $? -eq 0 ]; then
    echo "Done transcoding! Deleting the temp file"
    rm "$FILENAME"
    mv "$TEMP_FILENAME" "$FILENAME"
  fi
}

for FILE in "$@"; do
  process_file "$FILE"
done
