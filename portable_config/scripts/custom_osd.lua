local mp = require 'mp'

-- Author: Hyperion KING

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local VIRTUAL_HEIGHT = 1080
local BASE_FONT_SIZE = 28
local IMAX_BANNER_DURATION = 5

-------------------------------------------------
-- STATE
-------------------------------------------------
local visible = false
local imax_applied = false
local original_scale = nil
local imax_banner_until = 0

-------------------------------------------------
-- COLORS (Bright/Neon Palette)
-------------------------------------------------
local C_RESET    = "{\\c&HFFFFFF&}"       -- White
local C_LABEL    = "{\\c&HFFFF00&\\b1}"   -- Bright Cyan (RGB: 00FFFF)
local C_VALUE    = "{\\c&HFFFFFF&}"       -- White
local C_HEADER   = "{\\c&H00D7FF&}"       -- Gold (RGB: FFD700)
local C_IMAX     = "{\\c&HFF9900&}"       -- Vivid Blue (RGB: 0099FF)
local C_HDR      = "{\\c&H00FF00&}"       -- Neon Green (RGB: 00FF00)
local C_DV       = "{\\c&HFF00FF&}"       -- Magenta (RGB: FF00FF)
local C_LOSSY    = "{\\c&H6666FF&}"       -- Light Red (RGB: FF6666)
local C_LOSSLESS = "{\\c&HFFFF00&}"       -- Cyan
local C_DIM      = "{\\c&HCCCCCC&}"       -- Light Gray
local C_WARN     = "{\\c&H0000FF&}"       -- Bright Red
local C_META     = "{\\c&HAAFFFF&}"       -- Pale Yellow

-------------------------------------------------
-- UTILITIES
-------------------------------------------------
local function prop(name, def)
    local v = mp.get_property(name)
    if not v or v == "" then return def or "N/A" end
    return v
end

local function propn(name, def)
    local v = mp.get_property_number(name)
    if not v then return def or 0 end
    return v
end

local function sanitize(str)
    if not str then return "" end
    str = tostring(str)
    str = str:gsub("\\", "/") 
    str = str:gsub("{", "\\{")
    str = str:gsub("}", "\\}")
    return str
end

local function fmt(v)
    if not v or v == "N/A" or v == "" or v == "unknown" then
        return C_DIM .. "N/A" .. C_RESET
    end
    return C_VALUE .. sanitize(v) .. C_RESET
end

-------------------------------------------------
-- DATA GATHERING
-------------------------------------------------

-- FILE SIZE
local function get_file_size()
    local s = propn("file-size")
    if s <= 0 then return "N/A" end
    local mb = s / (1024 * 1024)
    if mb > 1024 then
        return string.format("%.2f GB", mb / 1024)
    else
        return string.format("%.0f MB", mb)
    end
end

-- CONTAINER
local function get_container_name()
    local fmt_raw = prop("file-format", ""):lower()
    if fmt_raw:find("mkv") or fmt_raw:find("matroska") then return "Matroska (MKV)" end
    if fmt_raw:find("mp4") then return "MPEG-4 (MP4)" end
    if fmt_raw:find("avi") then return "AVI" end
    if fmt_raw:find("webm") then return "WebM" end
    if fmt_raw:find("mov") then return "QuickTime (MOV)" end
    return sanitize(fmt_raw:upper())
end

-- VIDEO CODEC
local function get_video_codec_friendly()
    local c = prop("video-codec", ""):lower()
    
    if c == "hevc" then return "HEVC (High Efficiency Video Coding)" end
    if c == "h264" then return "AVC (H.264 / MPEG-4 Part 10)" end
    if c == "vp9" then return "VP9" end
    if c == "av1" then return "AV1" end
    if c == "mpeg2video" then return "MPEG-2 Video" end
    if c == "vc1" then return "VC-1 (SMPTE 421M)" end
    if c == "prores" then return "ProRes (Apple ProRes (iCodec Pro))" end
    if c == "dnxhd" then return "DNxHD (Avid DNxHD)" end
    if c == "mjpeg" then return "Motion JPEG" end
    if c == "theora" then return "Theora" end
    
    return sanitize(c:upper())
end

