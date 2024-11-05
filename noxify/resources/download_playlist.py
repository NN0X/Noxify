#!/usr/bin/env python3

import yt_dlp
import os

def download_best_audio_as_mp3(video_url):
    ydl_opts = {
        'outtmpl': '%(title)s.%(ext)s',  # Save path and file name
        'format': 'bestaudio/best',  # Choose the best audio quality
        'postprocessors': [
            {  # Post-process to convert to MP3
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',  # Convert to mp3
                'preferredquality': '0',  # '0' means best quality, auto-determined by source
            },
        ],
        'writethumbnail': True,  # Download thumbnail
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([video_url])

def get_artist_title_names(playlistName=''):
    path = os.getcwd()
    files = os.listdir(path)

    # get the largest index {index}.mp3 file from audio/
    largest_index = -1

    pathAudio = os.path.join(path, 'audio')
    if 'audio' not in files:
        os.mkdir('audio')
    filesAudio = os.listdir(pathAudio)
    mp3_files = []
    for file in filesAudio:
        if file.endswith('.mp3'):
            mp3_files.append(file)
    for file in mp3_files:
        index = int(file.split('.')[0])
        if index > largest_index:
            largest_index = index
    largest_index += 1
    indexes = []

    mp3_files = []
    for file in files:
        if file.endswith('.mp3'):
            mp3_files.append(file)
    artist_title_names = []
    for file in mp3_files:
        artist_title = file.split('-')
        artist_title_names.append(artist_title)
    with open('artist_title_names.txt', 'w') as f:
        for index, artist_title in enumerate(artist_title_names):
            indexes.append(index + largest_index)
            f.write(str(index + largest_index) + '\n')
            for name in artist_title[::-1]:
                # remove trailing whitespaces and .mp3
                name = name.strip()
                if name.endswith('.mp3'):
                    name = name[:-4]
                f.write(name + '\n')
            f.write(playlistName + '\n')
            f.write('\n')

    for index, file in enumerate(mp3_files):
        os.rename(file, str(index + largest_index) + '.mp3')

    jpg_files = []
    for file in files:
        if file.endswith('.jpg'):
            jpg_files.append(file)
    for index, file in enumerate(jpg_files):
        os.rename(file, str(index + largest_index) + '.jpg')


    # create playlist.txt file with all the indexes split by newlines
    with open('playlist.txt', 'w') as f:
        for index in indexes:
            f.write(str(index) + '\n')

def rename_thumbnails():
    path = os.getcwd()
    files = os.listdir(path)
    for file in files:
        if file.endswith('.webp'):
            os.rename(file, file[:-5] + '.jpg')
    # check if file {name}.jpg fits {file}.mp3 if not move to albums
    if 'albums' not in files:
        os.mkdir('albums')
    for file in files:
        if file.endswith('.jpg'):
            if not os.path.exists(file.split('.jpg')[0] + '.mp3'):
                os.rename(file, 'albums/' + file)

def move_audio_to_folder():
    path = os.getcwd()
    files = os.listdir(path)
    if 'audio' not in files:
        os.mkdir('audio')
    for file in files:
        if file.endswith('.mp3'):
            os.rename(file, 'audio/' + file)

def move_jpg_to_folder():
    path = os.getcwd()
    files = os.listdir(path)
    if 'covers' not in files:
        os.mkdir('covers')
    for file in files:
        if file.endswith('.jpg'):
            os.rename(file, 'covers/' + file)

def main():
    playlistID = input("Enter the playlist ID: ")
    playlistName = input("Enter the playlist name: ")
    playlist_url = 'https://www.youtube.com/playlist?list=' + playlistID
    download_best_audio_as_mp3(playlist_url)
    print('Downloaded all the audio files and covers')
    rename_thumbnails()
    print('Renamed all the thumbnails to .jpg')
    get_artist_title_names(playlistName)
    print('Created artist_title_names.txt and playlist.txt files')
    move_audio_to_folder()
    print('Moved all the audio files to the audio/ folder')
    move_jpg_to_folder()
    print('Moved all the covers to the covers/ folder')

if __name__ == '__main__':
    main()
