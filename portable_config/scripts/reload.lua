mp.add_key_binding("Ctrl+r", "reload", function()
    mp.command("playlist-reload")
    mp.osd_message("Reloading...")
end)