-- BIT DEPTH & CHROMA
local function get_pix_fmt_info()
    local pix = mp.get_property("video-params/pixel-format")
    if not pix or pix == "" then pix = mp.get_property("video-out-params/pixel-format") end
    if not pix or pix == "" then pix = mp.get_property("video-params/pixelformat") end 

    if not pix or pix == "" then return "N/A", "N/A" end

    -- Bit Depth
    local depth = "8 bit"
    if pix:find("10") then depth = "10 bit"
    elseif pix:find("12") then depth = "12 bit"
    elseif pix:find("16") then depth = "16 bit"
    end

    -- Chroma
    local chroma = "4:2:0" 
    if pix:find("444") then chroma = "4:4:4"
    elseif pix:find("422") then chroma = "4:2:2"
    elseif pix:find("420") then chroma = "4:2:0"
    elseif pix:find("gray") then chroma = "Grayscale"
    end

    return depth, chroma
end

-- ASPECT RATIO BADGES
local function get_aspect_badge(ar)
    if not ar or ar == 0 then return "" end
    local t = 0.04 -- tolerance
    
    if math.abs(ar - 1.33) < t then return "Academy (4:3)" end
    if math.abs(ar - 1.43) < t then return "IMAX GT (1.43:1)" end
    if math.abs(ar - 1.66) < t then return "European Wide (1.66:1)" end
    if math.abs(ar - 1.78) < t then return "Widescreen (16:9)" end
    if math.abs(ar - 1.85) < t then return "Flat (1.85:1)" end
    if math.abs(ar - 1.90) < t then return "IMAX Digital (1.90:1)" end
    if math.abs(ar - 2.00) < t then return "Univisium (2:1)" end
    if math.abs(ar - 2.20) < t then return "Dimension 150 (2.20:1)" end
    if ar > 2.30 and ar < 2.45 then return "Cinemascope / Anamorphic" end
    if math.abs(ar - 2.76) < t then return "Ultra Panavision 70" end
    
    return ""
end

-- AUDIO HELPERS
local function get_audio_depth_val()
    local f = prop("audio-params/format", "")
    if f:match("s16") then return 16 end
    if f:match("s24") then return 24 end
    if f:match("s32") then return 32 end
    if f:match("f32") then return 32 end
    return 0
end

local function get_audio_bit_depth_str()
    local d = get_audio_depth_val()
    if d > 0 then return d .. "-bit" end
    return nil
end

local function get_audio_dynamic_range()
    local d = get_audio_depth_val()
    if d > 0 then
        -- Approx 6dB per bit rule
        return (d * 6) .. " dB"
    end
    return nil
end

local function detect_audio_details()
    local c  = prop("audio-codec-name", ""):lower()
    local ch = mp.get_property_number("audio-params/channel-count", 0)
    local br = mp.get_property_number("audio-bitrate", 0) / 1000 
    local name = (prop("filename", "") .. " " .. prop("media-title", "")):lower()

    local codec_display = c:upper() -- Fallback
    local format_display = nil
    local encoded_display = nil

    -- 1. BADGES (Short [Long])
    if c == "flac" then codec_display = "FLAC [Free Lossless Audio Codec]"
    elseif c == "alac" then codec_display = "ALAC [Apple Lossless]"
    elseif c == "aac"  then codec_display = "AAC [Advanced Audio Coding]"
    elseif c == "opus" then codec_display = "Opus [Opus Audio]"
    elseif c == "vorbis" then codec_display = "Vorbis [Ogg Vorbis]"
    elseif c == "mp3"  then codec_display = "MP3 [MPEG-1 Audio Layer III]"
    elseif c == "ape"  then codec_display = "APE [Monkey's Audio]"
    elseif c == "wavpack" then codec_display = "WavPack [WavPack]"
    elseif c:find("pcm") then codec_display = "PCM [PCM Uncompressed]" 
    -- Surround formats
    elseif c == "truehd" then codec_display = "TrueHD [Dolby TrueHD]"
    elseif c == "eac3" then codec_display = "E-AC3 [Dolby Digital Plus]"
    elseif c == "ac3" then codec_display = "AC3 [Dolby Digital]"
    elseif c == "dts" then codec_display = "DTS [DTS Surround]"
    elseif c == "dts-hd-ma" then codec_display = "DTS-HD MA [DTS-HD Master Audio]"
    elseif c == "dts-hd-hr" then codec_display = "DTS-HD HR [DTS-HD High Res]"
    end

    -- 2. DETAILED FORMAT / ENCODED LOGIC
    if c == "truehd" then 
        format_display = "Dolby TrueHD (Atmos-capable)"
        encoded_display = "Dolby Atmos (TrueHD, encoded)"
    elseif c == "eac3" then
        if name:find("atmos") then
            format_display = "Dolby Digital Plus (Atmos-capable)"
            encoded_display = "Dolby Atmos (DD+, encoded)"
        else
            format_display = "Dolby Digital Plus"
        end
    elseif c == "ac3" then
        format_display = "Dolby Digital (AC-3)"
        
    -- DTS LOGIC (Refined)
    elseif c == "dts" or c == "dts-hd-ma" then
        local is_dtsx = false
        
        -- DTS:X Condition: Bitrate > 2.5Mbps AND Channels >= 8
        if (br > 2500 and ch >= 8) or name:find("dts%.?x") or name:find("dts%-x") then
            is_dtsx = true 
        end

        if is_dtsx then
             format_display = "DTS:X / DTS-HD Master Audio"
             encoded_display = "DTS:X (Inferred)"
        elseif c == "dts-hd-ma" or (br > 1512 and ch >= 6) then
             format_display = "DTS-HD Master Audio"
        else
             format_display = "DTS Core"
        end
    end

    return codec_display, format_display, encoded_display
