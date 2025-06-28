import os, strutils, algorithm, random, sequtils
import rythmTui
# Rythm - A simple command line music playlist manager

when isMainModule:
    if not dirExists("rythm-data"):
        createDir("rythm-data")
    setCurrentDir("rythm-data")
    let args = commandLineParams()
    if args.len == 0:
            echo "No command given"
            quit(1)

    case args[0].toLowerAscii():
    of "tui", "Tui", "TUI":
        rythmTui()
    of "list":
        #helper that does stuff
        proc PlaylistSuffix(name: string): string =
            if name.endsWith("_playlist"):
                result = name[0 .. ^("_playlist".len + 1)]
            else:
                result = name
        #da real code
        if args.len == 1:
            var playlists: seq[string] = @[]
            for kind, path in walkDir("."):
                let fname = path.extractFilename()
                if kind == pcDir and not fname.startsWith(".") and fname.endsWith("_playlist"):
                    playlists.add(PlaylistSuffix(fname))
            if playlists.len == 0:
                echo "No playlists found."
            else:
                echo "Playlists:"
                for i, pl in playlists:
                    echo $(i+1), ". ", pl
        elif args.len == 3 and args[1] == "-s":
            let playlist = args[2] & "_playlist"
            if not dirExists(playlist):
                echo "Playlist does not exist: ", playlist
                quit(1)
            var songs: seq[string] = @[]
            for kind, path in walkDir(playlist):
                if kind == pcFile and path.toLowerAscii().endsWith(".mp3"):
                    songs.add(path.extractFilename())
            if songs.len == 0:
                echo "No songs found in playlist."
            else:
                echo "Songs in playlist \"", args[2], "\":"
                for i, song in songs:
                    echo $(i+1), ". ", song
        else:
            echo "Usage:"
            echo "    list                # Show all playlists"
            echo "    list -s <playlist>  # Show songs in playlist"
            quit(1)

    of "delete", "del":
        if args.len == 2:
            let playlist = args[1] & "_playlist"
            if not dirExists(playlist):
                echo "Playlist does not exist: ", playlist
                quit(1)
            try:
                removeDir(playlist)
                echo "Deleted playlist: ", playlist
            except OSError:
                echo "Failed to delete playlist: ", playlist
                quit(1)
        elif args.len == 4 and args[2] == "-s":
            let playlist = args[1]
            let songName = args[3]
            if not dirExists(playlist):
                echo "Playlist does not exist: ", playlist
                quit(1)
            let songPath = playlist / songName
            if not fileExists(songPath):
                echo "Song does not exist in playlist: ", songName
                quit(1)
            try:
                removeFile(songPath)
                echo "Deleted song: ", songName, " from playlist: ", playlist
            except OSError:
                echo "Failed to delete song: ", songName
                quit(1)
        else:
            echo "Usage:"
            echo "    delete <playlist_name>                 # Delete a playlist"
            echo "    delete <playlist_name> -s <song_name>  # Delete a song from a playlist"
            quit(1)

    of "new":
        if args.len < 2:
            echo "Usage: new <playlist_name>"
            quit(1)
        let playlistName = args[1] & "_playlist"
        if dirExists(playlistName):
            echo "Playlist already exists: ", playlistName
            quit(1)
        createDir(playlistName)
        echo "Created new playlist: ", playlistName

    of "look":
        let searchQuery = args[1..^1].join(" ")
        let cmd = "./libs/yt-dlp --default-search ytsearch3 \"" & searchQuery & "\" --print title --print url"
        let output = execShellCmd(cmd)
        echo output

    of "add":
        if args.len < 3:
            echo "Usage: add <url> <playlist_name>"
            quit(1)
        let url = args[1]
        let playlist = args[2] & "_playlist"
        if not dirExists(playlist):
            echo "Playlist folder does not exist: ", playlist
            echo "Create a playlist with: new <playlist_name>"
            quit(1)
        let cmd = "./libs/yt-dlp -x --audio-format mp3 -o \"" & playlist & "/%(title)s.%(ext)s\" " & url
        let output = execShellCmd(cmd)
        echo output

    of "playlist":
        if args.len < 2:
            echo "Usage: playlist <playlist_name> [--shuffle]"
            quit(1)
        let playlist = args[1] & "_playlist"
        if not dirExists(playlist):
            echo "Playlist does not exist: ", playlist
            quit(1)

        var songs: seq[string] = @[]
        for kind, path in walkDir(playlist):
            if kind == pcFile and path.toLowerAscii().endsWith(".mp3"):
                songs.add(path)

        if songs.len == 0:
            echo "No songs found in playlist"
            quit(1)

        let shuffleMode = args.len > 2 and args[2] == "--shuffle"
        if shuffleMode:
            songs.shuffle()
        else:
            songs.sort()

        for song in songs:
            echo "playing  ", song.extractFilename()
            discard execShellCmd("mpv --no-video \"" & song & "\"")

    else:
        echo "Unknown command: ", args[0]
        quit(1)