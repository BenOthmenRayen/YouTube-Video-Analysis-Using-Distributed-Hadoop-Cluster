#!/usr/bin/env python3
"""
Mapper: Extract metadata from video files stored in HDFS
"""

import sys
import json
import subprocess

def extract_video_metadata(video_path):
    """Use ffprobe to extract video metadata"""
    cmd = [
        'ffprobe',
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        video_path
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout)
    except Exception as e:
        return {'error': str(e)}

def main():
    # Read HDFS file paths from stdin
    for line in sys.stdin:
        video_path = line.strip()
        
        if not video_path.endswith('.mp4'):
            continue
        
        # Extract video ID from path
        video_id = video_path.split('/')[-1].replace('.mp4', '')
        
        # Get metadata
        metadata = extract_video_metadata(video_path)
        
        # Emit: video_id \t metadata_json
        print(f"{video_id}\t{json.dumps(metadata)}")

if __name__ == '__main__':
    main()