end

local function get_channel_layout()
    local ch = propn("audio-params/channel-count")
    if ch == 1 then return "1.0 (Mono)" end
    if ch == 2 then return "2.0 (Stereo)" end
    if ch == 3 then return "2.1" end
    if ch == 6 then return "5.1" end
    if ch == 8 then return "7.1" end
    if ch > 0 then return ch .. " channels" end
    return "N/A"
end

local function audio_compression_mode()
    local c  = prop("audio-codec-name", ""):lower()
    local br = mp.get_property_number("audio-bitrate", 0) / 1000
    if c == "truehd" or c == "flac" or c == "alac" or c == "dts-hd-ma" or c == "eac3" or c:find("pcm") then
        return "Lossless"
    end
    if c == "dts" and br > 1500 then return "Lossless (inferred)" end
    return "Lossy"
end

local function get_bitrate_mode()
    local c = prop("audio-codec-name", ""):lower()
    if c == "flac" or c == "alac" or c == "opus" or c == "vorbis" or c == "aac" or c == "mp3" then
        return "Variable"
    end
    return "Constant" 
end

-- VIDEO HDR
local function detect_hdr_active()
    local trc = prop("video-params/transfer", "")
    local dvp = prop("video-params/dolby-vision-profile", "")
    if dvp ~= "" then return "Dolby Vision (Active)", C_DV end
    if trc == "pq" then return "HDR10 (Active)", C_HDR end
    if trc == "hlg" then return "HDR (HLG Active)", C_HDR end
    if prop("video-params/primaries", "") == "bt.2020" then return "Wide Gamut SDR", C_DIM end
    return "SDR", C_DIM
end

local function detect_hdr_encoded()
    local codec = prop("video-codec", ""):lower()
    local prim = prop("video-params/primaries", "")
    local trc = prop("video-params/transfer", "")
    local dvp = prop("video-params/dolby-vision-profile", "")
    if dvp ~= "" then return "Dolby Vision", C_DV end
    if codec == "hevc" and prim == "bt.2020" and trc == "bt.1886" then
        return "HDR / DV (Metadata inactive)", C_WARN
    end
    if prim == "bt.2020" and trc ~= "pq" then
        return "HDR10 (Metadata stripped)", C_WARN
    end
    return nil
end

local function detect_tonemapping()
    local trc = prop("video-params/transfer", "")
    local tm = prop("tone-mapping", "no")
    if (trc == "pq" or trc == "hlg") and tm ~= "no" then return "HDR -> SDR", C_WARN end
    return nil
end

local function decode_mode()
    local hw = mp.get_property("hwdec-current")
    if hw and hw ~= "" and hw ~= "no" then return "HW (" .. hw .. ")" end
    return "SW"
end

local function format_bitrate(bps)
    if not bps or bps <= 0 then return "N/A" end
    local mb = bps / 1000 / 1000
    local kb = bps / 1000
    return string.format("%.2f Mbps (%.0f kbps)", mb, kb)
end

local function format_duration(sec)
    if not sec or sec <= 0 then return "N/A" end
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    local min = sec / 60
    return string.format("%02d:%02d:%02d (%.1f min)", h, m, s, min)
end

local function format_audio_bitrate(bps)
    if not bps or bps <= 0 then return "N/A" end
    return string.format("%.0f kbps", bps / 1000)
