import re
from yt_dlp.extractor.common import InfoExtractor
from yt_dlp.utils import decode_packed_codes

class HdStream4uIE(InfoExtractor):
    _VALID_URL = r'https?://(?:www\.)?hdstream4u\.com/file/(?P<id>[a-zA-Z0-9]+)'

    def _real_extract(self, url):
        video_id = self._match_id(url)
        webpage = self._download_webpage(url, video_id)

        # 1. Isolate the obfuscated eval() javascript block from the raw HTML
        packed_js = self._search_regex(
            r"(eval\(function\(p,a,c,k,e,d\).*?split\('\|'\)\)\))",
            webpage, 'packed js'
        )

        # 2. Decode the script using the modern yt-dlp utility
        unpacked_js = decode_packed_codes(packed_js)

        # 3. Search the readable Javascript for the master manifest URL
        # We removed the strict dictionary keys so it catches dynamic variables
        stream_url = self._search_regex(
            r'["\'](https?://[^"\']+(?:\.txt|\.m3u8)[^"\']*)["\']',
            unpacked_js, 'stream url'
        )

        title = self._og_search_title(webpage, default=video_id)

        return {
            'id': video_id,
            'title': title,
            'url': stream_url,
            'protocol': 'm3u8_native',
            'ext': 'mp4',
            # Spoof the Referer header to bypass hotlink protection
            'http_headers': {
                'Referer': url,
            }
        }