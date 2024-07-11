#!/usr/bin/env python3

import os
import subprocess
from time import sleep

ascii_art = """
 _    ,                                          _
' )  /       _/_     /         /                //           /
 /  / __ . . /  . . /___    __/ __ , , , ____  // __ __.  __/ _  __
(__/_(_)(_/_<__(_/_/_)</_  (_/_(_)(_(_/_/ / <_</_(_)(_/|_(_/_</_/ (_
 //
(/
"""


def main():
    cowsaid(ascii_art)
    link = get_url()
    match download_format():
        case "1":
            download_mp3(link, download_directory())
        case "2":
            download_mp4(link, download_quality(), download_directory())


def clear_screen():
    os.system('clear')


def cowsaid(text):
    clear_screen()
    command = f'echo "{text}" | cowsay -n'
    subprocess.run(command, shell=True)


def get_url():
    link = input("\nEnter YouTube video/playlist URL: ").strip()
    if link.startswith("https://"):
        return link
    else:
        cowsaid("Invalid URL!")
        sleep(1)
        return get_url()


def download_format():
    cowsaid(
        "\nChoose download format\n"
        "(1) Download YouTube video in .mp3 format\n"
        "(2) Download YouTube video in .webm format\n"
    )
    choice = input("\nEnter the number corresponding to your choice: ")
    if choice == "1" or choice == "2":
        return choice
    else:
        cowsaid("Invalid input!")
        sleep(1)
        return download_format()


def download_quality():
    cowsaid(
        "\nChoose download quality\n"
        "(1) 480p\n"
        "(2) 720p\n"
        "(3) 1080p\n"
        "(4) 1440p\n"
        "(5) 2160p\n"
    )
    choice = input("\nEnter the number corresponding to your choice: ")

    match choice:
        case '1':
            return '480'
        case '2':
            return '720'
        case '3':
            return '1080'
        case '4':
            return '1440'
        case '5':
            return '2160'
        case _:
            cowsaid("\nInvalid input!\n")
            sleep(1)
            return download_quality()


def download_directory():
    default_path = "~/Videos/downloads"
    cowsaid(
        f"\nDefault download directory: {default_path}\n"
        "Enter new download directory to override the default directory, otherwise skip\n"
    )
    home = "~/"
    new_path = input(f"\nNew directory: {home}")
    if new_path == "":
        return default_path
    else:
        return home + new_path


def download_mp3(url, output_directory):
    command = f"yt-dlp -x --audio-format mp3 --embed-thumbnail --embed-metadata -o \"{output_directory}/%(title)s.%(ext)s\" -f 'bestaudio/best' {url}"
    execute_ytdlp_command(command)


def download_mp4(url, quality, output_directory):
    command = f"yt-dlp -o \"{output_directory}/%(title)s.%(ext)s\" -f 'bestvideo[height<={quality}]+bestaudio/best[height<={quality}]' {url}"
    execute_ytdlp_command(command)


def execute_ytdlp_command(command):
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        cowsaid(f"Error executing command: {e}")


if __name__ == "__main__":
    main()
