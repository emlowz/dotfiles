"""Produce editor-friendly MP4 without re-encoding already compatible streams."""

import os
import tempfile

from yt_dlp.postprocessor.ffmpeg import FFmpegPostProcessor
from yt_dlp.utils import PostProcessingError, replace_extension

__all__ = ["CompatibleMP4PP"]


class CompatibleMP4PP(FFmpegPostProcessor):
    def __init__(self, downloader=None):
        super().__init__(downloader)
        # Respect audio extraction and an explicitly requested other container.
        self.enabled = not any(
            pp["key"] == "FFmpegExtractAudio"
            for pp in self.get_param("postprocessors", [])
        ) and self.get_param("final_ext") in (None, "mp4")
        if self.enabled and downloader is not None:
            # Tell yt-dlp to recognize finished MP4s on repeat downloads, even
            # when the selected source format or intermediate file is WebM/MKV.
            downloader.params["final_ext"] = "mp4"

    @staticmethod
    def _video_compatible(stream):
        return (
            stream.get("codec_name") == "h264"
            and stream.get("pix_fmt") == "yuv420p"
        )

    @staticmethod
    def _audio_compatible(stream):
        return stream.get("codec_name") == "aac" and stream.get("profile") == "LC"

    def run(self, info):
        if not self.enabled or self.get_param("simulate") or self.get_param("skip_download"):
            return [], info

        source = info["filepath"]
        streams = self.get_metadata_object(source).get("streams", [])
        videos = [s for s in streams if s.get("codec_type") == "video"
                  and not s.get("disposition", {}).get("attached_pic")]
        audios = [s for s in streams if s.get("codec_type") == "audio"]
        if not videos:
            return [], info
        if any(s.get("color_transfer") in ("smpte2084", "arib-std-b67") for s in videos):
            raise PostProcessingError(
                "HDR source detected. Choose an SDR format, or use yt --no-convert "
                "to preserve HDR in MKV. Source retained; no uncorrected HDR-to-SDR conversion."
            )

        video_ok = all(self._video_compatible(s) for s in videos)
        audio_ok = all(self._audio_compatible(s) for s in audios)
        if info["ext"].lower() == "mp4" and video_ok and audio_ok:
            self.to_screen("Already H.264/AAC MP4; keeping original streams")
            return [], info
        if info.get("__real_download") is False and self.get_param("overwrites") is False:
            raise PostProcessingError(
                "Existing download needs conversion but --no-overwrites is set. "
                "Keep it and download to a new name or folder."
            )

        destination = replace_extension(source, "mp4", info["ext"])
        if destination != source and os.path.exists(destination):
            raise PostProcessingError(f"Refusing to replace existing file: {destination}")

        # Map actual video/audio explicitly, avoiding attached cover art being
        # encoded as another movie track. yt-dlp embeds thumbnails afterwards.
        opts = ["-map_metadata", "0", "-map_chapters", "0"]
        for stream in [*videos, *audios]:
            opts += ["-map", f"0:{stream['index']}"]
        opts += ["-map", "0:s?", "-c", "copy", "-c:s", "mov_text"]
        for index, stream in enumerate(videos):
            if not self._video_compatible(stream):
                opts += [
                    f"-c:v:{index}", "libx264", f"-crf:v:{index}", "18",
                    f"-preset:v:{index}", "medium", f"-pix_fmt:v:{index}", "yuv420p",
                    # Pad odd dimensions by at most one pixel, never downscale.
                    f"-filter:v:{index}", "pad=ceil(iw/2)*2:ceil(ih/2)*2",
                    f"-fps_mode:v:{index}", "passthrough",
                ]
            opts += [f"-tag:v:{index}", "avc1"]
        for index, stream in enumerate(audios):
            if not self._audio_compatible(stream):
                opts += [f"-c:a:{index}", "aac", f"-profile:a:{index}", "aac_low",
                         f"-b:a:{index}", "192k"]

        self.to_screen(
            f"MP4: video {'copy' if video_ok else 'convert to H.264'}, "
            f"audio {'copy' if audio_ok else 'convert to AAC'}; {destination}"
        )
        fd, temporary = tempfile.mkstemp(
            prefix=".yt-compatible-", suffix=".mp4", dir=os.path.dirname(source) or "."
        )
        os.close(fd)
        try:
            self.run_ffmpeg(source, temporary, opts)
            # Never replace the source until encoding and a codec check succeed.
            result = self.get_metadata_object(temporary).get("streams", [])
            result_video = [s for s in result if s.get("codec_type") == "video"]
            result_audio = [s for s in result if s.get("codec_type") == "audio"]
            if (len(result_video) != len(videos) or len(result_audio) != len(audios)
                    or not all(self._video_compatible(s) for s in result_video)
                    or not all(self._audio_compatible(s) for s in result_audio)):
                raise PostProcessingError("MP4 compatibility check failed; source retained")
            os.replace(temporary, destination)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

        info.update(filepath=destination, ext="mp4", vcodec="h264")
        if audios:
            info["acodec"] = "aac"
        return ([] if source == destination else [source]), info