end

-- IMAX / SOURCE BADGES
local function detect_imax(w, h)
    if not w or not h or h == 0 then return nil end
    local r = w / h
    if r > 1.40 and r < 1.46 then return "IMAX 1.43:1" end
    if r > 1.85 and r < 1.95 then return "IMAX 1.90:1" end
    return nil
end

local function apply_imax_scale(mode)
    if imax_applied then return end
    original_scale = mp.get_property_number("window-scale", 1.0)
    if mode == "IMAX 1.43:1" then
        mp.set_property_number("window-scale", original_scale * 1.15)
    elseif mode == "IMAX 1.90:1" then
        mp.set_property_number("window-scale", original_scale * 1.08)
    end
    imax_applied = true
    imax_banner_until = mp.get_time() + IMAX_BANNER_DURATION
end

local function restore_scale()
    if original_scale then
        mp.set_property_number("window-scale", original_scale)
    end
    imax_applied = false
end

-------------------------------------------------
-- RENDERER
-------------------------------------------------
local function build_ass()
    local vw = propn("video-params/w")
    local vh = propn("video-params/h")
    local dw = propn("width")
    local dh = propn("height")
    local fps = propn("container-fps")
    
    local imax = detect_imax(vw, vh)
    if imax then apply_imax_scale(imax) end

    -- MAIN FONT
    local fs = BASE_FONT_SIZE
    local title_fs = math.floor(fs * 1.3)
    
    local ass = string.format("{\\an7\\fs%d\\b1\\bord1\\3c&H000000&\\4c&H000000&\\4a&H88&}", fs)

    -- IMAX Banner
    if imax and mp.get_time() < imax_banner_until then
        ass = ass .. string.format("{\\fs%d}%s%s%s\\N{\\fs%d}", title_fs, C_IMAX, imax, C_RESET, fs)
    end

    -- 1. FILE
    ass = ass .. C_LABEL .. "File: " .. fmt(prop("filename")) .. "\\N"
    ass = ass .. C_LABEL .. "File Size: " .. C_VALUE .. get_file_size() .. C_RESET .. "\\N"
    ass = ass .. C_LABEL .. "Container: " .. fmt(get_container_name()) ..
          C_LABEL .. " | Duration: " .. fmt(format_duration(propn("duration"))) .. "\\N\\N"

    -- 2. VIDEO
    ass = ass .. C_HEADER .. "Video:" .. C_RESET .. "\\N"
    ass = ass .. C_LABEL .. "  Codec: " .. C_VALUE .. get_video_codec_friendly() .. C_RESET .. "\\N"
    
    local bit_depth, chroma = get_pix_fmt_info()
    ass = ass .. C_LABEL .. "  Bit Depth: " .. fmt(bit_depth) .. 
          C_LABEL .. " | Chroma: " .. fmt(chroma) .. "\\N"

    ass = ass .. C_LABEL .. "  Decoding: " .. C_VALUE .. decode_mode() .. C_RESET .. "\\N"

    -- FPS with SPF
    local spf = (fps > 0) and (1 / fps) or 0
    ass = ass .. C_LABEL .. "  FPS: " .. C_VALUE .. string.format("%.3f", fps) .. C_RESET .. 
                 " (" .. string.format("%.4f SPF", spf) .. ")" ..
          C_LABEL .. " | Bitrate: " .. fmt(format_bitrate(propn("video-bitrate"))) .. "\\N"

    -- RESOLUTION & SOURCE BADGES
    local fname = prop("filename"):lower()
    local source_badges = ""
    if fname:find("35mm") then source_badges = source_badges .. " [35mm Film]" end
    if fname:find("2k") and fname:find("scan") then source_badges = source_badges .. " [2K Scan]" end
    if fname:find("4k") and fname:find("scan") then source_badges = source_badges .. " [4K Scan]" end

    if vw == dw and vh == dh then
        ass = ass .. C_LABEL .. "  Resolution: " .. C_VALUE .. dw .. "x" .. dh .. C_META .. source_badges .. C_RESET .. "\\N"
    else
        ass = ass .. C_LABEL .. "  Coded: " .. C_VALUE .. vw .. "x" .. vh ..
              C_LABEL .. " | Display: " .. C_VALUE .. dw .. "x" .. dh .. C_META .. source_badges .. C_RESET .. "\\N"
    end

    local prof = prop("video-params/profile", "N/A")
    if prof ~= "N/A" then
        ass = ass .. C_LABEL .. "  Profile: " .. C_META .. sanitize(prof) .. C_RESET .. "\\N"
    end

    local primaries = prop("video-params/primaries")
    local transfer  = prop("video-params/transfer")
    local matrix    = prop("video-params/colormatrix")
    local range     = prop("video-params/range")
    
    if primaries == "N/A" then primaries = prop("video-out-params/primaries") end
    if transfer == "N/A"  then transfer = prop("video-out-params/transfer") end
    if matrix == "N/A"    then matrix = prop("video-out-params/colormatrix") end
    if range == "N/A"     then range = prop("video-out-params/range") end

    ass = ass .. C_LABEL .. "  Primaries: " .. fmt(primaries) ..
          C_LABEL .. " | Transfer: " .. fmt(transfer) .. "\\N"
    ass = ass .. C_LABEL .. "  Matrix: " .. fmt(matrix) ..
          C_LABEL .. " | Levels: " .. fmt(range) .. "\\N"

    -- Aspect Ratio with Professional Badges & Open Matte
    local aspect = (dh > 0) and (dw / dh) or 0
    local ar_badge = get_aspect_badge(aspect)
    
    if fname:find("open") and fname:find("matte") then
        if ar_badge ~= "" then ar_badge = ar_badge .. " / Open Matte"
        else ar_badge = "Open Matte" end
    end
    
    ass = ass .. C_LABEL .. "  Aspect: " .. C_VALUE .. string.format("%.2f:1", aspect)
    if ar_badge ~= "" then ass = ass .. " " .. C_META .. "[" .. ar_badge .. "]" end
    ass = ass .. C_RESET .. "\\N"
    
    local d_w = mp.get_property_number("display-width") or 0
    local d_h = mp.get_property_number("display-height") or 0
    ass = ass .. C_LABEL .. "  Display Output: " .. C_VALUE .. d_w .. "x" .. d_h .. C_RESET .. "\\N"
    
    local o_w = mp.get_property_number("osd-width") or 0
    local o_h = mp.get_property_number("osd-height") or 0
    ass = ass .. C_LABEL .. "  Window Size: " .. C_VALUE .. o_w .. "x" .. o_h .. C_RESET .. "\\N"

    local dvp = prop("video-params/dolby-vision-profile", "")
    if dvp ~= "" then
        ass = ass .. C_LABEL .. "  DV Profile: " .. C_DV .. "Profile " .. sanitize(dvp) .. C_RESET .. "\\N"
    end

    local hdr_active, hdr_active_color = detect_hdr_active()
    ass = ass .. C_LABEL .. "  Dynamic Range: " .. hdr_active_color .. hdr_active .. C_RESET .. "\\N"

    local hdr_enc, hdr_enc_color = detect_hdr_encoded()
    if hdr_enc then
        ass = ass .. C_LABEL .. "  Encoding: " .. hdr_enc_color .. hdr_enc .. C_RESET .. "\\N"
    end
    
    local tm, tm_color = detect_tonemapping()
    if tm then
        ass = ass .. C_LABEL .. "  Tone Mapping: " .. tm_color .. tm .. C_RESET .. "\\N"
    end
    ass = ass .. "\\N"

    -- 3. AUDIO
    local acodec, aformat, aencoded = detect_audio_details()

    ass = ass .. C_HEADER .. "Audio:" .. C_RESET .. "\\N"
    ass = ass .. C_LABEL .. "  Codec: " .. fmt(acodec)
    if aformat then ass = ass .. " " .. C_DV .. "[" .. aformat .. "]" .. C_RESET end
    ass = ass .. "\\N"

    if aformat then
        ass = ass .. C_LABEL .. "  Format: " .. C_VALUE .. aformat .. C_RESET .. "\\N"
    end

    if aencoded then
         ass = ass .. C_LABEL .. "  Encoded: " .. C_META .. aencoded .. C_RESET .. "\\N"
    end

    ass = ass .. C_LABEL .. "  Channels: " .. C_VALUE .. get_channel_layout() .. C_RESET ..
          C_LABEL .. " | Sample Rate: " .. fmt(prop("audio-params/samplerate") .. " Hz") .. "\\N"
    
    local aq = audio_compression_mode()
    local aq_color = (aq == "Lossless") and C_LOSSLESS or C_LOSSY
    ass = ass .. C_LABEL .. "  Bitrate: " .. fmt(format_audio_bitrate(propn("audio-bitrate"))) 
    
    local audio_depth = get_audio_bit_depth_str()
    if audio_depth then
         ass = ass .. C_LABEL .. " | Bit Depth: " .. C_VALUE .. audio_depth .. C_RESET
    end
    ass = ass .. "\\N"
    
    local adr = get_audio_dynamic_range()
    if adr then
        ass = ass .. C_LABEL .. "  Dynamic Range: " .. C_VALUE .. adr .. C_RESET .. "\\N"
    end

    ass = ass .. C_LABEL .. "  Bitrate Mode: " .. C_VALUE .. get_bitrate_mode() .. C_RESET .. "\\N"
    ass = ass .. C_LABEL .. "  Compression Mode: " .. aq_color .. aq .. C_RESET .. "\\N\\N"

    ass = ass .. C_LABEL .. "  Bitrate Mode: " .. C_VALUE .. get_bitrate_mode() .. C_RESET .. "\\N"
    ass = ass .. C_LABEL .. "  Compression Mode: " .. aq_color .. aq .. C_RESET .. "\\N"

    -- Check for active SOFA filter
    local active_af_raw = prop("af", "")
    if active_af_raw:lower():find("sofa") then
        -- Extract the file name (everything after the last slash up to .sofa)
        local sofa_file = active_af_raw:match("([^/\\]+%.sofa)") or "Unknown SOFA File"
        
        ass = ass .. C_LABEL .. "  HRTF (Binaural): " .. C_VALUE .. sanitize(sofa_file) .. C_RESET .. "\\N"
    else
        -- Display OFF in a dimmed color when inactive
        ass = ass .. C_LABEL .. "  HRTF (Binaural): " .. C_DIM .. "OFF" .. C_RESET .. "\\N"
    end

    -- Add final spacing before Playback section
    ass = ass .. "\\N"

    -- 4. PLAYBACK
    ass = ass .. C_HEADER .. "Playback:" .. C_RESET .. "\\N"
    ass = ass .. C_LABEL .. "  A/V Sync: " .. fmt(string.format("%.4f", propn("avsync"))) ..
          C_LABEL .. " | Dropped: " .. fmt(prop("frame-drop-count")) .. "\\N"
    ass = ass .. C_LABEL .. "  VO: " .. fmt(prop("video-out")) ..
          C_LABEL .. " | GPU: " .. fmt(prop("gpu-name"))
   
    return ass
