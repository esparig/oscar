#!/bin/bash
FILE_NAME=${INPUT_FILE_PATH##*/}
OUTPUT_FILE="$TMP_OUTPUT_DIR/$FILE_NAME"
#echo 'esto es una prueba'
#echo "SCRIPT: Invoked tts.py. File available in $INPUT_FILE_PATH"
#echo "SCRIPT: Invoked tts.py. FILE_NAME in $FILE_NAME"
#echo "SCRIPT: Invoked tts.py. OUTPUT_FILE $TMP_OUTPUT_DIR/"
#echo "SCRIPT: Invoked tts.py. lenguage $lenguage"
#echo "python3 /opt/tts.py --lenguage="$lenguage" -o "$OUTPUT_FILE" "$INPUT_FILE_PATH""
python3 /opt/tts.py --lenguage="$lenguage" -o "$OUTPUT_FILE" "$INPUT_FILE_PATH"
