#!/usr/bin/env python3
"""
Reducer: Aggregate and format video metadata
"""

import sys
import json

def main():
    current_video = None
    metadata_list = []
    
    for line in sys.stdin:
        video_id, metadata_json = line.strip().split('\t', 1)
        
        if current_video != video_id:
            if current_video:
                # Output aggregated result
                output = {
                    'video_id': current_video,
                    'metadata': metadata_list
                }
                print(json.dumps(output))
            
            current_video = video_id
            metadata_list = []
        
        metadata_list.append(json.loads(metadata_json))
    
    # Output last video
    if current_video:
        output = {
            'video_id': current_video,
            'metadata': metadata_list
        }
        print(json.dumps(output))

if __name__ == '__main__':
    main()