end

local function show_osd()
    local status, result = pcall(build_ass)
    if status then
        local w_val = mp.get_property_number("osd-width", 1280)
        local h_val = mp.get_property_number("osd-height", 720)
        
        local aspect = 1.777
        if h_val > 0 then aspect = w_val / h_val end
        
        local virt_h = VIRTUAL_HEIGHT
        local virt_w = virt_h * aspect

        mp.set_osd_ass(virt_w, virt_h, result)
    else
        mp.msg.error("OSD Error: " .. tostring(result))
    end
end

local function clear_osd()
    mp.set_osd_ass(0, 0, "")
end

-------------------------------------------------
-- EVENTS
-------------------------------------------------
mp.register_script_message("toggle-imax-osd", function()
    visible = not visible
    if visible then show_osd() else clear_osd() end
end)

mp.register_event("file-loaded", restore_scale)

mp.observe_property("osd-height", "number", function()
    if visible then show_osd() end
end)
mp.observe_property("window-scale", "number", function()
    if visible then show_osd() end
end)
mp.observe_property("video-params", "native", function()
    if visible then show_osd() end
end)
mp.observe_property("audio-params", "native", function()
    if visible then show_osd() end
end)
mp.add_key_binding("u", "toggle-sofa-filter", function()
    local filters = mp.get_property_native("af", {})
    local found_index = nil

    for i, filter in ipairs(filters) do
        local graph = (filter.params and filter.params.graph) or filter.name or ""
        if graph:lower():find("sofa") then
            found_index = i
            break
        end
    end

    if found_index then
        table.remove(filters, found_index)
        mp.osd_message("SOFA Filter: Disabled")
    else
        table.insert(filters, {
            name = "lavfi",
            params = { graph = "sofalizer=sofa='C\\:/mpv/portable_config/sofa/D1_96K_24bit_512tap_FIR_SOFA.sofa':gain=-4" }
        })
        mp.osd_message("SOFA Filter: Enabled")
    end

    mp.set_property_native("af", filters)
end)