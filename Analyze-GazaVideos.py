#!/usr/bin/env python3
"""
Gaza Videos Analysis - Analyze metadata from HDFS
"""

import json
import subprocess
from collections import Counter
from datetime import datetime
import re

class GazaVideoAnalyzer:
    def __init__(self):
        self.videos = []
        self.load_data()
    
    def load_data(self):
        """Load all metadata from HDFS"""
        print("Loading metadata from HDFS...")
        
        # Get list of files
        cmd = ['docker', 'exec', 'namenode', 'hdfs', 'dfs', '-ls', '/youtube/metadata']
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Extract filenames
        files = []
        for line in result.stdout.split('\n'):
            if '.json' in line:
                filename = line.split()[-1]
                files.append(filename)
        
        print(f"Found {len(files)} metadata files")
        
        # Load each file
        for filepath in files:
            cmd = ['docker', 'exec', 'namenode', 'hdfs', 'dfs', '-cat', filepath]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            try:
                data = json.loads(result.stdout)
                self.videos.append(data)
            except:
                pass
        
        print(f"Loaded {len(self.videos)} videos\n")
    
    def analyze_views(self):
        """Analyze view counts"""
        print("="*60)
        print("VIEW STATISTICS")
        print("="*60)
        
        views = [int(v.get('views', 0)) for v in self.videos if v.get('views')]
        
        if views:
            total_views = sum(views)
            avg_views = total_views / len(views)
            max_views = max(views)
            min_views = min(views)
            
            print(f"Total Views:      {total_views:,}")
            print(f"Average Views:    {avg_views:,.0f}")
            print(f"Highest Views:    {max_views:,}")
            print(f"Lowest Views:     {min_views:,}")
            print()
            
            # Top 5 most viewed
            sorted_videos = sorted(self.videos, key=lambda x: int(x.get('views', 0)), reverse=True)
            print("TOP 5 MOST VIEWED:")
            for i, video in enumerate(sorted_videos[:5], 1):
                print(f"{i}. {video.get('title', 'N/A')[:60]}")
                print(f"   Views: {int(video.get('views', 0)):,} | Author: {video.get('author', 'N/A')}")
            print()
    
    def analyze_channels(self):
        """Analyze channel/author distribution"""
        print("="*60)
        print("CHANNEL ANALYSIS")
        print("="*60)
        
        authors = [v.get('author', 'Unknown') for v in self.videos]
        author_counts = Counter(authors)
        
        print(f"Total Unique Channels: {len(author_counts)}")
        print("\nTop 10 Channels by Video Count:")
        for author, count in author_counts.most_common(10):
            print(f"  {count:2d} videos - {author}")
        print()
    
    def analyze_tags(self):
        """Analyze common tags/keywords"""
        print("="*60)
        print("TAG/KEYWORD ANALYSIS")
        print("="*60)
        
        all_tags = []
        for video in self.videos:
            tags = video.get('tags', [])
            all_tags.extend([tag.lower() for tag in tags if tag])
        
        tag_counts = Counter(all_tags)
        
        print(f"Total Tags Found: {len(all_tags)}")
        print(f"Unique Tags: {len(tag_counts)}")
        print("\nTop 20 Most Common Tags:")
        for tag, count in tag_counts.most_common(20):
            print(f"  {count:3d} - {tag}")
        print()
    
    def analyze_titles(self):
        """Analyze title keywords"""
        print("="*60)
        print("TITLE KEYWORD ANALYSIS")
        print("="*60)
        
        # Extract words from titles
        all_words = []
        stopwords = {'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'but', 'is', 'are', 'was', 'were'}
        
        for video in self.videos:
            title = video.get('title', '').lower()
            words = re.findall(r'\b[a-z]{4,}\b', title)  # Words 4+ letters
            all_words.extend([w for w in words if w not in stopwords])
        
        word_counts = Counter(all_words)
        
        print("Top 15 Keywords in Titles:")
        for word, count in word_counts.most_common(15):
            print(f"  {count:3d} - {word}")
        print()
    
    def analyze_engagement(self):
        """Analyze likes and engagement"""
        print("="*60)
        print("ENGAGEMENT ANALYSIS")
        print("="*60)
        
        likes = [int(v.get('likes', 0)) for v in self.videos if v.get('likes')]
        
        if likes:
            total_likes = sum(likes)
            avg_likes = total_likes / len(likes)
            
            print(f"Total Likes:      {total_likes:,}")
            print(f"Average Likes:    {avg_likes:,.0f}")
            print()
            
            # Calculate engagement rate (likes per view)
            engaged_videos = []
            for video in self.videos:
                views = int(video.get('views', 0))
                vid_likes = int(video.get('likes', 0))
                if views > 0:
                    engagement = (vid_likes / views) * 100
                    engaged_videos.append((video, engagement))
            
            engaged_videos.sort(key=lambda x: x[1], reverse=True)
            
            print("TOP 5 HIGHEST ENGAGEMENT RATE:")
            for i, (video, rate) in enumerate(engaged_videos[:5], 1):
                print(f"{i}. {video.get('title', 'N/A')[:60]}")
                print(f"   Engagement: {rate:.2f}% | Views: {int(video.get('views', 0)):,}")
            print()
    
    def analyze_publish_dates(self):
        """Analyze publication timeline"""
        print("="*60)
        print("PUBLICATION TIMELINE")
        print("="*60)
        
        dates = []
        for video in self.videos:
            date_str = video.get('publish_date', '')
            if date_str:
                try:
                    date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
                    dates.append(date)
                except:
                    pass
        
        if dates:
            dates.sort()
            print(f"Oldest Video: {dates[0].strftime('%Y-%m-%d')}")
            print(f"Newest Video: {dates[-1].strftime('%Y-%m-%d')}")
            
            # Group by year
            years = Counter([d.year for d in dates])
            print("\nVideos by Year:")
            for year in sorted(years.keys()):
                print(f"  {year}: {years[year]} videos")
            print()
    
    def generate_summary(self):
        """Generate overall summary"""
        print("="*60)
        print("OVERALL SUMMARY")
        print("="*60)
        
        total_videos = len(self.videos)
        total_views = sum(int(v.get('views', 0)) for v in self.videos)
        total_likes = sum(int(v.get('likes', 0)) for v in self.videos)
        
        print(f"Total Videos Analyzed: {total_videos}")
        print(f"Total Views:          {total_views:,}")
        print(f"Total Likes:          {total_likes:,}")
        print(f"Average Views/Video:  {total_views/total_videos if total_videos > 0 else 0:,.0f}")
        print(f"Average Likes/Video:  {total_likes/total_videos if total_videos > 0 else 0:,.0f}")
        print()
    
    def run_full_analysis(self):
        """Run all analysis functions"""
        print("\n" + "="*60)
        print(" "*15 + "GAZA VIDEOS ANALYSIS")
        print("="*60 + "\n")
        
        self.generate_summary()
        self.analyze_views()
        self.analyze_engagement()
        self.analyze_channels()
        self.analyze_tags()
        self.analyze_titles()
        self.analyze_publish_dates()
        
        print("="*60)
        print("ANALYSIS COMPLETE")
        print("="*60)

if __name__ == '__main__':
    analyzer = GazaVideoAnalyzer()
    analyzer.run_full_analysis()