#!/usr/bin/env python3
"""
Service B - Download REST API Server
Provides video metadata extraction and download functionality via REST API
"""

from flask import Flask, request, jsonify, Response, stream_with_context
import os
import yt_dlp
import threading
import queue
import json

app = Flask(__name__)

# Ensure downloads directory exists
DOWNLOADS_DIR = 'downloads'
os.makedirs(DOWNLOADS_DIR, exist_ok=True)


@app.route('/metadata', methods=['POST'])
def get_video_metadata():
    """
    Extract video metadata without downloading.
    
    Request body:
    {
        "video_url": "https://youtube.com/watch?v=..."
    }
    
    Response (200):
    {
        "title": "Video Title",
        "duration": 300,
        "thumbnail_url": "https://..."
    }
    
    Response (400/404):
    {
        "error": "Error message"
    }
    """
    data = request.get_json()
    
    if not data or 'video_url' not in data:
        return jsonify({'error': 'video_url é obrigatório'}), 400
    
    video_url = data['video_url']
    
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info_dict = ydl.extract_info(video_url, download=False)
        
        title = info_dict.get('title', 'N/A')
        duration = int(info_dict.get('duration', 0))
        thumbnail_url = info_dict.get('thumbnail', '')
        
        return jsonify({
            'title': title,
            'duration': duration,
            'thumbnail_url': thumbnail_url
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Não foi possível extrair metadados: {str(e)}'}), 404


@app.route('/downloads', methods=['POST'])
def download_video():
    """
    Download video with real-time progress streaming using Server-Sent Events.
    
    Request body:
    {
        "video_url": "https://youtube.com/watch?v=..."
    }
    
    Response (200) - Server-Sent Events stream:
    data: {"type": "progress", "percentage": 45.5}
    data: {"type": "success", "message": "Download completed"}
    
    Response (400):
    {
        "error": "Error message"
    }
    """
    data = request.get_json()
    
    if not data or 'video_url' not in data:
        return jsonify({'error': 'video_url é obrigatório'}), 400
    
    video_url = data['video_url']
    
    def generate():
        progress_queue = queue.Queue()
        
        def progress_hook(d):
            if d['status'] == 'downloading':
                try:
                    total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate')
                    if total_bytes:
                        downloaded_bytes = d.get('downloaded_bytes', 0)
                        percentage = (downloaded_bytes / total_bytes) * 100
                        progress_queue.put({
                            'type': 'progress',
                            'percentage': round(percentage, 2)
                        })
                except (TypeError, ZeroDivisionError):
                    pass
        
        ydl_opts = {
            'outtmpl': os.path.join(DOWNLOADS_DIR, '%(title)s.%(ext)s'),
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best/bestvideo+bestaudio',
            'merge_output_format': 'mp4',
            'progress_hooks': [progress_hook],
            'ignoreerrors': False,
            'quiet': True,
            'no_warnings': True,
        }
        
        def download_thread_target():
            try:
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    ydl.download([video_url])
                progress_queue.put({
                    'type': 'success',
                    'message': f"Download de '{video_url}' concluído com sucesso."
                })
            except Exception as e:
                progress_queue.put({
                    'type': 'error',
                    'message': f"Erro ao baixar '{video_url}': {str(e)}"
                })
            finally:
                progress_queue.put(None)
        
        thread = threading.Thread(target=download_thread_target)
        thread.start()
        
        while True:
            item = progress_queue.get()
            if item is None:
                break
            yield f"{json.dumps(item)}\n\n"
    
    return Response(
        stream_with_context(generate()),
        mimetype='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'X-Accel-Buffering': 'no'
        }
    )


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'download-service'}), 200

if __name__ == '__main__':
    print("=" * 60)
    print("Download REST API Server")
    print("=" * 60)
    print("Servidor iniciado em http://localhost:5002")
    print("\nEndpoints disponíveis:")
    print("  POST /metadata  - Obter metadados do vídeo")
    print("  POST /download  - Baixar vídeo com progresso (SSE)")
    print("  GET  /health    - Health check")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5002, debug=False, threaded=True)