import os, strutils, terminal, posix, posix/termios, algorithm

proc readKey(): char =
    var oldt, newt: Termios
    discard tcgetattr(STDIN_FILENO, addr oldt)
    newt = oldt
    newt.c_lflag = newt.c_lflag and not (ICANON or ECHO)
    discard tcsetattr(STDIN_FILENO, TCSANOW, addr newt)
    let ch = stdin.readChar()
    discard tcsetattr(STDIN_FILENO, TCSANOW, addr oldt)
    return ch

proc getPlaylists(): seq[string] =
    var result: seq[string] = @[]
    for kind, path in walkDir("."):
        let name = path.extractFilename()
        if kind == pcDir and name.endsWith("_playlist"):
            result.add(name[0 ..< name.len - "_playlist".len])
    result.sort()
    return result

proc selectPlaylist(playlists: seq[string]): string =
    var idx = 0
    while true:
        eraseScreen()
        echo "🎵 Select Playlist:\n"
        for i, p in playlists:
            if i == idx:
                stdout.styledWrite(fgGreen, "> ", p)
            else:
                stdout.write("  ", p)
            echo ""
        echo "\n↑↓ to navigate | Enter = select | q = quit"
        case readKey():
        of 'A': idx = (idx - 1 + playlists.len) mod playlists.len  # Up
        of 'B': idx = (idx + 1) mod playlists.len                  # Down
        of '\n': return playlists[idx]
        of 'q': quit(0)
        else: discard

proc playinNewTerm(pl: string; shuffle: bool) =
    let command = if shuffle:
        "rythm playlist \"" & pl & "\" --shuffle"
    else:
        "rythm playlist \"" & pl & "\""

    when defined(macosx):
        let escapedCmd = command.replace("\"", "\\\"")
        let script = "osascript -e 'tell application \"Terminal\" to do script \"" & escapedCmd & "\"'"
        discard execShellCmd(script)
    elif defined(linux):
        let cmd = "gnome-terminal -- bash -c \"" & command & "; echo Press Enter to close; read\""
        discard execShellCmd(cmd)
    elif defined(windows):
        let cmd = "start cmd /k " & command
        discard execShellCmd(cmd)
    else:
        echo "Unsupported OS"

proc playlistMenu(pl: string) =
    while true:
        eraseScreen()
        echo "📂 Playlist: ", pl
        echo "\nOptions:"
        echo "  [s]  Shuffle & Play"
        echo "  [p]  Play Sorted"
        echo "  [a]  Add Song"
        echo "  [b]  Back"
        echo "  [q]  Quit"

        case readKey():
        of 's':
            playinNewTerm(pl, true)
        of 'p':
            playinNewTerm(pl, false)
        of 'a':
            stdout.write "Enter URL: "
            let url = stdin.readLine()
            discard execShellCmd("rythm add " & url & " " & pl)
        of 'b':
            return
        of 'q':
            quit(0)
        else:
            discard

proc rythmTui*() =
    while true:
        let playlists = getPlaylists()
        if playlists.len == 0:
            echo "No playlists found."
            quit(1)
        let selected = selectPlaylist(playlists)
        playlistMenu(selected)