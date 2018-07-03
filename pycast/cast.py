import pychromecast
import sys
import time

def find_cast(device_name):
    chromecasts = pychromecast.get_chromecasts()
    try:
        return next(cc for cc in chromecasts if cc.device.friendly_name == device_name)
    except StopIteration:
        print('Cannot find device %s' % device_name)
        print('Available devices: [%s]' % ', '.join(cc.device.friendly_name for cc in chromecasts))
        raise
    except:
        raise

def start_cast(cast, url, media_type='video/mp4'):
    cast.wait()
    mc = cast.media_controller
    mc.play_media(url, media_type)
    while True:
      time.sleep(2)
      sys.stdout.write('\rcontent_type: %-10s stream_type: %-10s player_state: %-10s' %
                       (mc.status.content_type, mc.status.stream_type, mc.status.player_state))
      sys.stdout.flush()

def stop_cast(cast):
    mc = cast.media_controller
    mc.stop()
    print("Stop")

if __name__ == "__main__":
    if len(sys.argv) != 3 and len(sys.argv) != 4:
        print('Usage: %s <URL> <Device Name>> [Media Type]' % sys.argv[0])
        sys.exit()

    url = sys.argv[1]
    device_name = sys.argv[2]
    cast = find_cast(device_name)
    try:
        start_cast(cast, url)
    except KeyboardInterrupt:
        stop_cast(cast)
