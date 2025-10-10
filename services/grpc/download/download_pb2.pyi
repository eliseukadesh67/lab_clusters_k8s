from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Mapping as _Mapping, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Request(_message.Message):
    __slots__ = ("url",)
    URL_FIELD_NUMBER: _ClassVar[int]
    url: str
    def __init__(self, url: _Optional[str] = ...) -> None: ...

class Metadata(_message.Message):
    __slots__ = ("title", "duration", "thumbnail_url", "total_bytes")
    TITLE_FIELD_NUMBER: _ClassVar[int]
    DURATION_FIELD_NUMBER: _ClassVar[int]
    THUMBNAIL_URL_FIELD_NUMBER: _ClassVar[int]
    TOTAL_BYTES_FIELD_NUMBER: _ClassVar[int]
    title: str
    duration: int
    thumbnail_url: str
    total_bytes: int
    def __init__(self, title: _Optional[str] = ..., duration: _Optional[int] = ..., thumbnail_url: _Optional[str] = ..., total_bytes: _Optional[int] = ...) -> None: ...

class ProgressUpdate(_message.Message):
    __slots__ = ("bytes_downloaded", "total_bytes")
    BYTES_DOWNLOADED_FIELD_NUMBER: _ClassVar[int]
    TOTAL_BYTES_FIELD_NUMBER: _ClassVar[int]
    bytes_downloaded: int
    total_bytes: int
    def __init__(self, bytes_downloaded: _Optional[int] = ..., total_bytes: _Optional[int] = ...) -> None: ...

class DownloadChunk(_message.Message):
    __slots__ = ("progress", "data")
    PROGRESS_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    progress: ProgressUpdate
    data: bytes
    def __init__(self, progress: _Optional[_Union[ProgressUpdate, _Mapping]] = ..., data: _Optional[bytes] = ...) -> None: ...
