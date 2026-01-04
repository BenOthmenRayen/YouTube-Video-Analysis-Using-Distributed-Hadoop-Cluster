#!/usr/bin/env python3
import os
import json
import yaml
import time
import subprocess
from googleapiclient.discovery import build
from hdfs import InsecureClient
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class YouTubeVideoFetcher:
    def __init__(self, config_path='config.yaml'):
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)
        
        self.api_key = self.config['api_key']
        self.youtube = build('youtube', 'v3', developerKey=self.api_key)
        self.hdfs_client = InsecureClient(
            self.config['hdfs']['url'], 
            user=self.config['hdfs']['user']
        )
        logger.info("YouTube Video Fetcher initialized")
    
    def search_videos(self, query, max_results=2):
        logger.info(f"Searching YouTube for: {query}")
        try:
            request = self.youtube.search().list(
                part='snippet',
                q=query,
                type='video',
                maxResults=max_results,
                videoDuration='short',
                order='viewCount'
            )
            response = request.execute()
            video_ids = [item['id']['videoId'] for item in response['items']]
            logger.info(f"Found {len(video_ids)} videos")
            return video_ids
        except Exception as e:
            logger.error(f"YouTube API error: {e}")
            return []
    
    def get_video_info(self, video_id):
        try:
            request = self.youtube.videos().list(
                part='snippet,contentDetails,statistics',
                id=video_id
            )
            response = request.execute()
            
            if not response['items']:
                return None
            
            item = response['items'][0]
            snippet = item['snippet']
            stats = item.get('statistics', {})
            
            metadata = {
                'video_id': video_id,
                'title': snippet['title'],
                'author': snippet['channelTitle'],
                'description': snippet['description'][:500],
                'publish_date': snippet['publishedAt'],
                'thumbnail_url': snippet['thumbnails']['high']['url'],
                'views': stats.get('viewCount', 0),
                'likes': stats.get('likeCount', 0),
                'tags': snippet.get('tags', [])[:10]
            }
            return metadata
        except Exception as e:
            logger.error(f"Error getting video info for {video_id}: {e}")
            return None
    
    def download_video(self, video_id, output_path='/tmp'):
        try:
            video_url = f'https://www.youtube.com/watch?v={video_id}'
            output_file = f'{output_path}/{video_id}.mp4'
            
            logger.info(f"Downloading video: {video_id}")
            
            # Use yt-dlp command
            cmd = [
                'yt-dlp',
                '-f', 'worst[ext=mp4]',  # Download lowest quality to save space
                '-o', output_file,
                '--no-playlist',
                '--quiet',
                '--no-warnings',
                video_url
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0 and os.path.exists(output_file):
                logger.info(f"Downloaded to: {output_file}")
                return output_file
            else:
                logger.error(f"Download failed: {result.stderr}")
                return None
                
        except Exception as e:
            logger.error(f"Error downloading {video_id}: {e}")
            return None
    
    def upload_to_hdfs(self, local_path, hdfs_path):
        try:
            logger.info(f"Uploading to HDFS: {hdfs_path}")
            parent_dir = '/'.join(hdfs_path.split('/')[:-1])
            try:
                self.hdfs_client.makedirs(parent_dir)
            except:
                pass
            self.hdfs_client.upload(hdfs_path, local_path, overwrite=True)
            logger.info(f"✓ Uploaded successfully")
            return True
        except Exception as e:
            logger.error(f"HDFS upload error: {e}")
            return False
    
    def process_videos(self):
        queries = self.config['search']['queries']
        max_per_query = self.config['search']['max_results_per_query']
        total_processed = 0
        
        for query in queries:
            logger.info(f"\n{'='*60}")
            logger.info(f"Processing query: {query}")
            logger.info(f"{'='*60}")
            video_ids = self.search_videos(query, max_per_query)
            
            for video_id in video_ids:
                logger.info(f"\n--- Processing video: {video_id} ---")
                
                # Get metadata
                metadata = self.get_video_info(video_id)
                if not metadata:
                    logger.warning(f"Skipping {video_id} - no metadata")
                    continue
                
                logger.info(f"Title: {metadata['title']}")
                
                # Save metadata to HDFS
                meta_path = f"/youtube/metadata/{video_id}.json"
                meta_local = f'/tmp/{video_id}_metadata.json'
                
                with open(meta_local, 'w') as f:
                    json.dump(metadata, f, indent=2)
                
                self.upload_to_hdfs(meta_local, meta_path)
                os.remove(meta_local)
                
                # Download video
                local_file = self.download_video(video_id)
                
                if local_file:
                    # Upload to HDFS
                    hdfs_path = f'/youtube/videos/{video_id}.mp4'
                    success = self.upload_to_hdfs(local_file, hdfs_path)
                    
                    if success:
                        total_processed += 1
                        logger.info(f"✓ Video {video_id} processed successfully")
                    
                    # Cleanup
                    os.remove(local_file)
                else:
                    logger.warning(f"✗ Failed to download {video_id}")
                
                # Small delay
                time.sleep(2)
        
        logger.info(f"\n{'='*60}")
        logger.info(f"SUMMARY: Processed {total_processed} videos")
        logger.info(f"{'='*60}")

if __name__ == '__main__':
    try:
        fetcher = YouTubeVideoFetcher()
        fetcher.process_videos()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        import traceback
        traceback.print_exc()